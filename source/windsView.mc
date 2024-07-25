import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Graphics as Gfx;
import Toybox.Position;
using Toybox.Time.Gregorian as Gregorian;
import Toybox.Time;
import Toybox.Lang;
import Toybox.System;


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
	hidden var centerY = 109;
    // Update the view
    function onUpdate(dc as Dc) as Void {
	    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
	    if(windAPIResult != null && windAPIResult["last"] != null){	    	
	    	drawRequestedData(dc);
	    }

		if(windAPIResultHist != null){	    	
	    	drawHrChart(dc, 10, centerY-51, 50);
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

	function requestWindHistByCode(code) as Void {
		Communications.makeWebRequest(
			Utils.WINDS_API_ENDPOINT + "/stations/" + code + "/historic/?duration=7200",
			null,
			{
          		:method => Communications.HTTP_REQUEST_METHOD_GET,
           		:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
			},
			method(:setStationHist)
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
		if(data != null) {
		System.println(getMax(data));
		System.println(getMin(data));
		System.println(getAverage(data));
		
		}
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
	
	var lastTime as Number = 0;
	var altiValue as Number = 0;

	//Drawing UI element
	function drawRequestedData(dc) as Void {
				
			
			var fontH = dc.getFontHeight(Gfx.FONT_SMALL);
			var fontXTinyH = dc.getFontHeight(Gfx.FONT_XTINY);

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
			currentHeight = currentHeight + fontXTinyH + 4;
			dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_SMALL, baliseName, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			currentHeight = currentHeight + fontXTinyH + 3;
			dc.drawText(dc.getWidth() / 2,  currentHeight, Gfx.FONT_XTINY, altitude, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			currentHeight = currentHeight + fontXTinyH + 3;
			dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_SMALL, windAvg.format("%.1f") + " " + speedLabel, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
			currentHeight = currentHeight + fontH + 3;
			dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_SMALL, windMax.format("%.1f") + " " + speedLabel + " (max)", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));	
			currentHeight = currentHeight + fontH + 2;
			dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_SMALL, sector + " " + windAPIResult["last"]["w-dir"] + "°", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
			
			try {
				var now = new Toybox.Time.Moment(Time.now().value());
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


	function getMax(hist) {
		var max = null;
		if(hist == null) {
			return 0;
		}
        for(var i = 0; i < hist.size(); i++){
            if(hist[i] != null){
                if(max == null || hist[i]["w-avg"]>max){ 
                    max = hist[i]["w-avg"];
                }
            }
        }
        return max;
	}

	function getMin(hist){
        var min = null;
		if(hist == null) {
			return 0;
		}
        for(var i = 0; i < hist.size(); i++){
            if(hist[i] != null){
                if(min == null || hist[i]["w-avg"]<min){ 
                    min = hist[i]["w-avg"];
                }
            }
        }
        return min;
    }

	function getAverage(hist){
        var sum = 0;
        var size = 0;
        for(var i = 0; i < hist.size(); i++){
            if(hist[i] != null){
                sum = sum + hist[i]["w-avg"];
                size++;
            }
        }
        if(size == 0) {
            return null;
        } else {
            return (sum.toFloat()/size.toFloat());
        }
    }

	hidden var lightColor = Graphics.COLOR_LT_GRAY;
	
    function drawHrChart(dc, x, y, height){  
        // chart alignment and crop
        var maxHr = getMax(windAPIResultHist); 
        if(maxHr != null){  // no data, no chart
            var h; var offset=50; var last = null;
            y += height; // y should be at top

            var minHr = getMin(windAPIResultHist); 
            h = getAverage(windAPIResultHist); 
            
            if(h==null){h=0;} 
            if(h<minHr){ minHr = h;}
            if(h>maxHr){ maxHr = h;}

            // scale
            maxHr = maxHr.toNumber() >> 1;
            minHr = minHr.toNumber() >> 1;
            h = h.toNumber() >> 1;
        
            // cut offset which will not fit into an area
            if(maxHr-minHr>height){
                offset = maxHr-height; // put max to the top of the chart
                if(h<offset && h>0){
                    offset = h-10; // make sure current hr is shown
                }
            } else {
                offset = (((minHr+maxHr)-height)/2).toNumber(); // put it in the middle of the chart
            }          
            dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);

            // draw hr history
            var data = windAPIResultHist;
            var position = data.size() - 1; var size = data.size();
            var colorLineStart; var colorLineEnd; var midPoint = null;

            // set current hr to be drawn and draw it            
            if(h > 0){
                dc.drawPoint(x+size*2, y-h+offset);
                last = h;
            }

            for(var i = size-1; i>=0; i--){
                h = data[position]["w-avg"];
                if(h != null){
                    h = h.toNumber() >> 1;

                    // line can have two colors if it crossses a chart boundary
                    colorLineStart = (h>=offset && h<= offset+height) ? Graphics.COLOR_DK_RED : lightColor; 
                    dc.setColor(colorLineStart, Graphics.COLOR_TRANSPARENT);
                    if(last != null){
                        colorLineEnd = (last >= offset && last <= offset+height) ? Graphics.COLOR_DK_RED : lightColor;  
                        
                        // when line crosses boundary
                        if(colorLineStart != colorLineEnd){
                            if(colorLineStart == Graphics.COLOR_DK_RED){   // h (left value) is within boundaries
                                midPoint = (last<offset) ? y : y-height;  
                                dc.setColor(colorLineEnd, Graphics.COLOR_TRANSPARENT);
                                dc.drawLine(x+i*2+1, midPoint, x+i*2+2, y-last+offset); 
                                dc.setColor(colorLineStart, Graphics.COLOR_TRANSPARENT);
                                dc.drawLine(x+i*2, y-h+offset, x+i*2+1, midPoint);  
                            } else {    // h (left value) is out of boundaries
                                midPoint = (h<offset) ? y : y-height;
                                dc.setColor(colorLineStart, Graphics.COLOR_TRANSPARENT);
                                dc.drawLine(x+i*2, y-h+offset, x+i*2+1, midPoint); 
                                dc.setColor(colorLineEnd, Graphics.COLOR_TRANSPARENT);
                                dc.drawLine(x+i*2+1, midPoint, x+i*2+2, y-last+offset);  
                            }
                        } else {
                            dc.drawLine(x+i*2, y-h+offset, x+i*2+2, y-last+offset);    
                        }
                    } else {
                        dc.drawPoint(x+i*2, y-h+offset);
                    }
                }
                last = h; // value to continue from in the next iteration
                position--;
                if(position<0){
                    position = size-1;
                }
            }
        }
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














