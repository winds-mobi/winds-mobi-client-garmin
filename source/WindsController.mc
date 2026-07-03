import Toybox.Lang;
using Toybox.Application;
using Toybox.Communications;
using Toybox.WatchUi;
using Toybox.Position;

// Global controller instance, created by windsApp.getInitialView().
var ctrl = null;

// Kept as globals for backward compatibility / cross-view access.
var itemMemu = [];
var nearestStationsFound as Boolean = false;

//! Holds the shared state of the widget:
//!  - the list of beacon codes (from settings + GPS)
//!  - the currently selected beacon and its data (fetched once, shared by every page)
//!  - the current page and the navigation helpers
class WindsController {

	// Data for the selected beacon, shared by all the pages.
	var info = null;   // GET /stations/{code}
	var hist = null;   // GET /stations/{code}/historic/?duration=3600

	var selectedBalise as Number = 0;   // index in itemMemu
	var currentPage as Number = 0;      // 0 data, 1 history, 2 compass, 3 stats

	const PAGE_COUNT = 4;

	function initialize() {
		itemMemu = [];
		nearestStationsFound = false;
		selectedBalise = 0;
		currentPage = 0;

		var app = Application.getApp();

		// Natural order: balise_1 first (the one shown in the glance / background).
		for(var i = 1; i <= 8; i++) {
			var balise = app.getProperty("balise_" + i);
			if(balise != null && !balise.equals("")) {
				itemMemu.add(balise);
			}
		}

		if(itemMemu.size() > 0) {
			load(itemMemu[0]);
		}

		if(app.getProperty("enable_gps") == true && !nearestStationsFound) {
			Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onPosition));
		}
	}

	// ---- Data fetching (shared by every page) -------------------------------

	function load(code) {
		info = null;
		hist = null;

		Communications.makeWebRequest(
			Utils.WINDS_API_ENDPOINT + "/stations/" + code,
			null,
			{
				:method => Communications.HTTP_REQUEST_METHOD_GET,
				:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
			},
			method(:onInfo)
		);

		Communications.makeWebRequest(
			Utils.WINDS_API_ENDPOINT + "/stations/" + code + "/historic/",
			{ "duration" => 3600 },
			{
				:method => Communications.HTTP_REQUEST_METHOD_GET,
				:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
			},
			method(:onHist)
		);
	}

	// Keep the payload even on error: the API returns { "detail": ... } that the
	// data page displays as-is.
	function onInfo(responseCode, data) {
		if(data != null) {
			info = data;
		}
		WatchUi.requestUpdate();
	}

	function onHist(responseCode, data) {
		hist = data;
		WatchUi.requestUpdate();
	}

	function onPosition(posInfo) {
		var loc = posInfo.position.toDegrees();
		var app = Application.getApp();
		var distance = app.getProperty("gps_distance");
		if(distance == null || distance == 0) {
			distance = 1;
		}
		Communications.makeWebRequest(
			Utils.WINDS_API_ENDPOINT + "/stations/",
			{
				"near-lat" => loc[0],
				"near-lon" => loc[1],
				"near-distance" => distance * 1000
			},
			{
				:method => Communications.HTTP_REQUEST_METHOD_GET,
				:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
			},
			method(:onNearest)
		);
	}

	function onNearest(responseCode, data) {
		if(data != null && data instanceof Lang.Array) {
			for(var i = 0; i < data.size(); i++) {
				itemMemu.add(data[i]["_id"]);
			}
		}
		nearestStationsFound = true;
		WatchUi.requestUpdate();
	}

	// ---- Derived data -------------------------------------------------------

	function hasData() as Boolean {
		return info != null && info["last"] != null;
	}

	// Wind trend over the last hour, in km/h (null if not enough samples).
	// hist[0] is the most recent sample, hist[last] the oldest (~1 h ago).
	function trend() {
		if(hist == null || !(hist instanceof Lang.Array) || hist.size() < 2) {
			return null;
		}
		var last = hist[0]["w-avg"];
		var oneHour = hist[hist.size() - 1]["w-avg"];
		if(last == null || oneHour == null) {
			return null;
		}
		return last - oneHour;
	}

	// ---- Navigation ---------------------------------------------------------

	function buildView() {
		if(currentPage == 0)      { return new DataView(); }
		else if(currentPage == 1) { return new HistoryView(); }
		else if(currentPage == 2) { return new CompassView(); }
		else                      { return new StatsView(); }
	}

	function nextPage() {
		currentPage = (currentPage + 1) % PAGE_COUNT;
		return buildView();
	}

	function prevPage() {
		currentPage = (currentPage + PAGE_COUNT - 1) % PAGE_COUNT;
		return buildView();
	}

	function selectBalise(idx) {
		if(idx >= 0 && idx < itemMemu.size()) {
			selectedBalise = idx;
			currentPage = 0;
			load(itemMemu[idx]);
		}
		return buildView();
	}
}


//! Paging delegate shared by every page.
//!  - up / down (or swipe) cycles through the pages of the selected beacon
//!  - the select / menu button opens the beacon picker
class WindsPagerDelegate extends WatchUi.BehaviorDelegate {

	function initialize() {
		BehaviorDelegate.initialize();
	}

	function onNextPage() as Boolean {
		WatchUi.switchToView($.ctrl.nextPage(), self, WatchUi.SLIDE_UP);
		return true;
	}

	function onPreviousPage() as Boolean {
		WatchUi.switchToView($.ctrl.prevPage(), self, WatchUi.SLIDE_DOWN);
		return true;
	}

	function onMenu() as Boolean {
		return openMenu();
	}

	// Touch tap / start button.
	function onSelect() as Boolean {
		return openMenu();
	}

	function openMenu() as Boolean {
		if($.itemMemu.size() == 0) {
			return false;
		}
		if(WatchUi has :Menu2) {
			var menu = new WatchUi.Menu2({ :title => "Balises" });
			for(var i = 0; i < $.itemMemu.size(); i++) {
				menu.addItem(new WatchUi.MenuItem($.itemMemu[i], null, i, null));
			}
			WatchUi.pushView(menu, new BaliseMenuDelegate(), WatchUi.SLIDE_UP);
		} else {
			// Fallback for devices without Menu2: cycle to the next beacon.
			var next = ($.ctrl.selectedBalise + 1) % $.itemMemu.size();
			WatchUi.switchToView($.ctrl.selectBalise(next), self, WatchUi.SLIDE_LEFT);
		}
		return true;
	}
}


//! Handles the beacon selection in the Menu2 picker.
class BaliseMenuDelegate extends WatchUi.Menu2InputDelegate {

	function initialize() {
		Menu2InputDelegate.initialize();
	}

	function onSelect(item) {
		// switchToView replaces the menu with the freshly loaded data page.
		WatchUi.switchToView($.ctrl.selectBalise(item.getId()), new WindsPagerDelegate(), WatchUi.SLIDE_LEFT);
	}
}
