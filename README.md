# tegh-daemon

A daemon that detects RepRap-like 3D printer (ex. Ultimakers or anything with Marlin firmware) and serves access to them on the local network via the tegh protocol.

Features
=========

* **WiFi 3D Printer Control** - No need to tether your laptop to the 3D printer for hours anymore. Print from anywhere in the house.
* **Network Discoverablity** - All 3D printers with tegh-daemon on the network will show up automatically.
* **Queue your Print Jobs** - Add as many print jobs as you want. It's easy to manage your prints whether printing is fully or semi-autonomously. Try it out with the Makerbot ABP for extra-awesome automation!
* **Automatic Slicing** - Slicing is done by CuraEngine automatically. Just configure your printers' profiles in the `~/.tegh/cura_engine` directory and it will automatically slice any 3D models added to the queue.

**Note:** These features are based on tegh-daemon used in combination with the [tegh 3D printer client][1].

Why
====

Because I was tired of not being able to use my laptop while my 3D printer was printing. And having two printers was an even bigger problem.

How to try it out
==================

1. Install tegh-daemon on your printer's computer/raspberry pi/old laptop (see Install)
2. Install [tegh][1] on your laptop (this will allow you to remotely control your printer)
3. Open the command line and type `tegh [ENTER]`.
4. Select your printer and start 3D printing without the tether for fun and profit.


[1]: https://github.com/D1plo1d/tegh

Install
========

**Note:** tegh-daemon is currently unstable. There has not been a stable release yet so there are not packages for distros that don't support git-based unstable releases.

### Arch

`yaourt -S tegh-daemon-git`

### OSX / Non-Arch Linux Distros

1. Install an up to date copy of nodejs and npm
2. **Linux Only:** Install avahi
3. Install openssl
3. Clone and npm install
        git clone https://github.com/D1plo1d/tegh-daemon.git&& cd tegh-daemon&& npm install
4. Run the tegh-daemon install script:
        ./script/install.sh
5. Add yourself to the teghadmin group:

        sudo usermod -a -G teghadmin `whoami`
6. Add a printer config file for your printer (work in progress!):
  * Find out the serial number of your arduino
  * `cp ./defaults/printer.yml /etc/tegh/3d_printers/by_serial/[ARDUINO_SERIAL_NUMBER].yml`
  * uncomment the driver that matches your 3D printer type

7. **Linux Only (work in progress!):** If you have systemd then you can set tegh-daemon to load on startup by running  `sudo cp tegh-daemon.service /etc/systemd/system/tegh-daemon.service && sudo systemctl enable tegh-daemon.service`

**Note:** Upstart and initd are not yet supported so if you do not have systemd (for example on Ubuntu or OSX) then you won't be able to daemonize tegh-daemon. Instead your going to need to run tegh-dameon in a terminal session or screen or something. Just run `./bin/tegh-daemon` from the git repository to start the service (it will not fork).

## WebCam Setup

### Options 1: OSX / VLC

To create a mjpeg stream for your printer, first add the following lines to your printer's config file located in `/etc/tegh/3d_printers/by_serial/{PRINTER_SERIAL_NUMBER}`:
```
  camera:
    url: "$IP:1234/webcam.mjpg"
```

```
vlc qtcapture:// --sout '#transcode{vcodec=MJPG:width=1280:height=1024}:std{access=http{mime=multipart/x-mixed-replace;boundary=--7b3cc56e5f51db803f790dad720ed50a},mux=mpjpeg,dst=:1234/webcam.mjpg}' --mjpeg-fps=1
```

### Options 2: Linux / MJPG-Streamer

TODO: Docs
```

```
