import Toybox.Application;
import Toybox.Background;
import Toybox.System;
import Toybox.Time;

// Your service delegate has to be marked as background
// so it can handle your service callbacks
(:background)
class WindsSpeedDelegate extends System.ServiceDelegate {


    (:background)
    public function initialize() {
        System.ServiceDelegate.initialize();
    }
    
    (:background)
    public function onTemporalEvent() as Void {
        // Do fun stuff here
        System.println("onTemporalEvent");

        var app = Application.getApp();
        // First non-empty beacon, matching the widget's first page
        // (WindsController builds itemMemu the same way). Using balise_1 in a
        // hard-coded way showed nothing in the glance when it was left empty.
        var balise = null;
        for(var i = 1; i <= 8; i++) {
            var b = app.getProperty("balise_" + i);
            if(b != null && !b.equals("")) {
                balise = b;
                break;
            }
        }
        if(balise != null){
            requestWindInformationByCode(balise);
        }
    }

    (:background)
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

    function setStationInfo(responseCode, data) {
		Background.exit(data);		
	}









}