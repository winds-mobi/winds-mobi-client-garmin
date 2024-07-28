import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Graphics as Gfx;
import Toybox.Position;
using Toybox.Time.Gregorian as Gregorian;
import Toybox.Time;
import Toybox.Lang;


var itemMemu = [];
var nearestStationsFound as Boolean = false;

class windsView extends WatchUi.View {
	
	private var currentStation;
	private var lat as String;
	private var lon as String;
	private var distance as String;
	var app = Application.getApp();
	private var deltaSpeed = null;
	
	var windAPIResult = null;
	var windAPIResultHist = null;
	
    function initialize(codeBalise) {
        View.initialize();
        currentStation = codeBalise;
        
        if(app.getProperty("enable_gps") && !nearestStationsFound){
        	Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onPosition));
        }
        
        if(itemMemu.size() == 0){	        
	      	for(var i = 8; i >= 1; i--){
	      		var balise = app.getProperty("balise_" + i);
		      	if(balise != null && !balise.equals("")){
				   itemMemu.add(balise);
				}
	      	}
      	}
        
        if(itemMemu.size() > 0){
	 		requestWindInformationByCode(itemMemu[codeBalise]);
			requestWindHistByCode(itemMemu[codeBalise]);
	 	}
    }
	
    // Load your resources here
    function onLayout(dc as Dc) as Void {
 
     }
	
    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
	    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
	    if(windAPIResult != null && windAPIResult["last"] != null){	    	
	    	drawRequestedData(dc);

	    }
	    else if (windAPIResult != null && windAPIResult["last"] == null) {
	    	dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);

			if(windAPIResult["detail"] != null) {
        		dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_SYSTEM_XTINY, windAPIResult["detail"], (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			}else {
         		dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_MEDIUM, "STATION ERROR ...", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			}

	    }
	    else{
	    	if(itemMemu.size() > 0){	    
	    		dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_MEDIUM, "Loading ...", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
	    	}else {
	    		if(app.getProperty("enable_gps") && !nearestStationsFound){
	    			dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_MEDIUM, "Waiting GPS ...", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
	    		} else {
	    			dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_SMALL, "No station found", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
	    		}
	    	}
	    }	    
    }
    
    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

	function requestWindHistByCode(code) as Void {
		Communications.makeWebRequest(
			Utils.WINDS_API_ENDPOINT + "/stations/" + code + "/historic/?duration=3600",
			null,
			{
          		:method => Communications.HTTP_REQUEST_METHOD_GET,
           		:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
			},
			method(:setStationHist)
		);		
	}

	function requestWindInformationByCode(code) as Void {
		Communications.makeWebRequest(
			Utils.WINDS_API_ENDPOINT + "/stations/" + code,
			null,
			{
          		:method => Communications.HTTP_REQUEST_METHOD_GET,
           		:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
			},
			method(:setStationInfo)
		);		
	}
	
	function requestWindsNearestStationsFromPositionAndDistance(lat, lon, distance) as Void {			
		Communications.makeWebRequest(
			Utils.WINDS_API_ENDPOINT + "/stations/",
			{
				"near-lat" => lat,
				"near-lon" => lon,
				"near-distance" => distance
			},
			{
          		:method => Communications.HTTP_REQUEST_METHOD_GET,
           		:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
			},
			method(:setNearestStations)
		);		
	}
	
	function setStationHist(responseCode, data) {
		self.windAPIResultHist = data;
		windstrend(data);
		WatchUi.requestUpdate();	
	}

	function setStationInfo(responseCode, data) {
		self.windAPIResult = data;	
		WatchUi.requestUpdate();	
	}
	
	function setNearestStations(responseCode, data) {
		for (var i = 0; i < data.size(); ++i) {
			itemMemu.add(data[i]["_id"]);
		}
		nearestStationsFound = true;
		WatchUi.switchToView(new $.windsView(currentStation), new $.WindsViewDelegate(currentStation), WatchUi.SLIDE_LEFT);
	}
	
	function onPosition(info) {
	    var myLocation = info.position.toDegrees();
	    lat = myLocation[0];
	    lon = myLocation[1];	    
	    var app = Application.getApp();
	    var distance = app.getProperty("gps_distance");
	    
	    if(distance == null || distance == 0){
	    	distance = 1;
	    }
	    
	    requestWindsNearestStationsFromPositionAndDistance(lat, lon, distance * 1000);
	}
	
    function windstrend(hist) {
        if (hist.size() < 2) {
            return 0; // Pas assez de données pour déterminer une tendance
        }

        var lastSpeed = hist[0]["w-avg"];
		var oneHourSpeed = hist[hist.size() - 1]["w-avg"];
		deltaSpeed = lastSpeed - oneHourSpeed;
		
		if(app.getProperty("mesure_unit") == 1) {
			var negatif = false;
			if(deltaSpeed < 0) {
				negatif = true;
			}
			deltaSpeed = Utils.convertKmhToKts(deltaSpeed.abs());
			if(negatif){
				deltaSpeed = -deltaSpeed;
			}
		}



    }
	
	function drawStatus(dc, status, info) as Void {
	
		
		var cx = dc.getWidth() / 2;
		var cy = dc.getHeight() / 2;
		
		if(status == 2) {
			dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_BLACK);
			//dc.fillCircle(cx, 20, 12);	
			var hourLast = Lang.format("$1$:$2$",[info.hour, info.min.format("%02d")]);
			dc.drawText(dc.getWidth() / 2, 20, Gfx.FONT_SMALL, hourLast, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
		}else if (status == 1){
			dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_BLACK);
			//dc.fillCircle(cx, 20, 12);
			var hourLast = Lang.format("$1$:$2$",[info.hour, info.min.format("%02d")]);
			dc.drawText(dc.getWidth() / 2, 20, Gfx.FONT_SMALL, hourLast, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
		} else if (status == 0){
			dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);
			//dc.fillCircle(cx, 20, 12);			
			dc.drawText(dc.getWidth() / 2, 20, Gfx.FONT_SMALL, "!!!!", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
		}		
	}
	
	function drawGpsStatus(dc){
	
		if(app.getProperty("enable_gps")) {	
			if(nearestStationsFound){
				dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_BLACK);
			}else{
				dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);
			}
			dc.drawText(dc.getWidth() / 2, dc.getHeight() - 15, Gfx.FONT_XTINY, "GPS", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
		}
		
	}
	
	var sector as String;
	var provider as String;
	var windAvg as Float;
	var windMax as Float;
	var baliseName as String;
	
	var windMaxHist as Float = 0;
	var windMinHist as Float = 999;
	var windAvgHist as Float = 0;	
	var lastTime as Number = 0;
	var altiValue as Number = 0;

	//Drawing UI element
	function drawRequestedData(dc) as Void {
				
			
			var fontH = dc.getFontHeight(Gfx.FONT_SMALL);
			var fontXTinyH = dc.getFontHeight(Gfx.FONT_XTINY);
			var fontTinyH = dc.getFontHeight(Gfx.FONT_TINY);

			var currentHeight = (dc.getHeight() / 2) - ((fontH + 7) * 2);
						
			windAvg = windAPIResult["last"]["w-avg"];
			windMax = windAPIResult["last"]["w-max"];
			lastTime = windAPIResult["last"]["_id"];
			altiValue = windAPIResult["alt"];
			var speedLabel = "km/h";
			var altiLabel = "m";
			
			if(app.getProperty("mesure_unit") == 1) {
				windAvg = Utils.convertKmhToKts(windAvg);
				windMax = Utils.convertKmhToKts(windMax);
				altiValue = Utils.convertMetersToFeet(altiValue);
				speedLabel = "Kts";
				altiLabel = "ft";
			}

			sector =  WatchUi.loadResource(Utils.orientation(windAPIResult["last"]["w-dir"]));
			provider = windAPIResult["pv-name"];

			baliseName = windAPIResult["name"];
			
			if(baliseName.length() > 18) {
				baliseName = baliseName.substring(0, 18) + "...";
			}
			
			var altitude = "Alt " +  altiValue + " " + altiLabel;
						
			dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_XTINY, provider, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			currentHeight = currentHeight + fontXTinyH + 2;
			dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_TINY, baliseName, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			currentHeight = currentHeight + fontXTinyH + 3;
			dc.drawText(dc.getWidth() / 2,  currentHeight, Gfx.FONT_XTINY, altitude, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			currentHeight = currentHeight + fontXTinyH + 3;
			dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_XTINY, windAvg.format("%.1f") + " " + speedLabel, (Gfx.TEXT_JUSTIFY_RIGHT| Gfx.TEXT_JUSTIFY_VCENTER));		
			
			try {
				dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_XTINY, " | Δ h-1: " + Utils.getSign(deltaSpeed) + deltaSpeed.format("%.1f"), (Gfx.TEXT_JUSTIFY_LEFT| Gfx.TEXT_JUSTIFY_VCENTER));
			} catch (e) {
        		//@todo
        	}
			
			currentHeight = currentHeight + fontTinyH;
			dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_XTINY, windMax.format("%.1f") + " " + speedLabel + " (max)", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));	
			currentHeight = currentHeight + fontTinyH + 20;
			
			dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_TINY, sector + " " + windAPIResult["last"]["w-dir"] + "°", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
			
			try {
				var time = new Toybox.Time.Moment(lastTime);	
				var info = Gregorian.info(time, Time.FORMAT_SHORT);	
				drawStatus(dc, retrieveStationStatus(windAPIResult), info);	
			} catch (e) {
        		//@todo
        	}
			
			try {			
				drawGpsStatus(dc);		
			} catch (e) {
        		//@todo
        	}	
	}	
	
	var stationValue as Number;
	var lastValue as Number;
	function retrieveStationStatus(station) as Number {
	
		
        if (station["status"].equals("green")) {
            stationValue = 2;
        } else {
            if (station["status"].equals("orange")) {
                stationValue = 1;
            } else {
                stationValue = 0;
            }
        }
        		
		
        if (station["last"]) {
			var stationTimeStamp = station["last"]["_id"];
			var currentTimeStamp = Time.now().value();
			var diffTimeStamp = currentTimeStamp - stationTimeStamp;
            
            var nowSub2h = 7200;
            var nowLess1h = 3600;
            var nowAdd5min = currentTimeStamp + 300;
            
            if (diffTimeStamp > nowSub2h) {
                lastValue = 0;
            } else if (diffTimeStamp > nowLess1h) {
                lastValue = 1;
            } else if (stationTimeStamp > nowAdd5min) {
                lastValue = 0;
            } else {
                lastValue = 2;
            }
        } else {
            lastValue = 0;
        }
		
        return lastValue < stationValue ? lastValue : stationValue;
	}	
}	
	




//! Handle input on the object store view
class WindsViewDelegate extends WatchUi.BehaviorDelegate {
	
	
	var selectedItem;
	
	
    //! Constructor
    public function initialize(selectedItem) {
    	self.selectedItem = selectedItem;
        BehaviorDelegate.initialize();
    }

    //! Handle going to the next view
    //! @return true if handled, false otherwise
    public function onNextPage() as Boolean { 
    	if(selectedItem < itemMemu.size() - 1) {
    		selectedItem = selectedItem + 1;
    	}else{
    		selectedItem = 0;
    	}
        WatchUi.switchToView(new $.windsView(selectedItem), new $.WindsViewDelegate(selectedItem), WatchUi.SLIDE_LEFT);
        return true;
    }
    
    public function onKey(evt as KeyEvent) as Boolean {
    	if (evt.getKey() == WatchUi.KEY_ENTER) {    		
            return onNextPage();
        }
		return false;
    }
    
    function onTap(clickEvent) {
        return onNextPage();
    }
	
}














