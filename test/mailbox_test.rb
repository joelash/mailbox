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

	def test_non_mailslot_methods_become_private

		klass = Class.new do 
			include Mailbox

			def bar
			end
		end

		exception = assert_raise NoMethodError do
			klass.new.bar
		end
		
 		assert_match /private method `bar'/, exception.message
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
	  
		thread_ids = []
		latch = Latches::CountDownLatch.new 1
		a_channel = JRL::Channel.new
	
		klass.new(a_channel)
    a_channel.publish latch
	
		assert latch.await( 1, Latches::TimeUnit::SECONDS ), "Timed out" 

  end

end
