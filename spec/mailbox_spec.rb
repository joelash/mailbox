require File.expand_path '../spec_helper', __FILE__

module Mailbox
  describe SingleThreadExecution do
    klass = Class.new do
      include Mailbox::SingleThreadExecution

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
        @instance.is_mailslot?(:this_is_mailslot).should be_true
        confirm_is_mailslot { |h| @instance.send :this_is_mailslot, h }
      end

      it 'are on calling thread when public' do
        @instance.is_mailslot?(:this_is_not_mailslot).should be_false
        confirm_is_not_mailslot { |h| @instance.send :this_is_not_mailslot, h }
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
