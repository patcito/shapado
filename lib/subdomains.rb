# Copyright (c) 2005 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
module Subdomains
  def self.included(controller)
    controller.helper_method(:tag_domain, :current_tag, :tag_host, :tag_url,
                                                     :subdomain_url,:domain_url)
  end

  protected
  def subdomain_url(subdomain, options = {})
    options = {:controller=>"/welcome",:action=>"index"}.merge(options)
    host = options.delete(:custom)
    host = request.host.split("\.").last(2).join(".") unless host
    request.protocol + "#{subdomain}." + host + request.port_string +
                                          url_for({:only_path =>true}.merge(options))
  end

  def domain_url(options = {})
    host = options.delete(:custom)
    host = request.host.split("\.").last(2).join(".") unless host

    domain = request.protocol + "#{host}" + request.port_string
    if !options.empty?
      options = {:controller=>"/welcome",:action=>"index"}.merge(options)
      domain += url_for({:only_path =>true}.merge(options))
    end

    domain
  end

  def tag_url(tag, use_ssl = request.ssl?)
    (use_ssl ? "https://" : "http://") + tag_host(tag)
  end

  def tag_host(tag)
    account_host = ""
    account_host << tag + "."
    account_host << tag_domain
  end

  def tag_domain
    tag_domain = ""
    tag_domain << request.subdomains[1..-1].join(".") + "." if request.subdomains.size > 1
    tag_domain << request.domain + request.port_string
  end

  def current_tag
    request.subdomains.first
  end
end
