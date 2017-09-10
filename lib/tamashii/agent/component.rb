require 'tamashii/agent/common'
require 'tamashii/agent/event'


module Tamashii
  module Agent
    class Component
      include Common::Loggable

      class LoadDeviceError < RuntimeError; end

      def initialize(name, master, options = {})
        @name = name
        @master = master
        @options = options
        @event_queue = Queue.new
      end

      def send_event(event)
        @event_queue.push(event)
      end

      def check_new_event(non_block = false)
        @event_queue.pop(non_block)
      rescue ThreadError => e
        nil
      end
      
      def handle_new_event(non_block = false)
        if ev = check_new_event(non_block)
          process_event(ev)
        end
        ev
      end

      def restart_current_component_async
        @master.send_event(Event.new(Event::RESTART_COMPONENT, @name))
      end

      def process_event(event)
        logger.debug "Got event: #{event.type}, #{event.body}"
      end

      # worker
      def run
        @worker_thr = Thread.start { run_worker_loop }
      end

      def run!
        run_worker_loop
      end
      
      def stop
        logger.info "Stopping component #{@name}"
        stop_threads
        clean_up
      end

      def stop_threads
        @worker_thr.exit if @worker_thr
        @worker_thr = nil
      end

      def clean_up
      end

      def run_worker_loop
        worker_loop
      end

      # a default implementation
      def worker_loop
        loop do
          if !handle_new_event
            logger.error "Thread error. Worker loop terminated"
            break
          end
        end
      end

      def initialize_device
        device_name = @options[:device] || default_device_name
        logger.info "Using device: #{device_name}"
        get_device_instance(device_name)
      rescue => e
        logger.error "Error when loading device: #{e.message}"
        e.backtrace.each {|msg| logger.error msg}
        logger.error "Fallback to default: #{default_device_name}"
        load_default_device
      end

      def get_device_instance(device_name)
        klass = Common.load_device_class(get_device_class_name(device_name))
        klass.new(self, @options)
      end

      def load_default_device
        logger.info "loading default device: #{default_device_name}"
        get_device_instance(default_device_name)
      rescue => e
        raise LoadDeviceError, "Unable to load device: #{e.message}"
      end

      def default_device_name
        raise NotImplementedError
      end

      def get_device_class_name(device_name)
        raise NotImplementedError
      end
    end
  end
end
