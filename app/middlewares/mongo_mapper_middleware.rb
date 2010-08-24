class MongoMapperMiddleware
  def initialize(app)
    @app = app
  end

  def clear_descendants(k)
    return unless k.respond_to?(:descendants)
    k.descendants do |d|
      clear_descendants(d)
    end
    k.descendants.clear
  end

  def call(env)
    if Rails.configuration.cache_classes
      MongoMapper::Plugins::IdentityMap.clear
    else
      clear_descendants(MongoMapper::Document)
      clear_descendants(MongoMapper::EmbeddedDocument)
      MongoMapper::Plugins::IdentityMap.clear
      MongoMapper::Plugins::IdentityMap.models.clear
    end

    @app.call(env)
  end
end
