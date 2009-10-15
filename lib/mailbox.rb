require 'rubygems'
require 'jretlang'

# Author:: Joel Friedman and Patrick Farley

# This module is used to simplify the using concurrency
# in your application. Using JVM threads as the backing
# a function can set to become an asynchronous function
# to be used in a actor-model method. Or a function
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

  module ClassMethods

    attr_accessor :__channel_registry__

    # Notifies Mailbox that the next method added
    # will be a 'mailslot'. If :channel is provided
    # then it'll become a subscriber on that channel
    def mailslot(params={})
      @next_channel_name = params[:channel]
      @mailslot = true
    end

    private

    def method_added(method_name, &block)
      return if @adding_mailbox_to_method == method_name

      unless @mailslot == true
        private method_name
        return
      end

      @mailslot = false

      if @next_channel_name.nil?
        __setup_on_fiber__(method_name)
      else
        __setup_on_channel__(method_name)
      end

    end

    def __setup_on_fiber__(method_name)
      alias_method :"__#{method_name}__", method_name

      @adding_mailbox_to_method = method_name

      define_method( method_name, lambda do |*args| 
        __fiber__.execute { self.send(:"__#{method_name}__", *args ) }  
      end )

      @adding_mailbox_to_method = nil
    end

    def __setup_on_channel__(method_name)
      private method_name
      @__channel_registry__ ||= {}
      __channel_registry__[method_name] = @next_channel_name
      @next_channel_name = nil
    end

  end 

end

