$(function() {
  
  var updatePrice = function() {
    jQuery.get("average/usd?date=yes", function(data) {
      $("h2#price").fadeOut('fast',function(){
        $("h2#price").html("1 BTC = $" + data.value + " (updated " + data.date + ")")
      }).fadeIn("fast");
    });
  }
  updatePrice();
  setInterval(updatePrice, 5500);
  
  var options = {
  	animation : true,
    bezierCurve:false 
  }
  
  // - - - - - - - - - - - - - BTCs in Circulation - - - - - - - - - - - - - - - - - //

  var dataCirculation = {
  	labels : $("#circulation-chart").data("circulation-dates"),
  	datasets : [
  		{
  			fillColor : "rgba(230,171,39,0.5)",
  			strokeColor : "rgba(230,171,39,1)",
  			pointColor : "rgba(230,171,39,1)",
  			pointStrokeColor : "#fff",
  			data : $("#circulation-chart").data("circulation")
  		}
      
  	]
  }

  var ctx = $("#circulation-chart").get(0).getContext("2d");

  var circulationChart = new Chart(ctx).Line(dataCirculation, options);

  // - - - - - - - - - - - - - Current USD Market Price  - - - - - - - - - - - - - - //
  
  var dataMarketPrice = {
  	labels : $("#market-price-chart").data("market-price-dates"),
  	datasets : [
  		{
  			fillColor : "rgba(230,171,39,0.5)",
        strokeColor : "rgba(230,171,39,1)",
        pointColor : "rgba(230,171,39,1)",
        pointStrokeColor : "#fff",
  			data : $("#market-price-chart").data("market-price")
  		}
      
  	]
  }

  var ctx = $("#market-price-chart").get(0).getContext("2d");

  var marketPriceChart = new Chart(ctx).Line(dataMarketPrice, options);
    
})
