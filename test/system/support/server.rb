# frozen_string_literal: true

require "puma"
require "puma/server"
require "puma/log_writer"
require "rack"

# Boots the Rails app on an ephemeral port in a background thread so Playwright
# can hit it over real HTTP. One server per process; the URL is stable across
# tests so cookies/origins behave like a real browser session.
module SystemTests
  class Server
    HOST = "127.0.0.1"

    class << self
      def boot
        @boot ||= begin
          start
          at_exit { stop }
          true
        end
      end

      def base_url
        "http://#{HOST}:#{port}"
      end

      def port
        @port ||= @server&.connected_ports&.first
      end

      private
        # Bind to port 0 inside Puma so the kernel picks a free port and Puma
        # immediately holds the socket — no TOCTOU window between "pick port" and
        # "listen on it." After Puma binds, `connected_ports` tells us what it got.
        def start
          @server = Puma::Server.new(Rails.application, nil, log_writer: Puma::LogWriter.null)
          @server.add_tcp_listener(HOST, 0)
          @thread = Thread.new { @server.run.join }
          wait_until_ready
        end

        def stop
          @server&.stop(true)
          @thread&.join(5)
        end

        # Rescue every transient socket error we've seen during the Puma boot
        # window, not just ECONNREFUSED — under load we've hit EADDRNOTAVAIL,
        # ETIMEDOUT, and even ECONNRESET as the accept loop starts up.
        def wait_until_ready
          deadline = Time.now + 10
          loop do
            TCPSocket.new(HOST, port).close
            return
          rescue Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL, Errno::ETIMEDOUT, Errno::ECONNRESET, IO::TimeoutError
            raise "Test server failed to start on #{HOST}:#{port}" if Time.now > deadline
            sleep 0.05
          end
        end
    end
  end
end
