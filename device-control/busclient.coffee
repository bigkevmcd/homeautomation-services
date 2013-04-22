# To be moved to the main Bus module

MessageBus = (require 'homeauto').MessageBus
EventEmitter = (require 'events').EventEmitter


class BusClient extends EventEmitter

    constructor: (@options = {}) ->
      @console = @options.console ?= console
      @process = @options.process ?= process
      @bus = @options.bus

      @process.on 'SIGINT', () =>
        @close()

    close: () ->
      if @bus then @bus.close()

    run: () ->
      @bus = @bus ?= @_createMessageBus(@options)
      @runService()

    _createMessageBus: (options = {}) ->
      hostname = options.brokerHost
      new MessageBus(
        subAddress: "tcp://#{hostname}:9999"
        pushAddress: "tcp://#{hostname}:8888"
        # TODO: Work out a good way of calculating this
        identity: "googlecalendar-relay-#{@process.pid}"
      )

module.exports = BusClient