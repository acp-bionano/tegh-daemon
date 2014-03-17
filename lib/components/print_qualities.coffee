EventEmitter = require('events').EventEmitter
util = require 'util'
_ = require 'lodash'
Photo = require '../../vendor/photo'

module.exports = class PrintQualities extends EventEmitter

  constructor: (opts, cb) ->
    originalOptions = opts.options
    delete opts.options
    @[k] = v for k, v of opts

    # setting up the enumerable array of options (the array the websocket sees)
    @options = _.keys originalOptions
    # setting up the non-enumarable attributes of options (what we use to
    # configure slicing)
    Object.defineProperty @options, k, value: v for k, v of originalOptions

    setImmediate _.partial cb, @ if cb?

  components: ->
    [@]
