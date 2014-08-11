###Contents###
1. [Summary](#summary)
2. [Documentation](#docs)
    - [new Config (port, arg)](#new)
    - [Config.kill()](#kill)

3. [Examples](#examples)
    - [Set up a Config for a "null" development Printer](#null)
    - [Set up a Config for a Makerbot "Thing-O-Matic" Printer](#makerbot)

###Summary###{#summary}

A Config is used as an argument when initializing a new Printer. It is a container for:

* Communication references such as a serial port number.
* Printer properties such as print qualities, components, and drivers.

Suggested usage: Config arguments for a particular Printer should be written to a file such that a Config can be automatically initialized on a connection. See [[config file]].

Link: [config.coffee](https://github.com/acp-bionano/tegh-daemon/blob/tegh-daemon/lib/config.coffee)

***

###Docs for Class: Config###{#docs}

####new Config (port, arg)#####{#new}

* `port` Object - a serial port reference
* `arg` Object - a set of Printer properties to be initialized

A Printer will be initialized with the following components unless `args` specifies otherwise:

~~~
driver:
    type: "serial_gcode"
    baudrate: 115200}

components:
    e0: 'heater'
    b: 'heater'
    c: 'conveyor'
    f: 'fan'

printQualities:
      engine: "cura_engine"
      profile: "default"
      params: {layer_height: 5, infill: 20}
~~~

####Config.kill()#####{#kill}

Removes listeners associated with the Config.

***

###Examples###{#examples}


####Set up a Config for a "null" development Printer####{#null}

To initialize a null Printer for development purposes:

~~~
Config = require("./lib/config.coffee")

port = {serialNumber: "dev_null", comName: "dev/null"}
args = driver: {verbose: true, type: null},

nullConfig = new Config(port, args)
~~~

####Set up a Config for a Makerbot "Thing-O-Matic" Printer####{#makerbot}

If the Makerbot's serial number is known (see [here](http://acp-instiki.herokuapp.com/wiki/show/Serial+Communication#implementation)), setting up its Config is very straightforward.

~~~
port =
  serialNumber: "/dev/cu.usbmodem1411",
  comName: "64935343133351209231"

args =
  driver:
    verbose: true
    type: s3g
    baudrate: 115200
    eeprom: sailfish
    fork: false
    axes:
      x: { maxfeedrate: 160, steps_per_mm: 5.8837315, microstepping: 8 }
      y: { maxfeedrate: 160, steps_per_mm: 5.8837315, microstepping: 8 }
      z: { maxfeedrate: 16.6666667, steps_per_mm: 25, microstepping: 8 }
      a: { maxfeedrate: 26.6666667, steps_per_mm: 50.235478806907409, microstepping: 4 }
      b: { maxfeedrate: 26.6666667, steps_per_mm: 50.235478806907409, microstepping: 4 }

new Config (port, args)
~~~

The driver metadata specified by `args` will be merged in with the defaults discussed in the previous section.