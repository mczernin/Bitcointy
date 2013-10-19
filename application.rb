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

  EXCHANGES = ["blockchain", "mtgox", "btccharts", "coinbase"]

	def partial(page, options={})
		haml page.to_sym, options.merge!(:layout => false)
	end
  
  def get_price(currency, exchange)
    currency = currency.upcase
    case exchange
    when "blockchain"
      json = HTTParty.get("http://blockchain.info/en/ticker").body
      parsed_json = JSON.parse(json)
      @value = (parsed_json[currency]["buy"]).to_f.round(2)
    when "mtgox"
      json = HTTParty.get("http://data.mtgox.com/api/2/BTC#{currency}/money/ticker_fast").body
      parsed_json = JSON.parse(json)
      @value = (parsed_json["data"]["buy"]["value"]).to_f.round(2)
    when "btccharts"
      json = HTTParty.get("http://api.bitcoincharts.com/v1/weighted_prices.json").body
      parsed_json = JSON.parse(json)
      @value = (parsed_json[currency]["24h"]).to_f.round(2)
    when 'coinbase'
      json = HTTParty.get("https://coinbase.com/api/v1/currencies/exchange_rates").body
      parsed_json = JSON.parse(json)
      @value = (parsed_json["btc_to_#{currency.downcase}"]).to_f.round(2)
    else
      return false
    end
    @value
  end
  
  def btc_in_circulation(dates=false)
    json = HTTParty.get("http://blockchain.info/charts/total-bitcoins?format=json").body
    parsed_json = JSON.parse(json)
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
  
  def market_price(dates=false)
    json = HTTParty.get("http://blockchain.info/charts/market-price?format=json").body
    parsed_json = JSON.parse(json)
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
  
  def average_price(currency)
    
    prices = []
  
    EXCHANGES.each do |exchange|
      prices << get_price(currency, exchange)
    end
    (prices.inject(0.0) { |sum, el| sum.to_f + el.to_f } / prices.size).round(2)
    
  end
	
end

get '/' do
  haml :index
end

get '/charts/:type' do |type|
  content_type 'text/json'
  case type.to_sym
  when :circulation
    if params[:date]
      btc_in_circulation(true).to_json
    else
      btc_in_circulation.to_json
    end
  when :price
    if params[:date]
      market_price(true).to_json
    else
      market_price.to_json
    end
  end
end

get '/price/:currency' do |currency|
  content_type 'text/plain'
  get_price(currency, "blockchain").to_s
end

get '/average/:currency' do |currency|
  content_type 'text/json'

  average = average_price(currency)  
  if params[:date]
    response = {:currency => currency.upcase, :value => average, :date => Time.now.strftime("%I:%M %p").to_s}
  else
    response = {:currency => currency.upcase, :value => average}
  end
  
  response.to_json

end

get '/all/:currency' do |currency|
  content_type 'text/json'
    
  response = []
  
  EXCHANGES.each do |exchange|
    response << {:exchange => exchange, :currency => currency.upcase, :value => get_price(currency, exchange)}
  end
  
  response.to_json
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
      :description => "Unknown exchange!"
    }
    response.to_json
  end
end

