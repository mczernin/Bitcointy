# encoding: utf-8

require 'sinatra'
require 'haml'




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
  
  error_codes = ["ERR_SERVER_GONE_BANANAS", "ERR_DONT_CARE", "ERR_SYSTEM_FAILURE", "ERR_PROJECT_X_FAIL", "ERR_DOGS_CHEWING_MODEM", "ERR_NOPE", "ERR_LINUX_AINT_UNIX", "ERR_LS_NOT_FOUND", "ERR_GOVT_SHUTDOWN"]
  
	@random_error_code = error_codes.sample
	haml :index

end
