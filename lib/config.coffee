EventEmitter = require('events').EventEmitter
_ = require 'lodash'
path = require 'path'
fs = require 'fs'
modKeys         = require '../vendor/mod_keys'
SmartObject     = require '../vendor/smart_object'
InstallBuilder  = require "./install_builder"

module.exports = class Config extends EventEmitter
  # These properties we will have to reload the server for.
  serverReloadingProps: ['name', 'driver', 'polling']
  # These properties are static.
  staticAttrs: ['app', 'server', 'port']

  _defaults: ->
    # These properties we will have to reload the server for.
    name: "Printer ##{@port.serialNumber}"
    driver: "serial_gcode"
    polling: true
    # These properties we can outright ignore because they don't have any state.
    verbose: false
    pauseBetweenPrints: true
    # These properties we can send updates through the websocket for
    components: { e0: 'heater', b: 'heater', c: 'conveyor', f: 'fan' }
    printQualities: {default: "normal", options: @_defaultQualityOptions()}

  _defaultQualityOptions: ->
    draft:
      engine: "cura_engine"
      profile: "default"
      params: {layer_height: 10, infill: 5}
    normal:
      engine: "cura_engine"
      profile: "default"
      params: {layer_height: 5, infill: 20}
    high:
      engine: "cura_engine"
      profile: "default"
      params: {layer_height: 2, infill: 50}

  # Non-enumerable properties
  app: null
  server: null

  constructor: (@port, arg) ->
    # Making sure all non-config attributes non-enumerable
    for k,v of @
      delete @[k]
      Object.defineProperty @, k,
        writable: true
        configurable: true
        value: v
    # initializing the configuration
    if typeof arg == 'string'
      @filePath = arg
      @_initFromFile()
    else
      @_initFromObj arg

  _initFromFile: ->
    try
      obj = require @filePath
      @_onFileReady()
    catch
      console.log "New printer detected. Creating a config file."
      defaultsDir = path.join __dirname, "..", "defaults"
      installer = new InstallBuilder defaultsDir, path.dirname @filePath
      installer.run _.partial(@_install, @filePath), @_onFileReady
    if @$?
      @_reload obj
    else
      @_initFromObj obj

  _initProperties: (obj) ->
    _.merge @_defaults(), modKeys.camelize obj

  _initFromObj: (obj = {}) ->
    obj = @_initProperties obj
    for k in @staticAttrs
      @[k] ?= obj[k]
      delete obj[k]
    # Defining the buffer as a non-enumarble property so that it's excluded
    # from JSON
    Object.defineProperty @, "$",
      writable: true
      configurable: true
      value: new SmartObject obj
    # Binding events
    @$.on k, _.bind(@emit, @, k) for k in ['add', 'rm', 'change']
    # Adding properties from the buffer as enumerable attributes so that they
    # are included in JSON
    for k, v of @$.buffer
      Object.defineProperty @, k,
        enumerable: true
        configurable: true
        get: _.partial @_get, k

  _reload: (obj = {}) ->
    @$.merge @_initProperties obj

  _install: (filePath) ->
    @install 'printer.yml'
    @mv 'printer.yml', path.basename filePath

  _onFileReady: =>
    return if @_watcher?
    # initializing the config file watching and reloading
    Object.defineProperty @, "_watcher",
      configurable: true
      value: fs.watch(@filePath, persistent: false)
    @_watcher.on "change", @_onFileChange

  _onFileChange: =>
    @_initFromFile()

  kill: =>
    @_watcher?.close?()
    @removeAllListeners()
    @$.removeAllListeners()
    @$ = undefined

  _get: (key) =>
    @$.buffer[key]
