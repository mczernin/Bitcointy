$(function() {
  
  var updatePrice = function() {
    jQuery.get("price/usd", function(data) {
      $("h3.price").html("1BTC == US$" + data + " (updated " + new Date().getHours() + ":" + new Date().getMinutes() + ")")
    });
  }
  
  setInterval(updatePrice, 1000);
  
  var options = {
  	animation : false,
    bezierCurve:false 
  }
  
  // - - - - - - - - - - - - - BTCs in Circulation - - - - - - - - - - - - - - - - - //

  var dataCirculation = {
  	labels : $("#circulation-chart").data("circulation-dates"),
  	datasets : [
  		{
  			fillColor : "rgba(151,187,205,0.5)",
  			strokeColor : "rgba(151,187,205,1)",
  			pointColor : "rgba(151,187,205,1)",
  			pointStrokeColor : "#fff",
  			data : $("#circulation-chart").data("circulation")
  		}
      
  	]
  }

  var ctx = $("#circulation-chart").get(0).getContext("2d");

  var myNewChart = new Chart(ctx).Line(dataCirculation, options);

  // - - - - - - - - - - - - - Current USD Market Price  - - - - - - - - - - - - - - //
  
  var dataMarketPrice = {
  	labels : $("#market-price-chart").data("market-price-dates"),
  	datasets : [
  		{
  			fillColor : "rgba(151,187,205,0.5)",
  			strokeColor : "rgba(151,187,205,1)",
  			pointColor : "rgba(151,187,205,1)",
  			pointStrokeColor : "#fff",
  			data : $("#market-price-chart").data("market-price")
  		}
      
  	]
  }

  var ctx = $("#market-price-chart").get(0).getContext("2d");

  var myNewChart = new Chart(ctx).Line(dataMarketPrice, options);
    
})
