require 'test_helper.rb'

class MailboxTest < Test::Unit::TestCase

  def test_mailslot_causes_execution_on_separate_thread

    klass = Class.new do
      include Mailbox

      mailslot
      def test_method(latch, thread_info)
        thread_info[:thread_id] = Thread.current.object_id
        latch.count_down
      end
    end

    thread_info = {}
    latch = Latches::CountDownLatch.new( 1 )
    klass.new.test_method(latch, thread_info)

    assert( latch.await( 1, Latches::TimeUnit::SECONDS ), "Timed out" )
    assert_not_equal Thread.current.object_id, thread_info[:thread_id]

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
          thread_info[:thread_id] = Thread.current.object_id
        end

      end

      thread_info = {}
      klass.new.test_method(thread_info)
      assert_equal Thread.current.object_id, thread_info[:thread_id]
    ensure
      Mailbox.synchronous = false;
    end

  end

  def test_should_supports_channels

    klass = Class.new do
      include Mailbox

      def initialize(channel)
        register_channel :test_channel, channel
      end

      mailslot :channel => :test_channel
      def test_method(message)
        message[:thread_info][:thread_id] = Thread.current.object_id
        message[:latch].count_down
      end
    end

    thread_info = {}
    latch = Latches::CountDownLatch.new 1
    a_channel = JRL::Channel.new

    klass.new(a_channel)
    a_channel.publish :latch => latch, :thread_info => thread_info

    assert latch.await( 1, Latches::TimeUnit::SECONDS ), "Timed out" 
    assert_not_equal Thread.current.object_id, thread_info[:thread_id]

  end
  
end
