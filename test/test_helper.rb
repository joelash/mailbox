require 'rubygems'
require 'test/unit'

require File.dirname(__FILE__) + "/../lib/mailbox"
require File.dirname(__FILE__) + "/../lib/synchronized"

module Latches
  include_package 'java.util.concurrent'
end
