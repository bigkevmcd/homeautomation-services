nock = require 'nock'
util = require 'util'

GoogleCalendarRelay = require '../googlecalendar-relay'
helpers = require '../helpers'


testConfig =
  brokerHost: '127.0.0.1'
  cron: '00 00 07 * * *'
  calendars: [
    calendarId: '1234567random@group.calendar.google.com'
    magicCookie: 'private-abcdefghijk'
    cron: '00 30 * * * *'
  ,
    calendarId: 'testing@example.com'
    magicCookie: 'private-lmnopqrstuv'
  ]


class FakeMessageBus

  constructor: () ->
    @messages = []
    @closed = false

  send: (message) ->
    @messages.push message

  close: () ->
    @closed = true


class FakeCronJob
  constructor: (@pattern) ->
    @started = false
    @stopped = false

  start: () ->
    @started = true

  stop: () ->
    @stopped = true


class FakeConsole
  constructor: () ->
    @messages = []

  log: (message) ->
    @messages.push message


describe 'GoogleCalendarRelay', ->

  it 'can be instantiated', (done) ->
    relay = new GoogleCalendarRelay
    done()

  describe 'getCalendarUrlForToday', (done) ->
    it 'should return a url to fetch the calendar for events today', (done) ->
      today = helpers.getFormattedDate()
      tomorrow = helpers.getFormattedDate(1)

      relay = new GoogleCalendarRelay(testConfig)
      period = "start-min=#{today}&start-max=#{tomorrow}"
      url = relay.getCalendarUrlForToday(testConfig.calendars[0])
      expect(url).toEqual(
        "https://www.google.com/calendar/feeds/1234567random@group.calendar.google.com/private-abcdefghijk/full?#{period}")
      done()

  describe 'fetchUrlAndDispatch', (done) ->
    beforeEach (done) =>
      @fakeBus = new FakeMessageBus()
      done()

    it 'should fetch a url and send messages to the bus', (done) =>
      scope = nock('https://www.google.com/').get('/calendar/test')
        .replyWithFile(200, __dirname + '/fixtures/fixture1.xml')

      relay = new GoogleCalendarRelay(
        bus: @fakeBus
      )
      relay.fetchUrlAndDispatch 'https://www.google.com/calendar/test', (err) =>
        expect(@fakeBus.messages).toEqual([
            event: 'calendar'
            start: '2013-03-02T19:00:00.000Z'
            end: '2013-03-02T21:00:00.000Z'
            title: 'Testing Event'
            content: 'Testing Event'
            where : '4 High Street'
            status: 'confirmed'
            uid : 'q2h4tjfbn4abcdefgh12345678@google.com'
          ,])
        done()

    it 'should callback with an error if it gets a non 200 response', (done) =>
      scope = nock('https://www.google.com/').get('/calendar/test').reply(404)

      relay = new GoogleCalendarRelay(
        bus: @fakeBus
      )
      relay.fetchUrlAndDispatch 'https://www.google.com/calendar/test', (err, response, body) =>
        expect(response.statusCode).toBe(404)
        done()

    it 'should callback with an error if it gets an error parsing the content', (done) =>
      scope = nock('https://www.google.com/').get('/calendar/test').reply(200, 'Incorrect text')
      relay = new GoogleCalendarRelay(
        bus: @fakeBus
      )
      relay.fetchUrlAndDispatch 'https://www.google.com/calendar/test', (err, response) =>
        expect(err.toString().match(/Non-whitespace before first tag/)).toBeTruthy()
        done()

    it 'handle not having a bus to send messages on', (done) =>
      scope = nock('https://www.google.com/').get('/calendar/test')
        .replyWithFile(200, __dirname + '/fixtures/fixture1.xml')
      relay = new GoogleCalendarRelay
      relay.fetchUrlAndDispatch 'https://www.google.com/calendar/test', (err) =>
        expect(@fakeBus.messages).toEqual([])
        done()

  describe 'close', (done) ->
    beforeEach (done) =>
      @fakeBus = new FakeMessageBus()
      @relay = new GoogleCalendarRelay(
        bus: @fakeBus
      )
      done()

    it 'should stop all the cronjobs', (done) =>
      jobs = [new FakeCronJob, new FakeCronJob]
      @relay.jobs = jobs

      @relay.close()
      expect(job.stopped for job in jobs).toEqual([true, true])
      done()

    it 'should close the messagebus if one exists', (done) =>
      @relay.close()
      expect(@fakeBus.closed).toBeTruthy()
      done()

  describe 'runService', (done) ->
    beforeEach (done) =>
      @fakeBus = new FakeMessageBus
      @fakeConsole = new FakeConsole
      @relay = new GoogleCalendarRelay(
        bus: @fakeBus
        brokerHost: '127.0.0.1'
        console: @fakeConsole
        cron: '00 00 07 * * *'
        cronJob: FakeCronJob
        calendars: [
          calendarId: '1234567random@group.calendar.google.com'
          magicCookie: 'private-abcdefghijk'
          cron: '00 30 * * * *'
        ,
          calendarId: 'testing@example.com'
          magicCookie: 'private-lmnopqrstuv'
        ]
      )
      done()

    it 'should setup a cronjob for each calendar', (done) =>
      @relay.runService()
      expect(@relay.jobs.length).toBe(2)
      done()

    it 'should configure cronjobs should use a default pattern if no cron is supplied', (done) =>
      @relay.runService()
      expect(job.pattern for job in @relay.jobs).toEqual(['00 30 * * * *', '00 00 07 * * *'])
      done()

    it 'should start the newly created cronjobs', (done) =>
      @relay.runService()
      expect(job.started for job in @relay.jobs).toEqual([true, true])
      done()

    it 'should log the calendarIds that jobs are created for', (done) =>
      @relay.runService()
      expect(@fakeConsole.messages).toEqual([
        'Starting service',
        'Adding a job for 1234567random@group.calendar.google.com',
        'Adding a job for testing@example.com'])
      done()
