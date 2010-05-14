class DynamicDomain
  def initialize(app, default_domain)
    @app = app
    @default_domain = default_domain
  end

  def call(env)
    host = env["HTTP_HOST"].split(':').first
    if custom_domain?(host)
      ActionMailer::Base.default_url_options[:host] = host
    else
      ActionMailer::Base.default_url_options[:host] = @default_domain
      host = ".#{@default_domain}"
    end

    env["rack.session.options"][:domain] = host
    @app.call(env)
  end

  def custom_domain?(host)
    host !~ Regexp.new("#{@default_domain}$", Regexp::IGNORECASE)
  end
end

