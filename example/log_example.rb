require 'rubygems'
require 'test/unit'

require File.dirname(__FILE__) + "/../lib/mailbox"

class Logger
  include Mailbox

  mailslot
  def log(message)
    p "Logging on Thread #{Thread.current.object_id} - #{message}"
  end
end

class LogExample < Test::Unit::TestCase

  def test_log_example
    logger = Logger.new
    p "Current Thread is #{Thread.current.object_id}"
    logger.log "some log message"
  end

end