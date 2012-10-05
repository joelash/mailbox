require File.expand_path '../../../spec_helper', __FILE__

module Mailbox
  module Executors
    describe SingleThread do
      klass = Class.new do
        include Mailbox::Executors::SingleThread

        class << self
          def self_less_than_mailslot holder; holder << Thread.current.object_id end
          private
          def self_less_than_not_mailslot holder; holder << Thread.current.object_id end
        end

        def self.self_dot_mailslot holder; holder << Thread.current.object_id end
        def this_is_mailslot holder; holder << Thread.current.object_id end

        private
        def this_is_not_mailslot holder; holder << Thread.current.object_id end
      end

      after { klass.shutdown_mailslot }

      context 'instance methods' do
        before { @instance = klass.new }
        after  { @instance.shutdown_mailslot }

        it 'when public are on another thread' do
          confirm_is_mailslot { |h| @instance.send :this_is_mailslot, h }
        end

        it 'are on calling thread when public' do
          confirm_is_not_mailslot { |h| @instance.send :this_is_not_mailslot, h }
        end
      end

      context 'class methods' do
        context 'in self << class block' do
          it 'executes on another thread if public' do
            confirm_is_mailslot { |h| klass.send :self_less_than_mailslot, h }
          end

          it 'executes on calling thread if private' do
            confirm_is_not_mailslot { |h| klass.send :self_less_than_not_mailslot, h }
          end
        end

        it 'executes on another thread when self.' do
          confirm_is_mailslot { |h| klass.send :self_dot_mailslot, h }
        end
      end

      private
      def confirm_is_mailslot &block
        mailslot_result(block).should_not == Thread.current.object_id
      end

      def confirm_is_not_mailslot &block
         mailslot_result(block).should == Thread.current.object_id
      end

      def mailslot_result block
        holder = []
        block.call holder
        sleep 0.1
        holder.should_not be_empty
        holder.size.should == 1
        holder.first
      end
    end
  end
end
