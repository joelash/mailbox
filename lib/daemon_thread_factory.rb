module Mailbox
  class DaemonThreadFactory
    def newThread(r)
      thread = java.lang.Thread.new r;
      thread.set_daemon true;
      return thread;
    end
  end
end
