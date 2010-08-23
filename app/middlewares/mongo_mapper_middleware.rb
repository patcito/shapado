class MongoMapperMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if Rails.configuration.cache_classes
      MongoMapper::Plugins::IdentityMap.clear
    else
      MongoMapper::Document.descendants.clear
      MongoMapper::Plugins::IdentityMap.models.clear
    end

    @app.call(env)
  end
end

