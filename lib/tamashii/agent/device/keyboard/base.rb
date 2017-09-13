require 'concurrent'
require 'tamashii/agent/device/device_base'

module Tamashii
  module Agent
    module Device
      module Keyboard
        class Base < DeviceBase

          def initialize(*args)
            super(*args)
            initialize_hardware
            @number_of_keys = fetch_option(:number_of_keys, default_number_of_keys)
            @watcher_mode = fetch_option(:watch, default_watch)
            @watcher_stopping = Concurrent::AtomicBoolean.new(false)
            if @watcher_mode
              initialize_watcher
              start_watcher_thread
            end
          end

          def default_number_of_keys
            raise NotImplementedError
          end

          def default_watch
            true
          end

          def polling_interval
            0.1
          end

          def initialize_hardware
            logger.warn "Device #{@name} does not implement hardware initialize code"
          end

          def finalize_hardware
            logger.warn "Device #{@name} does not implement hardware finalize code"
          end

          def initialize_watcher
            @last_keys_state = {}
            @current_keys_state = {}
            @current_key = Concurrent::AtomicFixnum.new(-1)
            @callbacks = {}
          end

          def add_callback(event, callable)
            if @watcher_mode
              @callbacks[event] = callable
            else
              puts "Callbacks are only available in watcher mode!"
            end
          end

          def on_key_down(callable = nil, &block)
            add_callback(:down, callable || block)
          end

          def on_key_up(callable = nil, &block)
            add_callback(:up, callable || block)
          end

          def on_key_pressed(callable = nil, &block)
            add_callback(:pressed, callable || block)
          end

          def watcher_stopping?
            @watcher_stopping.true?
          end

          def start_watcher_thread
            @watcher_thread = Thread.new { watcher_loop }
          end

          def watcher_loop
            puts "watcher started"
            loop do
              if watcher_stopping?
                break
              end
              sleep polling_interval
              record_key_state
              read_key
              process_callbacks
            end
            puts "watcher thread terminated normally"
          end

          def process_callbacks
            @number_of_keys.times do |key|
              if @current_keys_state[key]
                if @last_keys_state[key]
                  @callbacks[:pressed]&.call(key)
                else
                  @callbacks[:down]&.call(key)
                end
              else
                if @last_keys_state[key]
                  @callbacks[:up]&.call(key)
                end
              end
            end
          end

          def record_key_state
            @number_of_keys.times do |key|
              @last_keys_state[key] = @current_keys_state[key]
            end
          end

          def stop_watcher_thread
            if !@watcher_thread.join(3)
              @watcher_thread.exit
              puts "watcher thread killed forcefully"
            end
          end

          def poll_key
            if @watcher_mode
              @current_key.value >= 0 ? @current_key.value : nil
            else
              sleep polling_interval
              read_key
            end
          end

          def shutdown
            @watcher_stopping.make_true
            if @watcher_mode
              stop_watcher_thread
            end
            finalize_hardware
          end

          def mark_key_up(key)
            return unless @watcher_mode
            if @current_key.value == key
              # remove current key
              @current_key.value = -1
            end
            @current_keys_state[key] = false
          end

          def mark_key_down(key)
            return unless @watcher_mode
            @current_key.value = key
            @current_keys_state[key] = true
          end

          def read_key
            raise NotImplementedError, "read_key"
          end
        end
      end
    end
  end
end
