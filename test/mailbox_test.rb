require 'test_helper.rb'

module JRL::Concurrent
  class Latch
    def fail_after_sec
      raise Exception.new("timed out waiting one second for latch countdown - remaining count: #{count}") unless await 1
    end
  end
end

class MailboxTest < Test::Unit::TestCase
  JThread = java.lang.Thread


  def jrl_latch count = 1
    JRL::Concurrent::Latch.new count
  end

  def test_mailslot_causes_execution_on_separate_thread
    klass = Class.new do
      include Mailbox

      mailslot
      def test_method(latch, thread_info)
        thread_info[:name] = JThread.current_thread.name
        latch.count_down
      end
    end

    thread_info = {}
    latch = jrl_latch
    klass.new.test_method(latch, thread_info)

    latch.fail_after_sec
    assert_not_equal JThread.current_thread.name, thread_info[:name]
  end

  def test_mailbox_supports_concurrent_mailslot_calls_on_new_mailbox_object
    klass = Class.new do
      include Mailbox

      attr_reader :failed
      def initialize; @items = []; @failed = nil; end
      
      mailslot :exception => :fail_test
      def one
        raise Exception.new('items not empty!') unless @items.empty?
        @items << 1
        sleep 0.01
        raise Exception.new("items not exactly [1]!") unless @items == [1]
        @items.pop
        raise Exception.new('items not empty') unless @items.empty?
      end

      def fail_test e; @failed = e; end
    end
    
    o = klass.new
    10.times { Thread.new { o.one } }

    assert_nil o.failed
  end

  def test_mailslot_supports_threadpool_based_fibers
    klass = Class.new do
      include Mailbox
      mailbox_thread_pool_size 2


      mailslot
      def test_method(latch, thread_info)
        thread_info[:name] = JThread.current_thread.name
        latch.count_down
      end
    end

    thread_info = {}
    latch = jrl_latch
    klass.new.test_method(latch, thread_info)

    latch.fail_after_sec
    assert_not_equal JThread.current_thread.name, thread_info[:name]
  end

  def test_can_set_mailslot_to_callback_on_exception
    klass = Class.new do
      include Mailbox

      attr_accessor :ex

      def initialize(latch)
        @latch = latch
      end

      mailslot :exception => :handle_exception
      def test_method
        raise "test exception"
      end

      def handle_exception(ex)
        @ex = ex
        @latch.count_down
      end
    end

    latch = jrl_latch
    clazz = klass.new(latch)
    clazz.test_method
    latch.fail_after_sec
    assert_equal "test exception", clazz.ex.message
  end

  def test_default_is_run_asynchronously
    assert Mailbox.synchronous == false, "Mailbox is defaulting to synchronous execution"
  end

  def test_default_is_run_with_exception_callbacks
    assert !Mailbox.raise_exceptions_immediately, "Mailbox is defaulting to raising exceptions immediately"
  end

  def test_cannot_set_raise_exceptions_immediately_unless_in_synchronous_mode
    begin
      assert !Mailbox.synchronous
      assert_raises(Exception) { Mailbox.raise_exceptions_immediately = true }
    ensure
      Mailbox.raise_exceptions_immediately = false
    end
  end

  def test_raise_exceptions_immediately_is_turned_off_when_setting_synchronous_to_false
    begin
      Mailbox.synchronous = true
      Mailbox.raise_exceptions_immediately = true
      Mailbox.synchronous = false
      assert !Mailbox.raise_exceptions_immediately
    ensure
      Mailbox.synchronous = false
      Mailbox.raise_exceptions_immediately = false
    end
  end

  def test_can_set_mailbox_to_ignore_exception_callback_and_raise_exceptions_for_tests
    begin
      Mailbox.synchronous = true
      Mailbox.raise_exceptions_immediately = true
      klass = Class.new do
        include Mailbox
        mailslot :exception => :should_not_run
        def test_method
          raise Exception.new('test exception')
        end

        def should_not_run exception
          raise Exception.new('exception handled')
        end
      end

      obj = klass.new
      raised = assert_raises(Exception) { obj.test_method }
      assert_equal 'test exception', raised.message
    ensure
      Mailbox.raise_exceptions_immediately = false
    end

  end

  def test_can_set_mailslot_to_run_synchronously
    begin
      Mailbox.synchronous = true
      klass = Class.new do
        include Mailbox

        mailslot
        def test_method(thread_info)
          thread_info[:name] = JThread.current_thread.name
        end

      end

      thread_info = {}
      klass.new.test_method(thread_info)
      assert_equal JThread.current_thread.name, thread_info[:name]
    ensure
      Mailbox.synchronous = false;
    end
  end

  def test_should_support_channels

    klass = Class.new do
      include Mailbox

      def initialize(channel)
        register_channel :test_channel, channel
      end

      mailslot :channel => :test_channel
      def test_method(message)
        message[:thread_info][:name] = JThread.current_thread.name
        message[:latch].count_down
      end
    end

    thread_info = {}
    latch = jrl_latch
    a_channel = JRL::Channel.new

    klass.new(a_channel)
    a_channel.publish :latch => latch, :thread_info => thread_info

    latch.fail_after_sec
    assert_not_equal JThread.current_thread.name, thread_info[:name]
  end

  def test_should_support_request_channels

    klass = Class.new do
      include Mailbox

      def initialize(request_channel)
        register_channel :test_channel, request_channel
      end

      mailslot :channel => :test_channel, :replyable => true
      def test_method
        return "ya_rly!"
      end
    end

    thread_info = {}
    latch = jrl_latch
    request_channel = JRL::Channels::MemoryRequestChannel.new

    klass.new(request_channel)
    fiber = JRL::Fibers::ThreadFiber.new
    fiber.start

    response = "no response"
    JRL::Channels::AsyncRequest.with_one_reply(fiber, request_channel, "orly?") do |message|
      response = message
      latch.count_down
    end

    latch.fail_after_sec
    assert_equal "ya_rly!", response
  end

  def test_should_support_replyable_messages
  
    klass = Class.new do
      include Mailbox

      mailslot :replyable => true
      def test_method
        ["response", JThread.current_thread.name]
      end
    end
  
    response, name = klass.new.test_method
    assert_equal "response", response
    assert_not_equal JThread.current_thread.name, name

  end

  def test_replyable_messages_should_respect_timeout

    klass = Class.new do
      include Mailbox

      mailslot :replyable => true, :timeout => 0.1
      def test_method
        sleep 1
      end
    end
  
    e = assert_raise(Exception) { klass.new.test_method }
    assert_equal e.message, "test_method message timeout after 0.1 seconds"

  end

  def test_replyable_messages_should_respect_non_timeout

    klass = Class.new do
      include Mailbox

      mailslot :replyable => true, :timeout => 1
      def test_method
        return 'ok'
      end
    end

    assert_equal 'ok', klass.new.test_method 

  end

  def test_should_maintain_queue_depth
    klass = Class.new do
      include Mailbox
      include Test::Unit::Assertions

      def initialize latch
        @latch = latch
        __fiber__.execute do 
          latch.fail_after_sec
        end
      end

      mailslot 
      def test_method latch
        latch.count_down
      end
    end

    hold_latch = jrl_latch
    agent = klass.new hold_latch
    method_latch = jrl_latch 10
    10.times { agent.test_method method_latch }
    assert_equal 10, agent.__queue_depth__
    hold_latch.count_down
    method_latch.fail_after_sec
    assert_equal 0, agent.__queue_depth__
  end

  def test_should_expose_hooks_to_message_enqueue_and_dequeue
    klass = Class.new do
      include Mailbox
      attr_accessor :msg_info

      def initialize(latch)
        verbose_output_to :msg_monitor

        @latch = latch
        @msg_info = []
      end

      mailslot :replyable => true
      def test_method
        @latch.count_down
      end

      def msg_monitor(info)
        @msg_info << info
      end

    end

    latch = jrl_latch 2

    test_agent = klass.new latch
    test_agent.test_method
    test_agent.test_method

    latch.fail_after_sec

    expected = ['enqueued test_method', 'dequeued test_method', 'enqueued test_method', 'dequeued test_method']
    assert_equal expected, test_agent.msg_info
  end

  class NamedMailbox 
    include Mailbox
  end

  def test_thread_name
    box = NamedMailbox.new

    assert_equal "MailboxTest::NamedMailbox #{box.object_id} Mailbox", box.__thread_name__
  end

  def test_dispose
    klass = Class.new do 
      include Mailbox 
      mailslot 
      def count_down(latch)
        latch.count_down
      end
    end
    
    test_agent = klass.new
    latch = jrl_latch
    test_agent.count_down latch

    latch.fail_after_sec

    test_agent.dispose

    latch = jrl_latch
    test_agent.count_down latch
    assert !latch.await(1), "latch didn't time out after fiber was disposed"
  end
end
