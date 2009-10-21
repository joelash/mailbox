require 'rubygems'
require 'test/unit'

require File.dirname(__FILE__) + "/../lib/mailbox"

module Latches
  include_package 'java.util.concurrent'
end

class MailboxTest < Test::Unit::TestCase

  def test_mailslot_causes_execution_on_separate_thread

    klass = Class.new do
      include Mailbox

      mailslot
      def test_method(latch, thread_ids)
        thread_ids << Thread.current.object_id
        latch.count_down
      end
    end

    thread_ids = []
    latch = Latches::CountDownLatch.new( 1 )
    klass.new.test_method(latch, thread_ids)

    assert( latch.await( 1, Latches::TimeUnit::SECONDS ), "Timed out" )
    assert_not_equal Thread.current.object_id, thread_ids.first

  end

  def test_non_mailslot_methods_stay_public

    klass = Class.new do 
      include Mailbox

      def bar
        "foo"
      end
    end

    assert "foo", klass.new.bar

  end

  def test_should_supports_channels

    klass = Class.new do
      include Mailbox

      def initialize(channel)
        register_channel :test_channel, channel
      end

      mailslot :channel => :test_channel
      def test_method(latch)
        latch.count_down
      end
    end

    latch = Latches::CountDownLatch.new 1
    a_channel = JRL::Channel.new

    klass.new(a_channel)
    a_channel.publish latch

    assert latch.await( 1, Latches::TimeUnit::SECONDS ), "Timed out" 

  end

  def test_supports_synchronized_access_of_methods

    klass = Class.new do
      include Mailbox

      attr_accessor :values

      def initialize
        @values = []
      end

      synchronized
      def test_method( value )
        @value = value
        @values << @value
        sleep 1
        @values << @value
      end
    end

    clazz = klass.new

    thread_1 = Thread.new do
      clazz.test_method "thread 1"
    end

    sleep 0.3

    thread_2 = Thread.new do
      clazz.test_method "thread 2"
    end

#   Thread.pass
    thread_1.join 1
    thread_2.join 1

    assert_equal "thread 1", clazz.values[0], "1st wrong"
    assert_equal "thread 1", clazz.values[1], "2nd wrong"
    assert_equal "thread 2", clazz.values[2], "3rd wrong"
    assert_equal "thread 2", clazz.values[3], "4th wrong"
      
  end


end
