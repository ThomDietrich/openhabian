This is the new announcement page that will pop up whenever you start
`openhabian-config` and the developers have significant news they would like to
share with you.

Hit tab to unselect the buttons and scroll through the text using UP/DOWN or
PGUP/PGDN.

All announcements will be stored in /opt/openhabian/docs/NEWSLOG for you to
lookup.

## June 10, 2020

### New parameters in `openhabian.conf`
See `/etc/openhabian.conf` for a number of new parameters such as the useful
`debugmode`, a fake hardware mode, the option to disable ipv6 and the ability to
update from a custom repository other than the `master` and `stable` branches.

In case you are not aware, there is a Debug Guide in the `docs/` directory.

### New Java options
Preparing for openHAB 3, new options for the JDK that runs openHAB are now
available:

-   Java Zulu 8 32-Bit OpenJDK (default on ARM based platforms)
-   Java Zulu 8 64-Bit OpenJDK (default on x86 based platforms)
-   Java Zulu 11 32-Bit OpenJDK
-   Java Zulu 11 64-Bit OpenJDK
-   AdoptOpenJDK 11 OpenJDK (potential replacement for Zulu)

openHAB 3 will be Java 11 only.  2.5.X is supposed to work on both, Java 8 and
Java 11. Running the current openHAB 2.X on Java 11 however has not been tested
on a wide scale. Please be aware that there is a small number of known issues in
this: v1 bindings may or may not work.

Please participate in beta testing to help create a smooth transition user
experience for all of us.

See [announcement thread](https://community.openhab.org/t/Java-testdrive/99827)
on the community forum.


## May 31, 2020

### Stable branch
Introducing a new versioning scheme to openHABian. Please welcome the `stable`
branch.

Similar to openHAB where there's releases and snapshots, you will from now on be
using the stable branch. It's the equivalent of an openHAB release. We will keep
providing new changes to the master branch first as soon as we make them
available, just like we have been doing in the past. If you want to keep living
on the edge, want to make use of new features fast or volunteer to help a little
in advancing openHABian, you can choose to switch back to the master branch.
Anybody else will benefit from less frequent but well better tested updates to
happen to the stable branch in batches, whenever the poor daring people to use
`master` have reported their trust in these changes to work flawlessly.

You can switch branches at any time using the menu option 01.

### ZRAM per default
Swap, logs and persistence files are now put into ZRAM per default.
See [ZRAM status thread](https://community.openhab.org/t/zram-status/80996) for
more information.

### Supported hardware and Operating Systems
openHABian now fully supports all Raspberry Pi SBCs with our fast-start image.
As an add-on package, it is supposed to run on all Debian based OSs.

Check the [README](README.md) to see what "supported" actually means and what
you can do if you want to run on other HW or OS.
