module Mailbox
  module Executors
    module SingleThread
      def self.included base
        base.send :include, Core unless base.respond_to? :is_mailbox?
        base.send :include, InstanceMethods
        base.extend ClassMethods
      end

      module ClassMethods
        def __mailslot_singleton_executor__
          @__mailslot_singleton_executor__ ||= begin
                                                 JConcurrent::Executors.new_single_thread_executor.tap do |exec|
                                                   # with this it'll not be daemon?
                                                   #at_exit { __mailslot_shutdown__ }
                                                 end
                                               end
        end

        #TODO: can this move to core?
        def __mailslot_shutdown__
          return unless @__mailslot_singleton_executor__
          @__mailslot_singleton_executor__.shutdown
          @__mailslot_singleton_executor__ = nil
        end
        alias_method :shutdown_mailslot, :__mailslot_shutdown__
      end

      module InstanceMethods
        #def on_mailslot &method_def
          #__executor__.execute method_def
        #end

        def __mailslot_executor__
          @__mailslot_executor__ ||= begin
                                       JConcurrent::Executors.new_single_thread_executor.tap do |exec|
                                         # with this it'll not be daemon?
                                         #at_exit { __mailslot_shutdown__ }
                                       end
                                     end
        end

        #TODO: can this move to core?
        def __mailslot_shutdown__
          return unless @__mailslot_executor__
          @__mailslot_executor__.shutdown
          @__mailslot_executor__ = nil
        end
        alias_method :shutdown_mailslot, :__mailslot_shutdown__
      end
    end
  end
end
