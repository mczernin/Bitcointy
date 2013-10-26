module Bitcoin
  EXCHANGES = ["blockchain", "mtgox", "btccharts", "coinbase", "bitpay"]
  
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
    http_request = HTTParty.get("https://blockchain.info/charts/market-price?format=json")
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
  
  module General
    require 'net/http'
 
    def convert_currency(from_curr = "EUR", to_curr = "USD", amount = 1000)
      http_request = HTTParty.get("http://currency-api.appspot.com/api/#{from_curr}/#{to_curr}.json?key=9f29f3321bfe25be46d551c842fefb7cad385ce2&amount=#{amount}")
      parsed_json = JSON.parse(http_request.body)
      (parsed_json["amount"]).to_f.round(2)
    end
  end
end

module Litecoin
  include Bitcoin
  
  def get_ltc_price(currency)
    case currency.upcase
    when "BTC"
      http_request = HTTParty.get("https://btc-e.com/api/2/ltc_btc/ticker")
      parsed_json = JSON.parse(http_request.body)   
      return_data = parsed_json["ticker"]["buy"]      
    else
      http_request = HTTParty.get("https://btc-e.com/api/2/ltc_usd/ticker")
      parsed_json = JSON.parse(http_request.body)   
      return_data = parsed_json["ticker"]["buy"]
      return_data = convert_currency("USD", currency, return_data) unless currency.upcase == "USD"
    end
    
    if http_request.code == 200
      if return_data.nil?
        @value = false
      else
        @value = (return_data).to_f.round(2)
      end
    else
      @value = false
    end
    @value
  end
  
  def get_ltc_historical_data
    http_request = HTTParty.get("http://www.cryptocoincharts.info/period-charts.php?period=alltime&resolution=day&pair=ltc-usd&market=btc-e")
    if http_request.code == 200
      require 'nokogiri'
      doc = Nokogiri.HTML(http_request.body)
    
      data = {:date => [], :values => []}

      doc.css('.table > tbody > tr').map do |row|
        data[:date] << Date.parse(row.elements.to_a.values_at(0).map(&:text)[0]).strftime("%d/%m/%Y")
        data[:values] << row.elements.to_a.values_at(4).map(&:text)[0].to_f
      end
      data[:date].flatten!
      data[:values].flatten!
    
      data[:date] = data[:date] - data[:date].slice(0, data[:date].length - 60)  
      data[:values] = data[:values] - data[:values].slice(0, data[:values].length - 60)  
    
      data
    else
      {:date => [], :values => []}
    end
  end
end
