require 'rubygems'
require 'jretlang'

require File.dirname(__FILE__) + '/synchronized'

# Author:: Joel Friedman and Patrick Farley

# This module is used to simplify concurrency
# in your application. JVM threads and JRetlang are
# used to provide Actor model style asynchronous
# message passing via method calls.  Named channel based
# message passing is also supported via register_channel and
# the :channel parameter on mailslot.
module Mailbox
  include Synchronized

  # Register your jretlang channel as a named channel
  def register_channel(channel_name, channel)
    channel_registry = self.class.__channel_registry__
    channel_registry.each_pair { |key, value| __subscribe__(channel, key) if value == channel_name }
  end

  class << self
    # Used to tell +Mailbox+ that all +mailslot+ 
    # methods should be run on the calling thread.
    #
    # <b>*** Intended for synchronus unit testing of concurrent apps***</b>
    attr_accessor :synchronous
  end

  private 

  def self.included(base)
    base.extend(Mailbox::ClassMethods)
  end

  def __subscribe__(channel, method)
    channel.subscribe_on_fiber(__fiber__) { |*args| self.send(method, *args) }
  end

  def __synchronous_fiber__
    executor = JRL::SynchronousDisposingExecutor.new
    fiber = JRL::Fibers::ThreadFiber.new executor, "synchronous_thread", true
  end

  def __started_fiber__
    fiber = Mailbox.synchronous == true ? __synchronous_fiber__ : JRL::Fiber.new
    fiber.start
    fiber
  end

  def __fiber__
    @fiber ||= __started_fiber__
  end 

  module ClassMethods 
    include Synchronized::ClassMethods
    
    attr_accessor :__channel_registry__

    # Notifies Mailbox that the next method added
    # will be a +mailslot+. If <tt>:channel</tt> is provided
    # the next method will become a subscriber on the channel.
    # Channel based mailslot methods are also made private
    # to discourage direct invocation
    def mailslot(params={})
      @next_channel_name = params[:channel]
      @mailslot = true
    end

    private

    def method_added(method_name, &block)
      return super unless @mailslot == true
      @mailslot = false

      if @next_channel_name.nil?
        __setup_on_fiber__(method_name)
      else
        __setup_on_channel__(method_name)
      end
      
      super

    end

    def __setup_on_fiber__(method_name)
      return super if @is_adding_mailbox_to_method
    
      alias_method :"__#{method_name}__", method_name
      @is_adding_mailbox_to_method = true

      define_method( method_name, lambda do |*args| 
        __fiber__.execute { self.send(:"__#{method_name}__", *args ) }  
      end )

      @is_adding_mailbox_to_method = false
    end

    def __setup_on_channel__(method_name)
      private method_name
      @__channel_registry__ ||= {}
      __channel_registry__[method_name] = @next_channel_name
      @next_channel_name = nil
    end

  end 

end

