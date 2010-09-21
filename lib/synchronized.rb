# Author:: Joel Friedman and Patrick Farley
#
# This module goes hand in hand with +Mailbox+.
# It simplifies concurrecncy within your 
# JRuby applications.
require 'monitor'

module Synchronized
  
  private
  
  def __synchronizer__
    @synchronizer ||= Monitor.new
  end
  
  def self.included(base)
    base.extend(Synchronized::ClassMethods)
  end
  
  module ClassMethods
    
    # Notify +Mailbox+ that the next method added
    # will be +synchronized+. 
    #
    # This guarentees:
    #     1. Two invocations of this method will not interleave and 
    #     2. a happens-before relationship is established with any subsequent invocation.
    # http://java.sun.com/docs/books/tutorial/essential/concurrency/syncmeth.html
    def synchronized
      @synchronized = true
    end

    
    private
    
    def method_added(method_name, &block)
      return super unless __synchronized__ == true
      @synchronized = false
      __synchronize__(method_name)
      super
    end
    
    
    def __synchronize__(method_name)
      return super if __is_adding_synchronized_to_method__
      
      alias_method :"__#{method_name}__", method_name
      @is_adding_synchronized_to_method = true
      

      define_method( method_name, lambda do |*args| 
        __synchronizer__.synchronize { self.send(:"__#{method_name}__", *args ) }  
      end )
      
      @is_adding_synchronized_to_method = false
    end
    
    def __synchronized__
      @synchronized ||= false
    end

    def __is_adding_synchronized_to_method__
      @is_adding_synchronized_to_method ||= false
    end
    
  end
  
end
