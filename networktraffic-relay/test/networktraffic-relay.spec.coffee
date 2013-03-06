NetworkTrafficRelay = require '../networktraffic-relay'
os = require 'os'

class FakeMessageBus

  constructor: () ->
    @messages = []
    @closed = false

  send: (message) ->
    @messages.push message

  close: () ->
    @closed = true

removeDuplicates = (array) ->
  array.filter (v, i, a) ->
    a.indexOf(v) == i


describe 'NetworkTrafficRelay', ->

  beforeEach (done) =>
    @bus = new FakeMessageBus
    done()

  it 'can be instantiated', (done) =>
    relay = new NetworkTrafficRelay()
    done()

  describe 'processProcNetDev', (done) =>
    beforeEach (done) =>
      @relay = new NetworkTrafficRelay(
        filename: __dirname + '/fixtures/procnetdev1'
        bus: @bus
      )
      done()

    it 'should emit a message per device', (done) =>
      @relay.processProcNetDev () =>
        expect(@bus.messages.length).toBe(4)
        done()

    it 'should send messages with the current hostname', (done) =>
      @relay.processProcNetDev () =>
        hostnames = removeDuplicates(message.hostname for message in @bus.messages)
        expect(hostnames).toEqual([os.hostname()])
        done()

    it 'should send messages with the type "bandwidth"', (done) =>
      @relay.processProcNetDev () =>
        type = removeDuplicates(message.event for message in @bus.messages)
        expect(type).toEqual(['bandwidth'])
        done()

    it 'should send messages with the currently received bytes', (done) =>
      @relay.processProcNetDev () =>
       recv_bytes = (message.recv_bytes for message in @bus.messages)
       expect(recv_bytes).toEqual(['0', '207941651', '0', '3802969997'])
       done()

    it 'should send messages with the currently transmitted bytes', (done) =>
      @relay.processProcNetDev () =>
       trans_bytes = (message.trans_bytes for message in @bus.messages)
       expect(trans_bytes).toEqual(['0', '207941651', '0', '771392249'])
       done()

    it 'should not send any delta if we did not have comparison data', (done) =>
      @relay.processProcNetDev () =>
       recv_delta = removeDuplicates(message.recv_delta for message in @bus.messages)
       expect(recv_delta).toEqual([undefined])
       done()

    it 'it should send a delta if we have comparison data', (done) =>
      times = [10000, 0]
      spyOn(NetworkTrafficRelay.prototype, 'getNow').andCallFake () ->
        times.pop()
      @relay.processProcNetDev () =>
        @bus.messages = [] # Clear the messages after the first run through
        @relay.procNetDev = __dirname + '/fixtures/procnetdev2'
        @relay.processProcNetDev () =>
          delta_mapping = {}
          for message in @bus.messages
            delta_mapping[message.iface] =
              receive: message.recv_delta
              transmit: message.trans_delta
          for iface in ['eth0', 'lo', 'virbr0']
            expect(delta_mapping[iface]).toEqual(
              receive: 0
              transmit: 0
            )
          expect(delta_mapping['wlan0']).toEqual(
            receive: 100
            transmit : 100
          )
          done()
