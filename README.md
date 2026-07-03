# Windx
Real-time weather observations: Garmin client

## Screenshot

![screenshot](https://github.com/sreynier-occ/garmin-winds/blob/master/doc/Capture.PNG)


# Installation

To manually install Windx in your device, do the following:

* Connect your device to a computer using a USB cable, the device should appear as a new drive (e.g. D:\ on Windows)
* Download the app binary from your device from the latest [Releases](https://github.com/sreynier-occ/garmin-winds/releases)

* Select the binary for your device type and rename it to Windx.prg
* Copy the app binary to the D:\GARMIN\APPS directory of your device (adjust drive letter as needed)
* Eject the drive, don't just unplug the device

The app should appear in the list of Connect IQ apps or activities menu. If you can't find your device in the releases, you can either compile it yourself using the Garmin IQ SDK or submit an issue.

# Navigation

* **Up / Down (or swipe)**: switch between the pages of the selected beacon — Data, History chart, Compass, 1-hour Stats.
* **Select / Menu button (or tap)**: open the beacon picker to choose a station.

# Features

* Real-time data page (Avg / Max / Δ 1h / direction / freshness).
* History chart of average wind and gusts over the last hour.
* Compass rose pointing to the wind origin.
* 1-hour statistics: min / max / average / strongest gust.
* Gust factor (peak gust / mean wind), colour-coded by turbulence — a direction-independent measure of air roughness.

# To Do

Manage your favorite weather station.

Orient the compass on the take-off direction (front / cross / tail wind).
