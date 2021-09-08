import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.Time.Gregorian as Gregorian;

var itemMemu = [];

class windsView extends WatchUi.View {

    private var _indicator as PageIndicator;
	private var codeBalise as String;
	
	var windAPIResult = null;
	var windAPIResultHist = null;
	
    function initialize(codeBalise) {
        View.initialize();
                       
        if(itemMemu.size() == 0){
	        var app = Application.getApp();
	      	for(var i = 8; i >= 1; i--){
	      		var balise = app.getProperty("balise_" + i);
		      	if(balise != null && !balise.equals("")){
				   itemMemu.add(balise);
				}	
	      	}
      	}
        
        
	 	requestWindInformationByCode(itemMemu[codeBalise]);
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
	    if(windAPIResult != null){	    	
	    	drawRequestedData(dc);
	    }else{
	    	dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_MEDIUM, "Loading ...", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
	    }
	    
    }
    
    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

		
	function requestWindInformationByCode(code) as Void {
			
		Communications.makeJsonRequest(
		"https://winds.mobi/api/2.2/stations/" + code,
		{
		},
		{
		"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
		},
		method(:setStationInfo)
		);		
	}
	
	function requestWindHistoryByCode(code) as Void {
					
		
		Communications.makeJsonRequest(
		"https://winds.mobi/api/2/stations/" + code + "/historic/?duration=3600",
		{
		},
		{
		"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED
		},
		method(:setStationHistory)
		);		
	}
	
	function setStationInfo(responseCode, data) {
		self.windAPIResult = data;	
		WatchUi.requestUpdate();	
	}
	
	function setStationHistory(responseCode, data) {
		self.windAPIResultHist = data;		
		WatchUi.requestUpdate();		
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
			dc.drawText(dc.getWidth() / 2,  currentHeight, Gfx.FONT_SMALL, altitude, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			currentHeight = currentHeight + fontH + 5;
			dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_SMALL, windAvg.format("%.1f") + " km/h", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
			currentHeight = currentHeight + fontH + 5;
			dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_SMALL, windMax.format("%.1f") + " km/h (max)", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));	
			currentHeight = currentHeight + fontH + 5;
			dc.drawText(dc.getWidth() / 2, currentHeight, Gfx.FONT_SMALL, sector + " " + windAPIResult["last"]["w-dir"] + "°", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
			
			var now = new Toybox.Time.Moment(Time.now().value());
			
			var time = new Toybox.Time.Moment(lastTime);	
			var info = Gregorian.info(time, Time.FORMAT_SHORT);		
			drawStatus(dc, getStationStatus(windAPIResult), info);
						
	}	
	
	
	//Retrieve station status
	function getStationStatus(station) as Number {
	
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
    }
    
    function onTap(clickEvent) {
        return onNextPage();
    }
	
}














