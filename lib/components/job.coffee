fs = require("fs-extra")
path = require ("flavored-path")
SlicingEngineFactory = require path.join __dirname, "../slicing_engines/factory"
EventEmitter = require('events').EventEmitter
exec = require('child_process').exec
Join = require('join')
nodeUUID = require('node-uuid')

module.exports = class PrintJob extends EventEmitter
  nonEnumerables:
    ['_gcodePath', '_modelPath', '_cancelled', '_slicingEngine', '_cb', 'key']

  constructor: (opts, cb, @_slice = SlicingEngineFactory.slice) ->
    # Setting the enumerable properties
    @[k] = v for k, v of Object.merge @_defaults(opts), opts
    # Setting up the non-enumerable properties
    for k in @nonEnumerables
      Object.defineProperty @, k, writable: true, value: undefined
    # Generating a unique key
    @key = nodeUUID.v4().replace(/-/g, "")
    # Initializing the file path
    isGCode = path.extname(filePath).match(/.gcode|.ngc/i)?
    pathAttr = if isGCode then "_gcodePath" else "_modelPath"
    @[pathAttr] = path.resolve(@filePath)
    delete @filePath
    # Calling the callback. For Assembly async compatibility.
    setTimeout cb, 0

  _defaults: (opts) =>
    qty: 1
    qtyPrinted: 0
    status: "idle"
    type: "job"
    assemblyId: null
    quality: if @needsSlicing() then "normal" else null # draft | normal | high

  components: ->
    [@]

  beforeDelete: ->
    @cancel()
    @removeAllListeners()
    fs.remove @_modelPath, @_deletionError if @_modelPath?
    @_deleteGCodeFile()

  _deleteGCodeFile: ->
    fs.remove @_gcodePath, @_deletionError if @_gcodePath?
    delete @_gcodePath

  _deletionErr: (err) ->
    console.log err.trace?() || err if err?

  cancel: =>
    @_cancelled = new Date()
    if @_slicingInstance?
      @_toggleSlicingEngineEvents 'off'
      @_slicingInstance.cancel()
    @removeListener "load", @_cb if @_cb?
    @_slicingInstance = null
    @_cb = null
    return @

  _cancelledAfter: (timestamp) =>
    @_cancelled and timestamp.isBefore @_cancelled

  needsSlicing: =>
    @_modelPath?

  loadGCode: (slicerOpts, cb = null) =>
    @_cb = cb
    @once "load", cb if cb?
    if @needsSlicing()
      @_slicingEngine = @_slice slicerOpts, @_modelPath
      @_toggleSlicingEngineEvents 'on'
    else
      setTimeout @onSlicingComplete, 0

  _toggleSlicingEngineEvents: (onOrOff) ->
    @_slicingEngine
    [onOrOff]('error', onSlicingError)
    [onOrOff]('complete', onSlicingComplete)

  onSlicingError: (e) =>
    console.log "slicer error"
    console.log e
    @emit "job_error", "slicer error"

  onSlicingComplete: =>
    join = Join.create()
    @currentLine = 0
    @_gcodePath = @_slicingEngine.gcodePath if @_slicingEngine?
    @_slicingEngine = undefined

    # Getting the number of lines in the file
    exec "wc -l #{@_gcodePath}", join.add()
    # Loading the gcode to memory
    fs.readFile @_gcodePath, 'utf8', join.add()
    join.when @_onLoadAndLineCount.fill new Date()

  _onLoadAndLineCount: (timestamp, lineCountArgs, loadArgs) =>
    # Deleting the gcode file now that it's loaded into memory
    @_deleteGCodeFile()
    # Stopping if the job was cancelled
    return if @_cancelledAfter timestamp
    # Parsing the loaded information and emitting the load event
    [err, gcode] = loadArgs
    @totalLines = parseInt(lineCountArgs[1].match(/\d+/)[0])
    if @totalLines == NaN or err?
      return @emit "job_error", "error loading gcode"
    @emit "load", err, gcode