require 'timeout'
require 'usage_tracker_middleware/log'
require 'usage_tracker_middleware/context'
require 'usage_tracker_middleware/railtie' if defined?(Rails)

# This middleware extracts some data from the incoming request
# and sends it to the specified server.
#

module UsageTrackerMiddleware
  class Middleware

    @@host    = 'localhost'
    @@port    = 5985
    @@backend = `hostname`.strip
    @@logger  = UsageTrackerMiddleware::Log.new

    @@headers = [
      # "REMOTE_ADDR",
      "REQUEST_METHOD",
      "PATH_INFO",
      "REQUEST_URI",
      "SERVER_PROTOCOL",
      #"HTTP_VERSION",
      "HTTP_REFERER",
      "HTTP_HOST",
      "HTTP_USER_AGENT",
      "HTTP_ACCEPT",
      "HTTP_ACCEPT_LANGUAGE",
      "HTTP_X_FORWARDED_FOR",
      "HTTP_X_FORWARDED_PROTO",
      #"HTTP_ACCEPT_LANGUAGE",
      #"HTTP_ACCEPT_ENCODING",
      #"HTTP_ACCEPT_CHARSET",
      #"HTTP_KEEP_ALIVE",
      "HTTP_CONNECTION",
      #"HTTP_COOKIE",
      #"HTTP_CACHE_CONTROL",
      #"SERVER_NAME",
      #"SERVER_PORT",
      "QUERY_STRING"
    ].freeze

    def initialize(app, options={})
      @@host    = options[:host]     if options.keys.include?(:host)
      @@port    = options[:port]     if options.keys.include?(:port)
      @@backend = options[:backend]  if options.keys.include?(:backend)
      @app      = app
    end

    def call(env)
      @app_raised_exception = false
      req_start = Time.now.to_f
      data = {:env => {}}

      begin
        data.merge!({
          :user_id   => env['rack.session'][:user_id],
          :remote_ip => env['action_dispatch.remote_ip'].to_s,
          :backend   => @@backend,
          :xhr       => env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest',
          :timestamp => Time.now.to_f
        })
        @@headers.each {|key| data[:env][key.downcase] = env[key] unless env[key].blank?}
      rescue
        @local_error = $!
      end

      begin
        response  = @app.call env
      rescue Exception => exception
        @app_raised_exception = exception
        data.merge!(:message => exception.message,
                    :backtrace => exception.backtrace)
      ensure
        req_end   = Time.now.to_f
        data.merge!(
            :duration  => ((req_end - req_start) * 1000).to_i,
            :context   => env[Context.key],
            :status    => (!!@app_raised_exception || @local_error) ? 500 : response[0] # response contains [status, headers, body]
        )
      end

      begin
        self.class.track(data.to_json)
      rescue
        @local_error = $!
      end

      if @local_error
        @@logger.error(@local_error.message)
        @@logger.error(@local_error.backtrace.join("\n"))
      end

      raise @app_raised_exception if @app_raised_exception

      return response
    end

    class << self

      def development?
        defined?(Rails) && Rails.env.development?
      end

      # Writes the given `data` to the server, using the UDP protocol.
      # Times out after 1 second. If a write error occurs, data is lost.
      #

      def track(data)
        Timeout.timeout(1) do

          @@logger.debug("Sending to #{@@host}:#{@@port} : #{data.to_json}") if development?

          UDPSocket.open do |sock|
            sock.connect(@@host, @@port.to_i)
            sock.write_nonblock(data << "\n")
          end
        end

      rescue Timeout::Error, Errno::EWOULDBLOCK, Errno::EAGAIN, Errno::EINTR
        @@logger.error "Cannot track data: #{$!.message}"
      end
    end
  end
end
