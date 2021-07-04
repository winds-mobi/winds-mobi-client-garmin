import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Graphics as Gfx;

var itemMemu = ["pioupiou-384", "pioupiou-1021", "pioupiou-230"];

class windsView extends WatchUi.View {

    private var _indicator as PageIndicator;
	private var codeBalise as String;
	
	var windAPIResult = null;
	
    function initialize(codeBalise) {
        View.initialize();
        var size = 2;
        var selected = Graphics.COLOR_DK_GRAY;
        var notSelected = Graphics.COLOR_LT_GRAY;
        var alignment = $.ALIGN_TOP_RIGHT;
        var margin = 3;
        _indicator = new $.PageIndicator(size, selected, notSelected, alignment, margin);
        
	 	requestWindInformationByCode(itemMemu[codeBalise]); // "pioupiou-384"
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
	    }
	    
	    _indicator.draw(dc, 1);
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
			dc.drawText(dc.getWidth() / 2, 80, Gfx.FONT_GLANCE_NUMBER, "Alt " + windAPIResult["alt"] + " m", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));
			
					
			dc.drawText(dc.getWidth() / 2, 120, Gfx.FONT_MEDIUM, windAvg.format("%.1f") + " km/h", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
			dc.drawText(dc.getWidth() / 2, 150, Gfx.FONT_GLANCE_NUMBER, windMax.format("%.1f") + " km/h (max)", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));	
			
			dc.drawText((dc.getWidth() / 2) - offSet - 12, 190, Gfx.FONT_LARGE, sector, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
			dc.drawText((dc.getWidth() / 2) + offSet + 12, 190, Gfx.FONT_GLANCE_NUMBER, windAPIResult["last"]["w-dir"] + "°", (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER));		
				
				
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
    	    	System.print("onNextPage" + itemMemu.size());
    	
    	if(selectedItem < itemMemu.size() - 1) {
    		selectedItem = selectedItem + 1;
    		System.print("hi" + selectedItem);
    	}else{
    		selectedItem = 0;
    	}
        	System.print("onNextPage" +selectedItem);
    
        WatchUi.switchToView(new $.windsView(selectedItem), new $.WindsViewDelegate(selectedItem), WatchUi.SLIDE_LEFT);
        return true;
    }

    //! Handle going to the previous view
    //! @return true if handled, false otherwise
    public function onPreviousPage() as Boolean {
    
    	if(selectedItem > 0) {
    		selectedItem = selectedItem - 1;
    	}else{
    		selectedItem = itemMemu.size() - 1;
    	}
    	
    	
        WatchUi.switchToView(new $.windsView(selectedItem), new $.WindsViewDelegate(selectedItem), WatchUi.SLIDE_RIGHT);
        return true;
    }
	
}














