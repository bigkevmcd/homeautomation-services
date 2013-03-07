request = require 'request'
xml2js = require 'xml2js'
cron = require 'cron'

BusClient = require './busclient'
helpers = require './helpers'

parserOptions =
  mergeAttrs: true

# Takes an entry for the form and returns its text
extractTextFromEntry = (entry, attribute) ->
  (item['_'] for item in entry[attribute]).join ' '

extractValueFromEntry = (entry, attribute) ->
  (item['value'] for item in entry[attribute]).join ' '

extractWhereFromEntry = (entry) ->
  (item['valueString'] for item in entry['gd:where']).join ' '

statusMapping =
  'http://schemas.google.com/g/2005#event.canceled': 'canceled'
  'http://schemas.google.com/g/2005#event.confirmed': 'confirmed'
  'http://schemas.google.com/g/2005#event.tentative': 'tentative'


class GoogleCalendarRelay extends BusClient

  constructor: (@options = {}) ->
    super(@options)
    @cronJob = @options.cronJob ?= cron.CronJob
    @jobs = []
    @on 'entry', (message) =>
      if @bus?
        @bus.send message

  getCalendarUrlForToday: (cal) ->
    today = helpers.getFormattedDate()
    tomorrow = helpers.getFormattedDate(1)
    period = "start-min=#{today}&start-max=#{tomorrow}"
    "https://www.google.com/calendar/feeds/#{cal.calendarId}/#{cal.magicCookie}/full?#{period}"

  close: () ->
    super()
    for job in @jobs
      job.stop()

  runService: () ->
    @console.log 'Starting service'
    defaultCron = @options.cron ? '00 00 07 * * *'
    for cal in @options.calendars
      do (cal) =>
        @console.log "Adding a job for #{cal.calendarId}"
        job = new @cronJob cal.cron ? defaultCron, () =>
            url = @getCalendarUrlForToday(cal)
            @fetchUrlAndDispatch(url)
        @jobs.push job
        job.start()

  fetchUrlAndDispatch: (url, callback) ->
    request.get url, (err, response, body) =>
      if not err and response.statusCode == 200
        parser = new xml2js.Parser(parserOptions)
        parser.parseString body, (err, result) =>
          if not err?
            if result.feed.entry?
              for entry in result.feed.entry
                for times in entry['gd:when']
                  status = extractValueFromEntry entry, 'gd:eventStatus'
                  message =
                    event: 'calendar'
                    start: times.startTime ? undefined
                    end: times.endTime ? undefined
                    title: extractTextFromEntry entry, 'title'
                    content: extractTextFromEntry entry, 'content'
                    where: extractWhereFromEntry entry
                    status: statusMapping[status] ? 'unknown'
                    uid: extractValueFromEntry entry, 'gCal:uid'
                  @emit 'entry', message
            return callback() if callback
          else
            return callback(err)
      else
        return callback(err, response, body)

module.exports = GoogleCalendarRelay
