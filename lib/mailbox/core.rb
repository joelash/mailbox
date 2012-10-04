module Mailbox
  module JConcurrent
    include_package 'java.util.concurrent'
  end

  module Core
    def self.included base
      @__mailslot_base = base
      base.extend ClassMethods
      base.send :include, InstanceMethods
    end

    def self.__mailslot_base
      @__mailslot_base
    end

    module ClassMethods
      def method_added(method_name)
        super
        is_public_method = Mailbox::Core.__mailslot_base.public_method_defined?(method_name)
        return if !is_public_method || @__mailbox_defining_method__
        @__mailbox_defining_method__ = true
        __mailslot_instance_methods__ << method_name.to_sym
        new_method_name = :"__mailslot_redef_#{method_name}__"
        alias_method new_method_name, method_name
        define_method(method_name) do |*args|
          method_lambda = lambda { send new_method_name, *args }
          __mailslot_executor__.execute method_lambda
        end
        @__mailbox_defining_method__ = false
      end

      def singleton_method_added(method_name, &block)
        super
        is_public_method = __mailbox_metaclass__.public_method_defined? method_name
        return if !is_public_method || @__mailbox_defining_method__
        @__mailbox_defining_method__ = true
        __mailslot_class_methods__ << method_name.to_sym
        # TODO: define execution
        @__mailbox_defining_method__ = false
      end

      def on_mailslot_exception exception
        #noop
      end

      def is_instance_mailslot? method_name
        __mailslot_instance_methods__.include? method_name.to_sym
      end

      def is_class_mailslot? method_name
        __mailslot_class_methods__.include? method_name.to_sym
      end
      alias_method :is_mailslot?, :is_class_mailslot?

      private
      def __mailbox_metaclass__
        class << self; self; end
      end

      def __mailslot_instance_methods__
        @__mailslot_instance_methods__ ||= []
      end

      def __mailslot_class_methods__
        @__mailslot_class_methods__ ||= []
      end
    end

    module InstanceMethods
      def is_mailslot? method_name
        self.class.is_instance_mailslot? method_name
      end

      def on_mailslot_exception exception
        #no op
      end
    end
  end
end
