Hit tab to unselect buttons and scroll through the text using UP/DOWN or PGUP/PGDN.
All announcements are stored in `/opt/openhabian/docs/NEWSLOG.md` for you to lookup.

## openHAB 3 released ## December 21, 2020
In the darkest of times (midwinter for most of us), openHAB 3 gets released.
See [documentation](docs/openhabian.md#on-openhab3) and [www.openhab.org](http://www.openhab.org) for details.

Merry Christmas and a healthy New Year !


## WiFi Hotspot ## November 14, 2020
Whenever your system has a WiFi interface that fails to initialize on installation or startup,
openHABian will now launch a [WiFi hotspot](docs/openhabian.md#WiFi-Hotspot) you can use to connect your system to an existing WiFi network.


## Tailscale VPN network ## October 6, 2020
Tailscale is a management toolset to establish a WireGuard based VPN between multiple systems
if you want to connect to openHAB(ian) instances outside your LAN over Internet.
It'll take care to detect and open ports when you and your peers are located behind firewalls.
This makes use of the tailscale service. Don't worry, for private use it's free of charge.


## Auto-backup ## August 29, 2020
openHABian can automatically take daily syncs of your internal SD card to another card in an external port.
This allows for fast swapping of cards to reduce impact of a failed SD card.
The remaining space on the external device will be made use of for openHABian's Amanda backup system.
