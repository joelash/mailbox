# Author:: Joel Friedman and Patrick Farley
#
# This module is used to simplify concurrency
# in your application. JVM threads and JRetlang are
# used to provide Actor model style asynchronous
# message passing via method calls.  Named channel based
# message passing is also supported via +register_channel+ and
# the <tt>:channel</tt> parameter on +mailslot+.

require 'rubygems'
require 'jretlang'

require File.dirname(__FILE__) + '/synchronized'
require File.dirname(__FILE__) + '/daemon_thread_factory'

module Mailbox
  include Synchronized

  # Register your jretlang channel as a named channel
  def register_channel(channel_name, channel)
    channel_registry = self.class.__channel_registry__
    channel_registry.select { |k,v| v[:channel] == channel_name }.each do |k,v|
      v[:replyable] ? __subscribe_with_single_reply__(channel, k) : __subscribe__(channel, k)
    end
  end

  def verbose_output_to method_name
    @__verbose_target__ = method_name
  end

  def dispose
    __fiber__.dispose
  end

  class << self
    # Used to tell +Mailbox+ that all +mailslot+ 
    # methods should be run on the calling thread.
    #
    # <b>*** Intended for synchronous unit testing of concurrent apps***</b>
    attr_reader :synchronous, :raise_exceptions_immediately

    def synchronous= value
      @synchronous = value
      @raise_exceptions_immediately = false if value == false
    end

    def raise_exceptions_immediately= value
      raise Exception.new('cannot set raise_exceptions_immediately when not in synchronous mode!') if value && !Mailbox.synchronous
      @raise_exceptions_immediately = value
    end

  end

  private
  def self.included(base)
    base.extend(Mailbox::ClassMethods)
  end

  def __subscribe__(channel, method)
    channel.subscribe_on_fiber(__fiber__) do |*args|
      self.send(method, *args)
    end
  end

  def __subscribe_with_single_reply__(channel, method)
    channel.subscribe(__fiber__) do |message|
      message.reply(self.send(method))
    end
  end

  def __synchronous_fiber__
    executor = JRL::SynchronousDisposingExecutor.new
    JRL::Fibers::ThreadFiber.new executor, "#{self.class.name} #{self.object_id} Mailbox synchronous", true
  end

  def __create_fiber__
    return self.class.__fiber_factory__.create if self.class.__fiber_factory__
    JRL::Fibers::ThreadFiber.new( JRL::RunnableExecutorImpl.new, "#{self.class.name} #{self.object_id} Mailbox", true )
  end

  def __started_fiber__
    fiber = Mailbox.synchronous == true ? __synchronous_fiber__ : __create_fiber__
    fiber.start
    fiber
  end

  def __fiber__
    @fiber ||= __started_fiber__
  end

  module ClassMethods 
    include Synchronized::ClassMethods

    # Used within +Mailbox+ module
    attr_accessor :__channel_registry__ 

    # Notifies Mailbox that the next method added
    # will be a +mailslot+. If <tt>:channel</tt> is provided
    # the next method will become a subscriber on the channel.
    # Channel based +mailslot+ methods are also made private
    # to discourage direct invocation. <tt>:exception</tt>
    # can be provided as the symbol for a method to handle
    # any exceptions that occur in your +mailslot+. This
    # method will be passed the exception that was raised
    def mailslot(params={})
      @next_channel_name = params[:channel]
      @replyable = params[:replyable]
      @timeout = params[:timeout].nil? ? -1 : params[:timeout] * 1000
      @exception = params[:exception]

      @mailslot = true
    end

    def mailbox_thread_pool_size(count)
      @__fiber_factory__ = JRL::Fibers::PoolFiberFactory.new(JRL::Concurrent::Executors.new_fixed_thread_pool(count, DaemonThreadFactory.new))
    end

    def __fiber_factory__
      @__fiber_factory__ ||= nil
    end
    
    private
    
    def method_added(method_name, &block)
      return super unless __mailslot__ == true
      @mailslot = false

      if @next_channel_name.nil?
        __setup_on_fiber__(method_name, @replyable, @timeout)
      else
        __setup_on_channel__(method_name, @replyable)
      end
      
      super

    end

    def __setup_on_fiber__(method_name, replyable, timeout)
      return super if __is_adding_mailbox_to_method__
    
      alias_method :"__#{method_name}__", method_name
      @is_adding_mailbox_to_method = true

      exception_method, @exception = @exception, nil
      define_method method_name do |*args|

        self.send(@__verbose_target__, "enqueued #{method_name}") if defined? @__verbose_target__

        result = nil
        latch = JRL::Concurrent::CountDownLatch.new(1) if replyable

        __fiber__.execute do
          begin
            self.send(@__verbose_target__, "dequeued #{method_name}") if defined? @__verbose_target__
            result = self.send(:"__#{method_name}__", *args )
          rescue Exception => ex
            raise if exception_method.nil? || Mailbox.raise_exceptions_immediately
            self.send(:"#{exception_method}", ex)
          ensure
            latch.count_down if replyable
          end
        end

        is_timeout = false
        if replyable
          if timeout == -1
            latch.await
          else
            is_timeout = !(latch.await timeout, JRL::Concurrent::TimeUnit::MILLISECONDS)
          end
        end

        raise Exception.new("#{method_name} message timeout after #{timeout/1000} seconds") if is_timeout

        return result
      
      end 
      
      @replyable = false
      @is_adding_mailbox_to_method = false
    
    end

    def __setup_on_channel__(method_name, replyable)
      private method_name
      @__channel_registry__ ||= {}
      __channel_registry__[method_name] = { :channel => @next_channel_name, :replyable => replyable } 
      @replyable = nil
      @next_channel_name = nil
    end
    
    def __mailslot__
      @mailslot ||= false
    end
  
    def __is_adding_mailbox_to_method__
      @is_adding_mailbox_to_method ||= false
    end

  end

end
