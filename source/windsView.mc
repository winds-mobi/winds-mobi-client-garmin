import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Graphics as Gfx;

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
	    	dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Gfx.FONT_MEDIUM, "Chargement ...", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
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
	
	function drawStatus(dc, color) as Void {
	
		var cx = dc.getWidth() / 2;
		var cy = dc.getHeight() / 2;
		
		if(color.equals("green")) {
			dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_GREEN);
			dc.fillCircle(cx, 20, 12);	
		}else if (color.equals("orange")){
			dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_ORANGE);
			dc.fillCircle(cx, 20, 12);	
		} else if (color.equals("red")){
			dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_RED);
			dc.fillCircle(cx, 20, 12);			
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
										
			windAvg = windAPIResult["last"]["w-avg"];
			windMax = windAPIResult["last"]["w-max"];
			var sector as String = Utils.orientation(windAPIResult["last"]["w-dir"]);
								
			baliseName = windAPIResult["name"];
			
			if(baliseName.length() > 16) {
				baliseName = baliseName.substring(0, 16) + "...";
			}
			
			
			var altitude = "Alt " + windAPIResult["alt"] + " m";
				
			dc.drawText(dc.getWidth() / 2, 50, Gfx.FONT_SMALL, baliseName, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			dc.drawText(dc.getWidth() / 2, 80, Gfx.FONT_SMALL, altitude, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
								
			dc.drawText(dc.getWidth() / 2, 120, Gfx.FONT_MEDIUM, windAvg.format("%.1f") + " km/h", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
			dc.drawText(dc.getWidth() / 2, 150, Gfx.FONT_SMALL, windMax.format("%.1f") + " km/h (max)", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));	
							
			dc.drawText(dc.getWidth() / 2, 190, Gfx.FONT_LARGE, sector + " " + windAPIResult["last"]["w-dir"] + "°", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
			drawStatus(dc, windAPIResult["status"]);
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
	
}














