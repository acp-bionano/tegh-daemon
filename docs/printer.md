###Contents###
1. [Summary](#summary)
2. [Documentation](#docs)
    - [new Printer(driver, config, \[Part\])](#new)
    - [Printer.add(attrs)](#add)
    - [Printer.rm(key)](#rm)
    - [Printer.estop()](#estop)
    - [Printer.set(diff)](#set)
    - [Printer.print()](#print)
    - [Printer.retryPrint()](#retryPrint)
    - [Printer.move(axesVals)](#move)
    - [Printer.home(axes)](#home)
3. [Examples](#examples)
    - [Instantiate a Development "Null Printer"](#devnull)
    - [Instantiate a Makerbot "Thing-O-Matic" Printer](#instantiate)

###Summary###{#summary}

A software representation of a 3D printer via its attributes and functions.

Link: [printer.coffee](https://github.com/acp-bionano/tegh-daemon/blob/tegh-daemon/lib/printer.coffee)

***

###Docs for Class: Printer###{#docs}

####new Printer (driver, config, \[Part\])#####{#new}
* `driver` Object
* `config` Object
* `Part` Object, Optional

Instantiates a new Printer which binds events belonging to a particular [driver](http://acp-instiki.herokuapp.com/wiki/show/driver.coffee) and [config](http://acp-instiki.herokuapp.com/wiki/show/config.coffee). Optionally instantiates and initial printable Part.

####Printer.add(attrs)####{#add}
* `attrs` Object - printer attributes (see  [tegh component spec](http://tegh.io/#components-reference))
* Return: [Part](http://acp-instiki.herokuapp.com/wiki/show/part.coffee) or [Assembly](http://acp-instiki.herokuapp.com/wiki/show/assembly.coffee)

Adds a Part or Assembly to-be-printed to the Printer, populated with attributes like a quantity or file path.

####Printer.rm(key)####{#rm}
* `key` String

Removes a Part or Assembly

####Printer.estop()####{#estop}

Resets all Printer components, ceasing printing and movement.

####Printer.set(diff)####{#set}
* `diff` Object - a key/value store of printer components. Only differences between currently set values need be included. (i.e:  diff: {e0} where e0: {targetTemp: 100}).


####Printer.print()####{#print}

Attempts to prints the first idle Part (i.e. not estopped) in the print queue.

####Printer.retryPrint()####{#retryPrint}

Attempts to print the first estopped Part in the print queue.

####Printer.move(axesVals)####{#move}
* `diff` Object - an object of axis key/values (i.e. x:10).

####Printer.home(axes)####{#home}
* `axes` Array - typically ['x', 'y', 'z']

***

###Examples###{#examples}

####Instantiate a Development "Null Printer"####{#devnull}

~~~
require("/Users/acp/tegh-daemon/lib/config.coffee")
require("/Users/acp/tegh-daemon/lib/printer.coffee")
require("/Users/acp/tegh-daemon/lib/drivers/factory.coffee")

port:
  serialNumber: "dev_null"
  comName: "dev/null"

args:
  driver: {verbose: true, type: null}


nullConfig = new Config(port, args)
driver = factory.build(nullConfig)

nullPrinter = new Printer(driver, nullConfig)

~~~

####Instantiate a Makerbot "Thing-O-Matic" Printer####{#instantiate}

If the Makerbot's serial number is known (see [here](http://acp-instiki.herokuapp.com/wiki/show/Serial+Communication#implementation)), and it's Config is defined (see [here](http://acp-instiki.herokuapp.com/wiki/show/config.coffee#makerbot), then instantiation follows analogously to the following:

~~~
require("/Users/acp/tegh-daemon/lib/config.coffee")
require("/Users/acp/tegh-daemon/lib/printer.coffee")
require("/Users/acp/tegh-daemon/lib/drivers/factory.coffee")
port:
  serialNumber: "/dev/cu.usbmodem1411"
  comName: "64935343133351209231"

args:
  driver:
    verbose: true
    type: "s3g"
    baudrate: 115200
    eeprom: "sailfish"
    fork: false
    axes:
      x:
        maxfeedrate: 160
        steps_per_mm: 5.8837315
        microstepping: 8
      y:
        maxfeedrate: 160
        steps_per_mm: 5.8837315
        microstepping: 8
      z:
        maxfeedrate: 16.6666667
        steps_per_mm: 25
        microstepping: 8
      a:
        maxfeedrate: 26.6666667
        steps_per_mm: 50.235478806907409
        microstepping: 4
      b:
        maxfeedrate: 26.6666667
        steps_per_mm: 50.235478806907409
        microstepping: 4

makerbotConfig = new Config(port, args)
driver = factory.build(makerbotConfig)

makerbot = new Printer(driver, makerbotConfig)

~~~