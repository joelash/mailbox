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

		assert_not_nil thread_ids.first
		assert_not_equal Thread.current.object_id, thread_ids.first

	end

	def test_non_mailslot_functions_become_private

		klass = Class.new do 
			include Mailbox

			def bar
				puts "This shouldn't print"
			end
		end

		foo = assert_raise NoMethodError do
			klass.new.bar
		end
 		assert_match /private method `bar'/, foo.message
	end

end
