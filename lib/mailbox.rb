require 'rubygems'
require 'jretlang'

module Mailbox

  module ClassMethods
  	def mailslot
  		@mailslot = true
  	end

  	def method_added(method_name, &block)
  		return if @adding_mailbox_to_method == method_name

  		unless @mailslot == true
  		  private method_name
  			return
  		end

  		@mailslot = false

  		alias_method :"__#{method_name}__", method_name

  		@adding_mailbox_to_method = method_name

  			define_method( method_name, lambda do |*args| 
  			__fiber__.execute { self.send(:"__#{method_name}__", *args ) }  
  			end )

  		@adding_mailbox_to_method = nil

  	end

  end

  def self.included(base)
  	base.extend(ClassMethods)
  end

  def __started_fiber__
  	fiber = JRL::Fiber.new
  	fiber.start
  	fiber
  end

  def __fiber__
  	@fiber ||= __started_fiber__
  end

end
