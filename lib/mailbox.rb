require 'rubygems'
require 'jretlang'

# Author:: Joel Friedman and Patrick Farley

# This module is used to simplify the using concurrency
# in your application. Using JVM threads as the backing
# a method can set to become an asynchronous method
# to be used in a actor-model method. Or a method
# can be set to be the backing of a named channel 
# (jretlang channels are used here). 
module Mailbox

  # Register your jretlang channel as a named channel
  def register_channel(channel_name, channel)
    channel_registry = self.class.__channel_registry__
    channel_registry.each_pair { |key, value| __subscribe__(channel, key) if value == channel_name }
  end

  private 

  def self.included(base)
    base.extend(Mailbox::ClassMethods)
  end

  def __subscribe__(channel, method)
    channel.subscribe_on_fiber(__fiber__) { |*args| self.send(method, *args) }
  end

  def __started_fiber__
    fiber = JRL::Fiber.new
    fiber.start
    fiber
  end

  def __fiber__
    @fiber ||= __started_fiber__
  end 

  def __mutex__
    @mutex ||= Mutex.new
  end

  module ClassMethods

    attr_accessor :__channel_registry__

    # Notifies Mailbox that the next method added
    # will be a 'mailslot'. If :channel is provided
    # then it'll become a subscriber on that channel
    def mailslot(params={})
      @next_channel_name = params[:channel]
      @mailslot = true
    end

    # Notified Mailbox that the next method added
    # will be 'synchronized'. This guarentees 1)
    # Two invocations of this method will not
    # interleave and 2) a happens-before relationship
    # is established with any subsequent invocation.
    # http://java.sun.com/docs/books/tutorial/essential/concurrency/syncmeth.html
    def synchronized
      @synchronized = true
    end

    private

    def method_added(method_name, &block)
      return if @adding_mailbox_to_method == method_name

      return unless @mailslot == true || @synchronized == true

      @mailslot = false

      if @synchronized == true
        __synchronize__(method_name)
      elsif @next_channel_name.nil?
        __setup_on_fiber__(method_name)
      else
        __setup_on_channel__(method_name)
      end

      @adding_mailbox_to_method = nil

    end

    def __alias_method__(method_name)
      alias_method :"__#{method_name}__", method_name
      @adding_mailbox_to_method = method_name
    end

    def __synchronize__(method_name)
      @synchronized = false
      __alias_method__(method_name)

      define_method( method_name, lambda do |*args| 
        __mutex__.synchronize { self.send(:"__#{method_name}__", *args ) }  
      end )
    end

    def __setup_on_fiber__(method_name)
      __alias_method__(method_name)

      define_method( method_name, lambda do |*args| 
        __fiber__.execute { self.send(:"__#{method_name}__", *args ) }  
      end )

    end

    def __setup_on_channel__(method_name)
      private method_name
      @__channel_registry__ ||= {}
      __channel_registry__[method_name] = @next_channel_name
      @next_channel_name = nil
    end

  end 

end

