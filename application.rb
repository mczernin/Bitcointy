# encoding: utf-8

require 'sinatra'
require 'haml'
require 'httparty'
require 'json'
require './bitcoin.rb'
include Bitcoin
include Bitcoin::General
include Litecoin

configure do
	set :views, "#{File.dirname(__FILE__)}/views"
end

error do
	@e = request.env['sinatra.error']
	puts @e.backtrace.join("\n")
  content_type 'text/html'
  
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
  haml :index
end

get '/app/:pass' do |password|
  if password != "PabloBTCApp"
    halt(404)
  else
    content_type 'text/json'
    
    return_array = [[], []]
    ["USD", "EUR", "GBP", "CAD"].each do |curr|
      return_array[0] << {:currency => curr, :value => average_price(curr)}
    end
    ["BTC", "USD", "EUR", "GBP", "CAD"].each do |curr|
      return_array[1] << {:currency => curr, :value => get_ltc_price(curr)}
    end
    return_array.to_json
  end
end

get '/charts/:type' do |type|
  content_type 'text/json'
  case type.to_sym
  when :circulation
    {:date => btc_in_circulation(true), :values => btc_in_circulation}.to_json
  when :price
    {:date => market_price(true), :values => market_price}.to_json
  when :transactions
    {:date => number_of_transactions(true), :values => number_of_transactions}.to_json
  else
    {:error => true}.to_json
  end

end

get '/ltc/:currency' do |currency|
  content_type 'text/json'
  price = get_ltc_price(currency)
  
  if !price.nan? || !price
    {
      :currency => currency.upcase,
      :value => price
    }.to_json
  else  
    {
      :error => true,
      :description => "Error! Probably a unexistant currency"
    }.to_json
  end
end


get '/convert/:amount/:currency' do |amount, currency|
  content_type 'text/json'
  avg_price = average_price(currency)
  
  converted_rate = (amount.to_f * avg_price).round(2)
  if !converted_rate.nan?
    {
      :currency => currency.upcase,
      :value => converted_rate
    }.to_json
  else  
    {
      :error => true,
      :description => "Error! Probably a unexistant currency"
    }.to_json
  end
end

get '/convert_ltc/:amount/:currency' do |amount, currency|
  content_type 'text/json'
  avg_price = get_ltc_price(currency)
  
  converted_rate = (amount.to_f * avg_price).round(2)
  if !converted_rate.nan?
    {
      :currency => currency.upcase,
      :value => converted_rate
    }.to_json
  else  
    {
      :error => true,
      :description => "Error! Probably a unexistant currency"
    }.to_json
  end
end

get '/price/:currency' do |currency|
  content_type 'text/plain'
  price = get_price(currency, "blockchain")
  if price
    price.to_s
  else  
    {
      :error => true,
      :description => "Error! Probably a unexistant currency"
    }.to_json
  end

end

get '/average/:currency' do |currency|
  content_type 'text/json'
  average = average_price(currency)  
  
  if !average.nan?
    {
      :currency => currency.upcase,
      :value => average
    }.to_json
  else
    {
      :error => true,
      :description => "Error! Probably a unexistant currency"
    }.to_json
  end
  
end

get '/all/:currency' do |currency|
  content_type 'text/json'
    
  response = []
  
  EXCHANGES.each do |exchange|
    response << {:exchange => exchange, :currency => currency.upcase, :value => get_price(currency, exchange)}
  end
  map = response.map {|item| item[:value] }
  if map.uniq.length != 1 && map.uniq != [false]
    response.to_json
  else
    {
      :error => true,
      :description => "Error! Probably a unexistant currency"
    }.to_json
  end
  
end

get '/:exchange/:currency' do |exchange, currency|
  content_type 'text/json'
  
  value = get_price(currency, exchange)
  
  if value
  
    response = {
      :currency => currency.upcase,
      :value => value.to_f
    }
    response.to_json
  else
    response = {
      :error => true,
      :description => "Error! Probably a unexistant currency or wrong exchange"
    }
    response.to_json
  end
end

