require 'rubygems'
require 'test/unit'

require File.dirname(__FILE__) + "/../lib/mailbox"

class ChannelBasedLogger
  include Mailbox

  def initialize(log_channel)
    register_channel :log_channel, log_channel
  end

  mailslot :channel => :log_channel
  def log(message)
    p "Logging on Thread #{Thread.current.object_id} - #{message}"
  end
end

class ChannelBasedLogExample < Test::Unit::TestCase

  def test_log_example
    channel = JRL::Channel.new
    logger = ChannelBasedLogger.new channel
    p "Current Thread is #{Thread.current.object_id}"
    channel.publish "some log message"
  end

end