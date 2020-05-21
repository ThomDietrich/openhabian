﻿As an **openHABian end user**, please check out the official openHAB documentation:  
-   <https://www.openhab.org/docs/installation/openhabian.html>

# openHABian - Hassle-free openHAB Setup
[![build](https://travis-ci.org/openhab/openhabian.svg?branch=master)](https://travis-ci.com/github/openhab/openhabian)
![shellcheck](https://github.com/openhab/openhabian/workflows/shellcheck/badge.svg?branch=master)

Setting up a fully working Linux system with all needed packages and openHAB recommendations is a **boring task** taking quite some time and **Linux newcomers** shouldn't worry about these technical details.

***A home automation enthusiast doesn't have to be a Linux enthusiast!***

openHABian aims to provide a **self-configuring** Linux system setup specific to the needs of every openHAB user.
The project provides two things:

*   A set of scripts to set up openHAB on any Debian/Ubuntu based system
*   Complete **SD-card images pre-configured with openHAB** and many other openHAB- and Hardware-specific preparations, for the *Raspberry Pi* and the *Pine A64* platforms.

Closely related to openHABian is the repository [openhab-linuxpkg](https://github.com/openhab/openhab-linuxpkg) which provides linux packages for openHAB. openHABian uses those packages to setup openHAB with some additional configurations.

## Installation and Setup

Please check the [official documentation article](https://www.openhab.org/docs/installation/openhabian.html) to learn about openHABian and please visit and subscribe to our very active [community forum thread](https://community.openhab.org/t/13379).

If you want to install openHABian on non-supported hardware, you can actually fake it to make openHABian treat your box as if it was one of the supported ones. Needless to say that that may work out or not, but it's worth a try.
See [openhabian](openhabian.md) how to edit openhabian.conf before booting. Set the hw, hwarch and release parameters to match your system best.

## Development

openHABian is foremost a collection of `bash` script version handled and deployed using GIT. In the current state the scripts can only be invoked through the terminal menu system [whiptail](https://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail). There is a longterm need to better separate the UI part from the script code. A work has started to define conventions and further explain the code base in the document [CONTRIBUTING](CONTRIBUTING.md) along with development guidelines in general.

A good place to look at to start to understand the code is the file `openhabian-setup.sh`.

### Building Hardware Images
Take a look at the `build.bash` script to get an idea of the process.
Simply explained run the code below with `platform` being either `rpi` or `pine64`. The RPi image is based on the [Raspbian Lite](https://www.raspberrypi.org/downloads/raspbian) standard image while the Pine64 image is based on [build-pine64-image](https://github.com/longsleep/build-pine64-image).
```
$ sudo bash ./build.bash platform
```
As the script uses `openhab/openhabian` git repository during installation it must sometimes be changed to test code from other repositories, like a new feature in a fork. There are two commands for replacing the git repo with a custom one. The first command uses the current checked-out repository used in the filesystem:
```
$ sudo bash build.bash platform dev-git
```
The second command uses a fully customizable repository:
```
$ sudo bash build.bash platform dev-url branch url
```

### Testing
Testing is done continuously with Travis using the test framework [Bats](https://github.com/bats-core/bats-core) and the linter [Shellcheck](https://www.shellcheck.net/).  As the tests focus on installing software, a docker solution is used for easy build-up and teardown. To run the test suite execute the commands below or `"$ ./test.bash docker-full"`. Docker and Shellcheck need to be installed. For more details regarding the tests see [Test Architecture](https://github.com/openhab/openhabian/blob/master/CONTRIBUTING.md#test-architecture) in CONTRIBUTING.

```
docker build --tag openhabian/openhabian-bats .
docker run -it openhabian/openhabian-bats bash -c 'bats -r -f "unit-." .'

docker run --name "install-test" --privileged -d openhabian/openhabian-bats
docker exec -it install-test bash -c "./build.bash local-test && mv ~/.profile ~/.bash_profile && /etc/rc.local"
docker exec -it install-test bash -c 'bats -r -f "installation-." .'
docker exec -it install-test bash -c 'bats -r -f "destructive-." .'

docker stop install-test
docker rm install-test
```
Run the linter by executing:
```
shellcheck -s bash openhabian-setup.sh
shellcheck -s bash functions/*.bash
shellcheck -s bash build-image/*.bash
```


Happy Hacking!
