util = require 'util'

DeviceControlRelay = require '../devicecontrol-relay'


class FakeMessageBus

  constructor: () ->
    @messages = []
    @closed = false

  send: (message) ->
    @messages.push message

  close: () ->
    @closed = true


class FakeConsole
  constructor: () ->
    @messages = []

  log: (message) ->
    @messages.push message


describe 'DeviceControlRelay', ->

  it 'can be instantiated', (done) ->
    relay = new DeviceControlRelay
    done()

  describe 'close', (done) ->
    beforeEach (done) =>
      @fakeBus = new FakeMessageBus()
      @relay = new DeviceControlRelay(
        bus: @fakeBus
      )
      done()

    it 'should close the messagebus if one exists', (done) =>
      @relay.close()
      expect(@fakeBus.closed).toBeTruthy()
      done()

  describe 'runService', (done) ->
    beforeEach (done) =>
      @fakeBus = new FakeMessageBus
      @fakeConsole = new FakeConsole
      @relay = new DeviceControlRelay(
        bus: @fakeBus
        brokerHost: '127.0.0.1'
        console: @fakeConsole
        rfxtrxDevice: '/dev/ttyUSB0'
      )
      done()

    it 'should', (done) ->
      done()
