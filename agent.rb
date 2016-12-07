#!/usr/bin/env ruby
$LOAD_PATH << "#{File.dirname(__FILE__)}/codeme-common/lib"
$LOAD_PATH << "#{File.dirname(__FILE__)}/lib"

Thread.abort_on_exception = true

require 'thread'
require 'connection'


module Codeme
  class AgentMaster < Component
    def initialize
      super
      @c = Connection.new(self, "127.0.0.1", 4180)
      @c.run

      @selector = NIO::Selector.new
      @selector.register(@pipe_r, :r)

      @c.enable_log = false
    end

    def run
      loop do
        ready = @selector.select
        if ready
          # read the event
          receive_event
        end
      end
    end

    def broadcast_event(ev_type, ev_body)
      @c.send_event(ev_type, ev_body)
    end
  end
end

agent = Codeme::AgentMaster.new
Thread.new do
  loop do
    sleep 1
    agent.broadcast_event(Codeme::Component::EVENT_CARD_DATA, "ABC")
  end
end
agent.run
