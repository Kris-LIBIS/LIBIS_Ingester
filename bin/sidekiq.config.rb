require 'sidekiq'
require 'sidekiq/api'
Sidekiq.configure_client do |config|
  # noinspection RubyResolve
  config.redis = {
      url: @installer.config.sidekiq.redis_url,
      namespace: (installer.config.sidekiq.namespace rescue 'Ingester'),
  }
end
