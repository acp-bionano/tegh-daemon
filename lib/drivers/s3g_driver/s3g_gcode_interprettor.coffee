BufferBuilder = require '../../buffer_builder'
payloadSizes = require('./s3g_payload_sizes').payloadSizes
toolPayloadSizes = require('./s3g_payload_sizes').toolPayloadSizes
BitMask = require('bit-mask')

# Builds a payload buffer for a host query or action
# nBytes: the number of bytes to add for variable sized packets like
#         setting EEPROM values.
payloadBuilder = (s3gCmdByte, size = payloadSizes[s3gCmdByte], nBytes = 0) ->
  size ?= 1
  b = new BufferBuilder size + nBytes
  b.addUInt8 s3gCmdByte
  return b

# Builds a payload buffer for a tool query or action
toolPayloadBuilder = (isAction, toolId, toolCmdByte, nBytes = 0) ->
  s3gCmdByte = if isAction then 136 else 10
  size = toolPayloadSizes[toolCmdByte]
  size ?= 2
  size += 1 if isAction
  b = payloadBuilder s3gCmdByte, size, nBytes
  b.addUInt8 toolId
  b.addUInt8 toolCmdByte
  b.addUInt8 size - 4 if isAction
  return b

slowestAxisStepsPerMM = (state) ->
  slowest = Math.Infinity
  slowest = v.stepsPerMM * v.microstepping if v.stepsPerMM < slowest for k, v of state.axes
  return slowest

axesBitmask = (gcode) ->
  mask = new BitMask(0)
  for i, k of "xyzee"
    mask.setBit(i, 1) if gcode.indexOf(k) != -1
  return mask


gcodeRegex = /([a-z])([\-0-9\.]+)/g


module.exports = parse: (gcode, state) ->
  console.log "gcode?"
  console.log gcode
  gcode = gcode.toLowerCase().replace(/\s/g, '')
  matches = gcode.match gcodeRegex

  cmd = matches.shift()
  attrs = {}
  attrs[s[0]] = parseFloat(s[1..]) for s in matches
  toolId = attrs.p || 0

  switch cmd
    when 'g0', 'g1' # Move
      b = payloadBuilder 142
      distance = 0
      # console.log attrs
      if attrs.e?
        eValue = attrs['e']
        delete attrs['e']
        attrs['ab'[state.tool]] = eValue
      for i, k of "xyzab"
        axis = state.axes[k]
        # console.log axis
        steps =  (attrs[k]||0) * (axis.stepsPerMM||1)
        steps = Math.round(steps * (state.unitsMultiplier||1) * (axis.microstepping||1))
        distance += Math.pow steps, 2
        b.addInt32 steps
      distance = Math.sqrt distance
      # Durration in microseconds
      # console.log distance
      # console.log state.feedrate
      state.feedrate = attrs.f / 60 if attrs.f?
      # console.log "Feedrate: #{state.feedrate}"
      b.addUInt32 Math.round(100000 * distance / state.feedrate)
      # Relative axes bit mask
      b.addUInt8 if state.absolutePosition then 0x0 else 0xF

    when 'g28' # Home
      b = payloadBuilder 131
      console.log axesBitmask(gcode).value
      # Timeout in seconds
      b.addUInt8 axesBitmask(gcode).value || 0xF
      # Max step rate in microseconds per step
      micros = 100 * slowestAxisStepsPerMM(state) / 40
      b.addUInt32 Math.round micros
      b.addUInt16 60 # 60 second timeout. This is totally arbitrary.

    when 'g4' # Dwell
      b = payloadBuilder 133
      b.addUInt32 attrs['p']

    when 'g20' # Set to inches
      state.unitsMultiplier = 25.4

    when 'g21' # Set to mm
      state.unitsMultiplier = 1

    when 'm84' # Disable extruder stepper
      b = toolPayloadBuilder true, toolId, 10
      b.addUInt8 0

    when 'g90', 'g91' # Set to absolute / relative positioning
      state.absolutePosition = (cmd == 'g90')

    when 'g92' # Set Position (offset, does not physically move the printer)
      b = payloadBuilder 133
      b.addUInt32 attrs['p']

    when 'm17', 'm18' # Enable/Disable steppers
      b = payloadBuilder 137
      bits = 0
      bits |= 1 << i for i in [0..4]
      bits |= 1 << 7 if cmd == 'm17'
      b.addUInt8 bits

    when 'm92' # Set axis_steps_per_unit (Marlin firmware)
      return []

    when 'm104' # Set extruder temperature
      b = toolPayloadBuilder true, toolId, 3
      b.addInt16 attrs.s

    when 'm105' # Get extruder temperature
      b = toolPayloadBuilder false, toolId, 2

    when 'm106', 'm107' # Enable / Disable Fan
      b = toolPayloadBuilder true, toolId, 12
      b.addUInt8(if cmd == 'm106' then 1 else 0)

    when 'm109' # Set extruder temperature and wait
      # Set temp
      b = toolPayloadBuilder true, toolId, 3
      b.addInt16 attrs.s
      # Wait for tool ready
      b2 = payloadBuilder 135
      b2.addInt8 toolId
      b2.addUInt16 100 # delay between packets
      # delay until timing out and continuing even though the tool isn't ready
      # in minutes. Set to max because this sounded sketchy at best.
      b2.addUInt16 Math.pow(2,16)-1

    when 'm140' # Set bed temperature
      b = toolPayloadBuilder true, toolId, 31
      b.addInt16 attrs.s

    when 'm190' # Set bed temperature and wait
      b = toolPayloadBuilder true, toolId, 31
      b.addInt16 attrs.s
      b2 = payloadBuilder 141
      b2.addInt8 toolId
      b2.addUInt16 100 # delay between packets
      # delay until timing out and continuing even though the tool isn't ready
      # in minutes. Set to max because this sounded sketchy at best.
      b2.addUInt16 Math.pow(2,16)-1

    when 'm240', 'm241' # Enable / Disable Conveyor
      b = toolPayloadBuilder true, toolId, 13
      b.addUInt8(if cmd == 'm240' then 1 else 0)

    else
      if gcode.startsWith 't' # Select Tool
        state.tool = parseInt gcode[1..]
      else
        throw new Error "Invalid gcode #{cmd.capitalize()} in line: #{gcode}"

  return [b?.buffer, b2?.buffer].compact()
