BusClient = require './busclient'


class DeviceControlRelay extends BusClient

  constructor: (@options = {}) ->
    super(@options)
    @on 'entry', (message) =>
      if @bus?
        @bus.send message

  runService: () ->
    @console.log 'Starting service'


module.exports = DeviceControlRelay
