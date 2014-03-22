requireRelative = (args...) ->
  args.unshift __dirname
  require path.join.apply null, args
# 3rd Party Libraries
https = require "https"
express = require "express"
fs = require "fs-extra"
path = require "flavored-path"
pamAuth = require "express-pam"
_ = require 'lodash'
require "js-yaml"
# Source Libraries
SlicingFactory        = requireRelative "slicing_engines", "factory"
ArudinoDiscoverer     = requireRelative "arduino_discoverer"
DriverFactory         = requireRelative "drivers", "factory"
Printer               = requireRelative "printer"
PrinterServer         = requireRelative "printer_server"
Config                = requireRelative "config"

APP_NAME = 'tegh'

module.exports = class App
  constructor: (options, cb) ->
    @silent = options.silent
    @printerServers = {}
    # Loading Config
    globalConfig = require("../defaults/_tegh.yml")
    globalConfig = _.merge globalConfig, require("/etc/tegh/tegh.yml")
    @enableAuth = globalConfig.enable_auth
    # HTTPS Server
    opts = pfx: fs.readFileSync('/etc/tegh/cert.pfx')
    @app = express()
    @server = https.createServer(opts, @app).listen(2540)
    @server.on "listening", cb if cb
    # CORS
    @app.all '*', (req, res, next) ->
      res.header("Access-Control-Allow-Origin", "*")
      res.header("Access-Control-Allow-Headers", "X-Requested-With")
      next()
    # Authentication
    @app.use pamAuth(undefined, 'tegh') if @enableAuth
    # Base Routes (ie. routes not specific to individual printers)
    @app.get '/printers.json', @getPrintersJson
    # Displaying Init Message
    @log "Tegh Daemon started on https://localhost:2540"
    # Adding printers
    if options['dry-run'] == true
        @addDryRunPrinter()
    else
        ArudinoDiscoverer.listen().on "update", @_onSerialPortsUpdate

  log: (msg) =>
    console.log msg unless @silent

  getPrintersJson: (req, res) =>
    res.send printers: Object.map @printerServers, (k, p) -> p.slug

  _onSerialPortsUpdate: (ports) =>
    newPorts = ports.filter (p) => !(@printerServers[p.comName]?)
    @addPrinter port for port in newPorts

  _initConfig: (port) ->
    # loading the config file (or creating a new one)
    dir = path.get "/etc/tegh/3d_printers/by_serial/"
    configPath = path.join dir, "#{port.serialNumber}.yml"
    # initializing the config object
    return new Config port, configPath

  addPrinter: (port, config) =>
    config ?= @_initConfig port
    # installing the slicing engines
    SlicingFactory.install v for k, v in config.printQualities.options
    # initializing the serial driver
    driver = DriverFactory.build config.driver
    # intializing the printer and server
    @_initPrinter driver, config

  addDryRunPrinter: ->
    driver = DriverFactory.build driver: {fork: true, type: "null"}
    port = serialNumber: "dev_null", comName: "dev/null"
    config = @_initConfig(port) # new Config port, name: "Dev Null Printer"
    @_initPrinter driver, config

  _initPrinter: (driver, config) ->
    @log "#{config.name} Connecting.."
    # initializing the printer and appending config data
    config.printer = new Printer(driver, config)
    config[k] = @[k] for k in ['app', 'server', 'enableAuth']
    config.on 'change', _.partial(@_onConfigChange, driver, config)
    # initializing the server routes
    ps = new PrinterServer config, @silent
    @printerServers[config.port.comName] = ps
    # removing the printer when it is disconnected
    driver.on "disconnect", @_onPrinterDisconnect.fill(ps)
    @log "#{config.name} Connected"

  _onConfigChange: (driver, config, changes) ->
    # Checking if this change requires restarting the driver/printer/server
    props = config.serverReloadingProps
    return unless _.some changes, (v, k) -> _.contains props, k
    # Reloading the driver/printer/server
    driver.kill()
    config.removeAllListeners()
    @addPrinter config.port, config

  _onPrinterDisconnect: (psA) =>
    ( delete @printerServers[k] if psA == psB ) for k, psB of @printerServers

  kill: =>
    ps.printer.driver.kill() for k, ps of @printerServers
    @server.close()

