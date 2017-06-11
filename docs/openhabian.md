---
layout: documentation
title: openHABian
---

{% include base.html %}

<!-- Attention authors: If you want to improve or enhance this article, please go to: -->
<!--   * https://github.com/openhab/openhabian/issues -->
<!--   * https://github.com/openhab/openhabian/blob/master/docs/openhabian.md -->

# openHABian - Hassle-free openHAB Setup

The Raspberry Pi and other small single-board computers are quite famous platforms for openHAB.
However, setting up a fully working Linux system with all recommended packages and openHAB recommendations is a **boring task** taking quite some time and **Linux newcomers** shouldn't worry about these technical details.

<p style="text-align: center; font-size: 1.2em; font-style: italic;"><q>A home automation enthusiast doesn't have to be a Linux enthusiast!</q></p>

openHABian aims to provide a **self-configuring** Linux system setup specific to the needs of every openHAB user.
To that end, the project provides two things:

* Complete **SD-card images pre-configured with openHAB** and many other openHAB- and Hardware-specific preparations for the Raspberry Pi and the Pine A64
* The openHABian Configuration Tool to set up and configure openHAB and many related things on any Debian/Ubuntu based system

#### Table of Content

{::options toc_levels="2..3"/}

* TOC
{:toc}

## Features

The following features are provided by the openHABian images out of the box:

* Hassle-free setup without the need for a display or an [ethernet connection]()
* openHAB 2 in the latest recommended version (2.0.0 stable)
* Zulu Embedded OpenJDK Java 8 ([*version 8.20.0.42* or newer](http://zulu.org/zulu-community/zulurelnotes))
* Useful Linux packages pre-installed, including `vim, mc, screen, htop, ...`
* Samba file sharing with [pre-configured to use shares](http://docs.openhab.org/installation/linux.html#mounting-locally)
* Customized Bash shell experience
* Customized vim settings, including [openHAB syntax highlighting](https://github.com/cyberkov/openhab-vim)
* Customized nano settings, including [openHAB syntax highlighting](https://github.com/airix1/openhabnano)
* Version control for `/etc` by the help of [etckeeper](http://etckeeper.branchable.com) (git)
* Login information screen, powered by [FireMotD](https://github.com/willemdh/FireMotD)
* openHABian Configuration Tool including updater functionality
* [Raspberry Pi specific](rasppi.html): Extend to the whole SD card, 16MB GPU memory split

openHABian provides the Configuration Tool [`openhabian-config`](#first-steps) with the following optional settings and components:

![openHABian-config menu](images/openHABian-config.png)

* Switch over to the *unstable* openHAB 2.1 [build branch](http://docs.openhab.org/installation/linux.html#changing-versions)
* Switch to Oracle Java 8 ([*build 1.8.0_101* or newer](https://launchpad.net/~webupd8team/+archive/ubuntu/java?field.series_filter=xenial))
* Install and Setup a [reverse proxy](security.html#nginx-reverse-proxy) with password authentication and/or HTTPS access (incl. [Let's Encrypt](https://letsencrypt.org) certificate) for self-controlled remote access
* Set up a Wi-Fi connection
* Bind the [Karaf remote console]({{base}}/administration/console.html) to all interfaces
* Easily install and preconfigure [Optional components](#optional-components) of your choice
* ... and many more
* Raspberry Pi specific:
  * Prepare the serial port for the use with extension boards like Razberry, SCC, Enocean Pi, ...
  * Move the system partition to an external USB stick or drive

## Quick Start

Here you'll find supported and tested installation platforms and instructions.

### Raspberry Pi

**Flash, plug, wait, enjoy:**
The provided *image* is based on the [Raspbian Lite](https://www.raspberrypi.org/downloads/raspbian) system.
On first boot the system will set up openHAB and the mentioned settings and tools.
All packages will be downloaded in their newest version and configured to work without further modifications.
The whole process will take a few minutes, then openHAB and all other needed tools to get started will be ready to use without further configuration steps.
openHABian is designed as a headless system, you will not need a display or a keyboard.

Learn more about the Raspberry Pi as your platform for openHAB and about the requirements over in our [Raspberry Pi article](rasppi.html).

**Setup:**

* [Download the latest "openHABianPi" SD card image file](https://github.com/openhab/openhabian/releases) (Note: the file is *xz* compressed)
* Write the image to your SD card (e.g. with [Etcher](https://etcher.io), able to directly work with *xz* files)
* Insert the SD card into the Raspberry Pi, connect Ethernet ([Wi-Fi supported](#wifi-setup)) and power
* Wait approximately **15-30 minutes** for openHABian to do its magic
* Enjoy! 🎉

* The device will be available under its IP or via the local DNS name `openhabianpi`
* [Connect to the openHAB 2 dashboard](http://docs.openhab.org/configuration/packages.html) (available after a few more minutes): [http://openhabianpi:8080](http://openhabianpi:8080)
* [Connect to the Samba network shares](http://docs.openhab.org/installation/linux.html#mounting-locally) with username and password `openhabian`
* If you encounter any setup problem, [please continue here](#faq-successful)

You can stop reading now.
openHABian has installed and configured your openHAB system and you can start to use it right away.
If you want to get in touch with the system or want to install one of the previously mentioned optional features, you can come back here later.

Ready for more?
[Connect to your Raspberry Pi SSH console](https://www.raspberrypi.org/documentation/remote-access/ssh/windows.md) using the username and password `openhabian`.
You will see the following welcome screen:

![openHABian login screen](images/openHABian-SSH-MotD.png)

➜ Continue at the ["First Steps"](#first-steps) chapter below!

### Pine A64

We provide a ready to use system image for the Pine A64.
The image is based on the official [Ubuntu Base Image by longsleep](http://wiki.pine64.org/index.php/Pine_A64_Software_Release), which comes as a compressed 4GB file.
After boot-up the latest version of openHAB 2 and the featured settings and tools are installed.
All packages are downloaded in their newest version and configured to work without further modifications.

Learn more about the Pine A64 as your platform for openHAB and about the requirements in our [Pine A64 article](pine.html).

**Setup:**

* [Download the latest "openHABianPine64" SD card image file](https://github.com/openhab/openhabian/releases) (Note: the file is *xz* compressed)
* Write the image file to your SD card (e.g. with [Etcher](https://etcher.io), able to directly work with *xz* files)
* Insert the SD card into the Pine A64, connect Ethernet ([Wi-Fi supported](#wifi-setup)) and power ([See here for more details](http://wiki.pine64.org/index.php/Main_Page#Step_by_Step_Instructions))
* Wait approximately **15-30 minutes** for openHABian to do its magic
* Enjoy! 🎉

* The device will be available under its IP or via the local DNS name `openhabianpine64`
* [Connect to the openHAB 2 dashboard](http://docs.openhab.org/configuration/packages.html) (available after a few more minutes): [http://openhabianpine64:8080](http://openhabianpine64:8080)
* [Connect to the Samba network shares](http://docs.openhab.org/installation/linux.html#mounting-locally) with username and password `openhabian`
* If you encounter any setup problem, [please continue here](#faq-successful)

You can stop reading now.
openHABian has installed and configured your openHAB system and you can start to use it right away.
If you want to get in touch with the system or want to install one of the previously mentioned optional features, you can come back here later.

Ready for more?
Connect to your Pine A64 [SSH console](https://www.raspberrypi.org/documentation/remote-access/ssh/windows.md) using the username and password `openhabian`.
You will see the following welcome screen:

![openHABian login screen](images/openHABian-SSH-MotD.png)

➜ Continue at the ["First Steps"](#first-steps) section below!

### Manual Setup

openHABian also supports general Debian/Ubuntu based systems on different platforms.
Starting with a fresh installation of your operating system, install git, then clone the openHABian poject and finally execute the openHABian configuration tool:

```shell
# install git
sudo apt-get update
sudo apt-get install git

# download and link
sudo git clone https://github.com/openhab/openhabian.git /opt/openhabian
ln -s /opt/openhabian/openhabian-setup.sh /usr/local/bin/openhabian-config

# execute
sudo openhabian-config
```

You'll see the openHABian configuration menu and can now select all desired actions.
The "Manual/Fresh Setup" submenu entry is the right place for you. Execute all entries one after the other to get the full openHABian experience:

![openHABian-config menu fresh setup](images/openHABian-menu-freshsetup.png)

> Attention:
> openHABian usage on a custom system is supported and should be safe.
> Still some routines might not work for you.
> Please be cautious and have a close look at the console output for errors.
> Report problems you encounter to the [openHABian Issue Tracker](https://github.com/openhab/openhabian/issues).

{: #wifi-setup}
### Wi-Fi based Setup Notes

If you own a RPi3, RPi0W or a Pine A64, you can setup and use openHABian purely via Wi-Fi.
For the setup on Wi-Fi, you'll need to make your SSID and password known to the system before the first boot.
Additionally to the setup instructions given above, the following steps are needed:

* Flash the system image to your micro SD card as described
* Access the first SD card partition from your file explorer
* Open the file `openhabian.conf` in a text editor
* Uncomment and fill in `wifi_ssid=` and `wifi_psk=`
* Save, Unmount, Insert, Boot
* Continue with the instructions for the Raspberry Pi or Pine A64

## First Steps

The following instructions are oriented at the Raspberry Pi openHABian setup but are transferable to all openHABian environments.

Once connected to the command line console of your system, please execute the openHABian configuration tool by typing the command `sudo openhabian-config`:

![openHABian-config menu](images/openHABian-config.png)

The configuration tool is the heart of openHABian.
It is not only a menu with a set of options, it's also used in a special unattended mode inside the ready to use images.

Execute the "Update" function before anything else. The menu and the menu options will evolve over time and you should ensure to be up to date.

All other menu entries should be self-explaining and more details are shown after selecting an option.

ℹ - The actions behind menu entry 1-5 are already taken care of on a Raspberry Pi openHABian image installation.

⌨ - A quick note on menu navigation.
Use the cursor keys to navigate, &lt;Enter&gt; to execute, &lt;Space&gt; to select and &lt;Tab&gt; to jump to the actions on the bottom of the screen. Press &lt;Esc&gt; twice to exit the configuration tool.

### Linux Hints

If you are unfamiliar with Linux, SSH and the Linux console or if you want to improve your skills, read up on these important topics.
A lot of helpful articles can be found on the internet, for example:

* "Learn the ways of Linux-fu, for free" interactively with exercises at [linuxjourney.com](https://linuxjourney.com).
* The official Raspberry Pi help articles over at [raspberrypi.org](https://www.raspberrypi.org/help)
* "Now what?", Tutorial on the Command line console at [LinuxCommand.org](http://linuxcommand.org/index.php)

*The good news:* openHABian helps you to stay away from Linux - *The bad news:* Not for long...

Regardless of if you want to copy some files or are on the search for a solution to a problem, sooner or later you'll have to know some Linux.
Take a few minutes to study the above Tutorials and get to know the most basic commands and tools to be able to navigate on your Linux system, edit configurations, check the system state or look at log files.
It's not complicated and something that doesn't hurt on ones résumé.

{: #further-config}
### Further Configuration Steps

openHABian is supposed to provide a ready-to-use openHAB base system. There are however a few things we can not decide for you.

* **Timezone:** The default timezone openHABian is shipped with is "Europe/Berlin". You should change it to your location.
* **Language:** The `locale` setting of the openHABian base system is set to "en_US.UTF-8". While this setting will not do any harm, you might prefer e.g. console errors in German or Spanish. Change the locale settings accordingly. Be aware, that error solving might be easier when using the English error messages as search phrases.
* **Passwords:** Relying on default passwords is a security concern you should care about!

All of these settings can be changed via the openHABian Configuration Tool.

The openHABian system is preconfigured with a few passwords you should change to ensure the security of your system.
This is especially important of your system is accessible from outside your private subnet.

Here are the passwords in question, their default value and the way to change them:

{: #passwords}
* User password needed for SSH or sudo (e.g. "openhabian:openhabian") : `passwd`
* Samba share password (e.g. "openhabian:openhabian"): `sudo smbpasswd openhabian`
* Karaf remote console (e.g. "openhab:habopen"): Change via the openHABian menu
* Nginx reverse proxy login (no default): Change via the openHABian menu, please see [here](http://docs.openhab.org/installation/security.html#adding-or-removing-users) for more

## Optional Components

openHABian comes with a number of additional configs that allow you to quickly install home automation related software.

* [frontail](https://github.com/mthenw/frontail) - openHAB Log Viewer accessible from [http://openHABianPi:9001/](http://openHABianPi:9001/)
* [Node-RED](https://nodered.org/) - Flow-based programming for the Internet of Things with preinstalled [openHAB2](https://flows.nodered.org/node/node-red-contrib-openhab2) and [BigTimer](https://flows.nodered.org/node/node-red-contrib-bigtimer) addons. Accessible from [http://openHABianPi:1880/](http://openHABianPi:1880/)
* [KNXd](http://michlstechblog.info/blog/raspberry-pi-eibknx-ip-gateway-and-router-with-knxd) - KNX daemon running at `224.0.23.12:3671/UDP`
* [Homegear](https://www.homegear.eu/index.php/Main_Page) - Homematic control unit emulation
* [Eclipse Mosquitto](http://mosquitto.org) - Open Source MQTT v3.1/v3.1.1 Broker
* [OWServer](http://owfs.org/index.php?page=owserver_protocol) - 1wire control system
* [Grafana](https://community.openhab.org/t/influxdb-grafana-persistence-and-graphing/13761/1) - persistence and graphing available from [http://openHABianPi:3000/](http://openHABianPi:3000/)

## FAQ and Troubleshooting

For openHABian related questions and further details, please have a look at the main discussion thread in the Community Forum:

* [https://community.openhab.org/t/13379](https://community.openhab.org/t/13379)

If you want to get involved, you found a bug, or just want to see what's planned for the future, come visit our Issue Tracker:

* [https://github.com/openhab/openhabian/issues](https://github.com/openhab/openhabian/issues)

{: #changelog}
#### Where can I find a changelog for openHABian?

The official changelog announcements are posted [here](https://community.openhab.org/t/13379/1) and [here](https://github.com/openhab/openhabian/releases), be sure to check these out regularly.
If you want to stay in touch with all the latest code changes under the hood, see the [commit history](https://github.com/openhab/openhabian/commits/master) for openHABian.
You'll also see added commits when executing the "Update" function within the openHABian Configuration Tool.

{: #faq-successful}
#### Did my Installation succeed? What to do in case of a problem?

During and after the first boot of your Raspberry Pi, the green on-board LED will indicate the setup progress (no display needed):

* `❇️️ ❇️️    ❇️️ ❇️️     ` - Steady "heartbeat": setup **successful**
* ` ❇️️         ❇️️❇️️❇️️ ` - Irregular blinking: setup in progress...
* `❇️️ ❇️️ ❇️️ ❇️️ ❇️️ ❇️️ ❇️️` - Fast blinking: error while setup

Besides, you should always be able to connect to the SSH console of your device.
During the setup process you'll be redirected to the live progress report of the setup.
The report can also be checked for errors after the installation, execute: `cat /boot/first-boot.log`

The progress of a successful installation will look similar to the following:

![openHABian installation log](images/openHABian-install-log.png)

If the installation was successful, you will see the normal login screen afterwards.
If the installation was *not* successful you will see a warning and further instructions:

<div class="row">
  <div class="col s12 m5"><img src="images/openHABian-SSH-MotD.png" alt="openHABian installation successful" title="openHABian installation successful"></div>
  <div class="col s12 m5"><img src="images/openHABian-install-failed.png" alt="openHABian installation failed warning and instructions" title="openHABian installation failed warning and instructions"></div>
</div>

If you are not able to SSH access your system after more than one hours, chances are high that your hardware setup is the problem.
Try using a steady power source and a reliable SD card.
Check the network connection.
Restart the Setup process to rule out most other possible causes.

Contact the [Community Forum thread](https://community.openhab.org/t/13379) if the problem persists.

{: #switch-openhab-branch}
#### Can I switch from openHAB 2 stable to the testing or unstable branch?

openHABian installs the latest stable build of openHAB 2.
If you want to switch over to the snapshot release branch, please do so via the openHABian Configuration Tool.
Switching from stable to newer development releases might introduce changes and incompatibilities, so please be sure to make a full openHAB backup first!

Check the Linux installation article for all needed details: [Linux: Changing Versions](http://docs.openhab.org/installation/linux.html#changing-versions)

{: #faq-other-platforms}
#### Can I use openHABian on ...?

openHABian is restricted to Debian/Ubuntu based systems.
If your operating system is based on these or if your Hardware supports one, your chances are high openHABian can be used.
Check out the [Manual Setup](#manual-setup) instructions for guidance.

Differences between systems can still be a problem, so please check the [Community Forum thread](https://community.openhab.org/t/13379) or the [Issue Tracker](https://github.com/openhab/openhabian/issues) for more information.
Do not hesitate to ask!
