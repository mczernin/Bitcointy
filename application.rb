# encoding: utf-8

require 'sinatra'
require 'haml'

module Rack
  class Request
    def subdomains(tld_len=1) # we set tld_len to 1, use 2 for co.uk or similar
      # cache the result so we only compute it once.
      @env['rack.env.subdomains'] ||= lambda {
        # check if the current host is an IP address, if so return an empty array
        return [] if (host.nil? ||
                      /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.match(host))
        host.split('.')[0...(1 - tld_len - 2)] # pull everything except the TLD
      }.call
    end
  end
end


configure do
	set :views, "#{File.dirname(__FILE__)}/views"
end

error do
	@e = request.env['sinatra.error']
	puts @e.backtrace.join("\n")
	if ENV['RACK_ENV'] == "production"
		haml :"errors/error", layout: :"errors/error_layout"
	else
		haml :"errors/error_dev", layout: false
	end
end

helpers do

	def partial(page, options={})
		haml page.to_sym, options.merge!(:layout => false)
	end
	
end

get '/' do
  require 'geocoder'
  
  require 'open-uri'
  
  @remote_ip = open('http://whatismyip.akamai.com').read
  
  @ip = Geocoder.search(request.ip)
  
  @public_ip = Geocoder.search(@remote_ip)
  
  if ENV['RACK_ENV'] == "production"
    if !["US", "AU", "CA"].include?(@ip[0].country_code) and request.host != "eu.pmerino.me" 
      redirect 'http://eu.pmerino.me' 
    end
  end
  
  error_codes = ["ERR_SERVER_GONE_BANANAS", "ERR_DONT_CARE", "ERR_SYSTEM_FAILURE", "ERR_PROJECT_X_FAIL", "ERR_DOGS_CHEWING_MODEM", "ERR_NOPE", "ERR_LINUX_AINT_UNIX", "ERR_LS_NOT_FOUND", "ERR_GOVT_SHUTDOWN"]
  
  @random_error_code = error_codes.sample
  haml :index
end
