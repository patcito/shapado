require 'time'
require 'rack/utils'

class GridfsMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if env["PATH_INFO"] =~ /^\/_files\/([^\/?]+)/
      @model = $1.classify.constantize rescue nil
      return forbidden if @model.nil?

      dup._call(env)
    else
      @app.call(env)
    end
  end

  def _call(env)
    request = Rack::Request.new(env)
    params = request.GET

    @file = @model.find_file_from_params(params, request)
    return not_found if @file.nil?

    if @file.present?
      serving
    else
      not_found
    end
  end

  def forbidden
    body = "Forbidden\n"
    [403, {"Content-Type" => "text/plain",
           "Content-Length" => body.size.to_s,
           "X-Cascade" => "pass"},
     [body]]
  end

  def serving
    body = self
    [200, {
      "Last-Modified"  => Time.now.httpdate,
      "Content-Type"   => @file.content_type,
      "Content-Length" => @file.size.to_s
    }, body]
  end

  def not_found
    body = "File not found: #{@path_info}\n"
    [404, {"Content-Type" => "text/plain",
       "Content-Length" => body.size.to_s,
       "X-Cascade" => "pass"},
     [body]]
  end

  def each
    f = @file.get
    while part = f.read(8192)
      yield part
      break if part.empty?
    end
  end
end

