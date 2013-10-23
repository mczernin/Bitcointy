# encoding: utf-8

require 'sinatra'
require 'haml'
require 'httparty'
require 'json'

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

  EXCHANGES = ["blockchain", "mtgox", "btccharts", "coinbase", "bitpay"]

	def partial(page, options={})
		haml page.to_sym, options.merge!(:layout => false)
	end
  
  def get_price(currency, exchange)
    currency = currency.upcase
    case exchange
    when "blockchain"
      http_request = HTTParty.get("http://blockchain.info/en/ticker")
      if http_request.code == 200
        parsed_json = JSON.parse(http_request.body)
        if parsed_json[currency].nil?
          @value = false
        else
          @value = (parsed_json[currency]["buy"]).to_f.round(2)
        end
      else
        @value = false
      end
    when "mtgox"
      http_request = HTTParty.get("http://data.mtgox.com/api/2/BTC#{currency}/money/ticker_fast")
      if http_request.code == 200
        parsed_json = JSON.parse(http_request.body)
        @value = (parsed_json["data"]["buy"]["value"]).to_f.round(2)
      else
        @value = false
      end
    when "btccharts"
      http_request = HTTParty.get("http://api.bitcoincharts.com/v1/weighted_prices.json")
      if http_request.code == 200
        parsed_json = JSON.parse(http_request.body)
        if parsed_json[currency].nil?
          @value = false
        else
          @value = (parsed_json[currency]["24h"]).to_f.round(2)
        end
      else
        @value = false
      end
    when 'coinbase'
      http_request = HTTParty.get("https://coinbase.com/api/v1/currencies/exchange_rates")
      if http_request.code == 200
        parsed_json = JSON.parse(http_request.body)
        if parsed_json["btc_to_#{currency.downcase}"].nil?
          @value = false
        else
          @value = (parsed_json["btc_to_#{currency.downcase}"]).to_f.round(2)
        end
      else
        @value = false
      end
    when 'bitpay'
      http_request = HTTParty.get("https://bitpay.com/api/rates")
      if http_request.code == 200
        parsed_json = JSON.parse(http_request.body)
        
        rate = parsed_json.map {|i| if i["code"] == "USD"; i; end }.compact[0]
        
        if rate == []
          @value = false
        else
          @value = (rate["rate"]).to_f.round(2)
        end
      else
        @value = false
      end
    else
      return false
    end
    @value
  end
  
  def btc_in_circulation(dates=false)
    http_request = HTTParty.get("http://blockchain.info/charts/total-bitcoins?format=json")
    if http_request.code == 200
      parsed_json = JSON.parse(http_request.body)
      return_data = parsed_json["values"]
      content = []
      if dates
        return_data.each do |item|
          content << Time.at(item["x"]).strftime("%d/%m/%Y")
        end
      else
        return_data.each do |item|
          content << item["y"]
        end
      end
      content - content.slice(0, content.length - 50)
    end
  end
  
  def market_price(dates=false)
    http_request = HTTParty.get("http://blockchain.info/charts/market-price?format=json")
    if http_request.code == 200
      parsed_json = JSON.parse(http_request.body)
      return_data = parsed_json["values"]
      content = []
      if dates
        return_data.each do |item|
          content << Time.at(item["x"]).strftime("%d/%m/%Y")
        end
      else
        return_data.each do |item|
          content << item["y"]
        end
      end
      content - content.slice(0, content.length - 20)
    end
  end
  
  def average_price(currency)
    
    prices = []
  
    EXCHANGES.each do |exchange|
      prices << get_price(currency, exchange)
    end
    prices.delete_if { |el| el == false }
    (prices.inject(0.0) { |sum, el| sum.to_f + el.to_f } / prices.size).round(2)
    
  end
  
  def number_of_transactions(dates=false) 
    http_request = HTTParty.get("http://blockchain.info/charts/n-transactions?format=json")
    if http_request.code == 200
      parsed_json = JSON.parse(http_request.body)
      return_data = parsed_json["values"]
      content = []
      if dates
        return_data.each do |item|
          content << Time.at(item["x"]).strftime("%d/%m/%Y")
        end
      else
        return_data.each do |item|
          content << item["y"]
        end
      end
      content - content.slice(0, content.length - 60)  
    end
  end
	
end

get '/' do
  haml :index
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

