require 'test_helper.rb'

class MailboxTest < Test::Unit::TestCase
  JThread = java.lang.Thread

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
    latch = Latches::CountDownLatch.new( 1 )
    klass.new.test_method(latch, thread_info)

    assert( latch.await( 1, Latches::TimeUnit::SECONDS ), "Timed out" )
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

    latch = Latches::CountDownLatch.new( 1 )
    clazz = klass.new(latch)
    clazz.test_method
    assert( latch.await( 1, Latches::TimeUnit::SECONDS ), "Timed out" )
    assert_equal "test exception", clazz.ex.message
  end

  def test_default_is_run_asynchronously
    assert Mailbox.synchronous == false, "Mailbox is defaulting to synchronous execution"
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
    latch = Latches::CountDownLatch.new 1
    a_channel = JRL::Channel.new

    klass.new(a_channel)
    a_channel.publish :latch => latch, :thread_info => thread_info

    assert latch.await( 1, Latches::TimeUnit::SECONDS ), "Timed out" 
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
    latch = Latches::CountDownLatch.new 1
    request_channel = JRL::Channels::MemoryRequestChannel.new

    klass.new(request_channel)
    fiber = JRL::Fibers::ThreadFiber.new
    fiber.start

    response = "no response"
    JRL::Channels::AsyncRequest.with_one_reply(fiber, request_channel, "orly?") do |message|
      response = message
      latch.count_down
    end

    assert latch.await(1, Latches::TimeUnit::SECONDS), "timed out"
    assert_equal "ya_rly!", response
  end

  def test_should_support_replayble_messages
  
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

    latch = JRL::Concurrent::Latch.new 2

    test_agent = klass.new latch
    test_agent.test_method
    test_agent.test_method

    assert latch.await(1), "timed out waiting for test_method to trip latch twice"

    expected = ['enqueued test_method', 'dequeued test_method', 'enqueued test_method', 'dequeued test_method']
    assert_equal expected, test_agent.msg_info
  end

end
