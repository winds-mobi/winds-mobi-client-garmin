import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Graphics as Gfx;

class windsView extends WatchUi.View {

	var windAPIResult = null;
		
    function initialize() {
        View.initialize();
	 	requestWindInformationByCode("pioupiou-384");

    }
	
    // Load your resources here
    function onLayout(dc as Dc) as Void {
        //setLayout(Rez.Layouts.MainLayout(dc));        

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
	
	function setStationInfo(responseCode, data) {
		self.windAPIResult = data;		
		WatchUi.requestUpdate();		
	}
		
	//Drawing UI element
	function drawRequestedData(dc) as Void {
				
			var windAvg as Float;
			var windMax as Float;
			windAvg = windAPIResult["last"]["w-avg"];
			windMax = windAPIResult["last"]["w-max"];
			var sector as String = Utils.orientation(windAPIResult["last"]["w-dir"]);
			var offSet = sector.length() * 5;
				
				
			dc.drawText(dc.getWidth() / 2, 50, Gfx.FONT_SMALL, windAPIResult["name"], (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
			dc.drawText(dc.getWidth() / 2, 100, Gfx.FONT_MEDIUM, windAvg.format("%.1f") + " km/h", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
			dc.drawText(dc.getWidth() / 2, 130, Gfx.FONT_GLANCE_NUMBER, windMax.format("%.1f") + " km/h (max)", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));	
			
			dc.drawText((dc.getWidth() / 2) - offSet - 12, 170, Gfx.FONT_LARGE, sector, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
			dc.drawText((dc.getWidth() / 2) + offSet + 12, 170, Gfx.FONT_GLANCE_NUMBER, windAPIResult["last"]["w-dir"] + "°", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
				
				
	}
	
		
	
}
