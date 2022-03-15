import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Graphics as Gfx;
import Toybox.Position;
using Toybox.Time.Gregorian as Gregorian;
import Toybox.Time;

var itemMemu = [];
var nearestStationsFound as Boolean = false;

class windsView extends WatchUi.View {
	
	private var currentStation;
	private var lat as String;
	private var lon as String;
	private var distance as String;
	var app = Application.getApp();
	
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
    		dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_MEDIUM, "STATION ERROR ...", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
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
	
	function drawWaitingSignalGPS(dc) as Void {
		dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_MEDIUM, "Waiting GPS ...", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));	
	}
	
	
	//Drawing UI element
	function drawRequestedData(dc) as Void {
				
			var windAvg as Float;
			var windMax as Float;
			var baliseName as String;
			
			var windMaxHist as Float = 0;
			var windMinHist as Float = 999;
			var windAvgHist as Float = 0;	
			var lastTime as Number = 0;
										
			var fontH = dc.getFontHeight(Gfx.FONT_SMALL);
			var currentHeight = (dc.getHeight() / 2) - ((fontH + 5) * 2);
						
			windAvg = windAPIResult["last"]["w-avg"];
			windMax = windAPIResult["last"]["w-max"];
			lastTime = windAPIResult["last"]["_id"];
			
			var sector as String = Utils.orientation(windAPIResult["last"]["w-dir"]);
								
			baliseName = windAPIResult["name"];
			
			if(baliseName.length() > 15) {
				baliseName = baliseName.substring(0, 15) + "...";
			}
			
			var altitude = "Alt " + windAPIResult["alt"] + " m";
						
				
			dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_SMALL, baliseName, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			currentHeight = currentHeight + fontH;
			dc.drawText(dc.getWidth() / 2,  currentHeight, Gfx.FONT_XTINY, altitude, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			currentHeight = currentHeight + fontH + 5;
			dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_SMALL, windAvg.format("%.1f") + " km/h", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
			currentHeight = currentHeight + fontH + 5;
			dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_SMALL, windMax.format("%.1f") + " km/h (max)", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));	
			currentHeight = currentHeight + fontH + 5;
			dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_SMALL, sector + " " + windAPIResult["last"]["w-dir"] + "°", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
			
			try {
				var now = new Toybox.Time.Moment(Time.now().value());
				var time = new Toybox.Time.Moment(lastTime);	
				var info = Gregorian.info(time, Time.FORMAT_SHORT);	
				drawStatus(dc, retrieveStationStatus(windAPIResult), info);	
			} catch (e) {
        		
        	}
						
			drawGpsStatus(dc);			
	}	
	
	
	function retrieveStationStatus(station) as Number {
	
		var stationValue as Number;
        if (station["status"].equals("green")) {
            stationValue = 2;
        } else {
            if (station["status"].equals("orange")) {
                stationValue = 1;
            } else {
                stationValue = 0;
            }
        }
        		
		var lastValue as Number;
        if (station["last"]) {
            var last = new Toybox.Time.Moment(station["last"]["_id"]);
            var now = new Toybox.Time.Moment(Time.now().value());
            
            var nowSub2h = now.subtract(new Time.Duration(7200));
            var nowLess1h = now.subtract(new Time.Duration(3600));
            var nowAdd5min = now.add(new Time.Duration(300));
            
            if (last.lessThan(nowSub2h)) {
                lastValue = 0;
            } else if (last.lessThan(nowLess1h)) {
                lastValue = 1;
            } else if (last.greaterThan(nowAdd5min)) {
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














