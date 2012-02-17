require 'usage_tracker_middleware/context'

module UsageTrackerMiddleware
  class Railtie < Rails::Railtie
    initializer 'usage_tracker_middleware.insert_into_action_controller' do
      ActiveSupport.on_load :action_controller do
        ActionController::Base.instance_eval { include UsageTrackerMiddleware::Context }
      end
    end
  end
end
