require 'rubygems'
require 'usage_tracker_middleware/log'

module UsageTrackerMiddleware
  class << self
    # Memoizes the current environment
    def env
      @env ||= ENV['RAILS_ENV'] || ARGV[0] || 'development'
    end
  end
end
