require 'rubygems'
require 'test/unit'

require File.dirname(__FILE__) + "/../lib/mailbox"

class ICanHasCheeseBurger
  include Mailbox

  def initialize(channel)
    register_channel :request_channel, channel
  end

  mailslot :channel => :request_channel, :replyable => true
  def can_you_has?
    return "ya you can has!"
  end

end

class ICanHasCheeseBurgerExample < Test::Unit::TestCase

  def test_cheeseburgerz
    i_can_has_channel = org.jetlang.channels.MemoryRequestChannel.new
    i_can_has_cheeseburger = ICanHasCheeseBurger.new(i_can_has_channel)

    sync_executor = org.jetlang.core.SynchronousDisposingExecutor.new
    sync_fiber = org.jetlang.fibers.ThreadFiber.new(sync_executor, nil, false)
    question = "can i has?"
    puts question

    latch = JRL::Concurrent::Latch.new(1)
    answer = "no response!"
    org.jetlang.channels.AsyncRequest.with_one_reply(sync_fiber, i_can_has_channel, question) do |message|
      answer = message
      latch.count_down
    end

    latch.await(1)
    puts answer
  end

end