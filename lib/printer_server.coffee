WebSocketServer = require('ws').Server
http = require("http")
express = require("express")
mdns = require('mdns2')
avahi = require('avahi_pub')
formidable = require('formidable')
nodeUUID = require('node-uuid')
pamAuth = require "express-pam"
modKeys = require('../vendor/mod_keys')
wsPamAuth = require('../vendor/ws_pam_auth')

module.exports = class PrinterServer
  constructor: (opts, @silent) ->
    @[k] = opts[k] for k in ['name', 'printer', 'app']
    @slug = @name.underscore().replace("#", "")
    @path = "/printers/#{@slug}"
    @_clients = {}
    wssOpts =
      server: opts.server
      path: "#{@path}/socket"
      protocolVersion: 8
    wssOpts.verifyClient = wsPamAuth serviceName: "tegh" if opts.enableAuth
    @wss = new WebSocketServer wssOpts

    @wss.on "connection", @onClientConnect

    if avahi.isSupported()
      @avahiAd = avahi.publish
        name: @slug
        type: "_tegh._tcp"
        data: {txtvers:'1'}
        port: 2540
    else
      @mdnsAd = mdns.createAdvertisement "_tegh._tcp", 2540,
        name: @slug
        txtRecord: {txtvers:'1'}
      @mdnsAd.start()

    @printer.driver.on "disconnect", @onPrinterDisconnect
    @printer.on "change", @onPrinterChange
    @printer.on "add", @onPrinterAdd
    @printer.on "rm", @onPrinterRm

    @app.post @path, @createComponent

  createComponent: (req, res) =>
    uuid = req.query.session_uuid
    form = new formidable.IncomingForm(keepExtensions: true)
    ws = @_clients[uuid]
    form.on 'error', (e) -> console.log (e)
    form.on 'progress', @_onUploadProgress.fill(ws) if uuid?
    form.parse req, @_onUploadParsed.fill(ws, res)

  _onUploadProgress: (ws, bytesReceived, bytesExpected) =>
    msg =
      type: 'change'
      target: 'upload_progress'
      data: { uploaded: bytesReceived, total: bytesExpected }
    @send ws, [msg]

  _onUploadParsed: (ws, res, err, fields, files) =>
    return console.log err if err?
    try
      @printer.add
        filePath: files.file.path
        qty: fields.qty || 1
        fileName: files.file.name
    catch e
      res.status(500)
      @_catchActionError(ws, e)

    res.end()

  broadcast: (data) =>
    data = modKeys.underscore data
    @send ws, data for ws in @wss.clients

  send: (ws, data) =>
    try
      ws.send JSON.stringify(data), @_onSend.fill(ws)
    catch
      try ws.close()

  _onSend: (ws, error) ->
    return unless error?
    console.log "error sending data to client"  unless @silent
    console.log error  unless @silent
    ws.terminate()

  onClientConnect: (ws) =>
    ws.on 'message', @onClientMessage.fill(ws)
    ws.on "close", @onClientDisconnect
    console.log @printer.data
    data = modKeys.underscore @printer.data
    # console.log data
    uuid = nodeUUID.v4()
    Object.merge data, session: { uuid: uuid }
    @send ws, [{type: 'initialized', data: data}]
    @_clients[uuid] = ws
    console.log "#{@name}: Client Attached" unless @silent

  onClientDisconnect: (wsA) =>
    (delete @_clients[uuid] if wsA == wsB) for uuid, wsB of @_clients
    console.log "#{@name}: Client Detached" unless @silent

  _websocketActions: [
    'home',
    'move',
    'set',
    'estop',
    'print',
    'rm',
    'retry_print'
  ]

  onClientMessage: (ws, msgText, flags) =>
    try
      # Parsing / Fail fast
      msg = modKeys.camelize JSON.parse msgText
      if @_websocketActions.indexOf(msg.action) == -1
        throw new Error("#{msg.action} is not a valid action")
      # Executing the action and responding
      response = @printer[msg.action.camelize false](msg.data)
      @send ws, [type: 'ack']
    catch e
      @_catchActionError(ws, e)
    # console.log "client message:"
    # console.log msg

  _catchActionError: (ws, e) =>
    console.log e.stack if e.stack?
    data = type: 'runtime.sync', message: e.toString()
    @send ws, [type: 'error', data: modKeys.underscore data]

  onPrinterChange: (changes) =>
    # console.log "printer change:"
    # console.log changes
    @broadcast ( type: 'change', target: k, data: v for k, v of changes )

  onPrinterAdd: (target, value) =>
    @broadcast [type: 'add', target: target, data: value]

  onPrinterRm: (target) =>
    @broadcast [type: 'rm', target: target]

  onPrinterDisconnect: =>
    console.log "#{@name} Disconnecting.."  unless @silent
    # Removing all the event listeners from the server so it will be GC'd
    @printer.driver.removeAllListeners()
    @printer.removeAllListeners()
    # Removing the websocket
    try
      @wss.close()
    catch e
      console.log e.stack
    @wss.removeAllListeners()
    # Removing the create component upload route
    @app.routes.post.remove (route) => route.path = @path
    # Removing the DNS-SD advertisement
    if @mdnsAd? then @mdnsAd.stop() else @avahiAd.remove()
    console.log "#{@name} Disconnected"  unless @silent
