BusClient = require './busclient'
fs = require 'fs'
os = require 'os'

delay = (ms, func) -> setTimeout func, ms

class NetworkRelay extends BusClient

    constructor: (options = {}) ->
      super(options)
      @pollTime = options.time ?= 60000
      @procNetDev = options.filename ?= '/proc/net/dev'
      @counter = 0
      @hostname = options.hostname ?= os.hostname()
      @previousValues = {}

    runService: () ->
      @watchProcNetDev()

    watchProcNetDev: () ->
      @processProcNetDev()
      delay(@pollTime, @watchProcNetDev)

    getNow: () ->
      new Date().getTime()

    processProcNetDev: (callback) ->
      fs.readFile @procNetDev, (err, data) =>
        throw err if err?
        now = @getNow()
        lines = data.toString().split '\n'
        columnLine = lines[1]
        elements = columnLine.split '|'
        receiveColumns = elements[1]
        transmitColumns = elements[2]

        dataColumns = []
        for key in receiveColumns.split /\s+/
          dataColumns.push "recv_#{key}"
        for key in transmitColumns.split /\s+/
          dataColumns.push "trans_#{key}"
        interfaces = {}
        for line in lines[2..]
          if not (/:/.test line)
            continue
          line = line.split /:/
          iface = line[0].replace(/^\s+|\s+$/g, '')
          message = {}
          index = 0
          for val in line[1].split /\s+/
            if val # Skips the initial whitespace at the start of the line
              message[dataColumns[index++]] = val
          message.event = 'bandwidth'
          message.iface = iface
          message.hostname = @hostname
          message.timestamp = new Date()
          message.nodeid = "#{@hostname}:#{iface}"
          message.counter = @counter++

          previousValue = @previousValues[message.nodeid]
          if previousValue?
            timeDelta = (now - previousValue.time) / 1000
            message.recv_delta = (message.recv_bytes - previousValue.recv_bytes) / timeDelta
            message.trans_delta = (message.trans_bytes - previousValue.trans_bytes) / timeDelta
          @previousValues[message.nodeid] =
            recv_bytes: message.recv_bytes
            trans_bytes: message.trans_bytes
            time: now
          @bus.send message

        if callback?
           callback()

module.exports = NetworkRelay
