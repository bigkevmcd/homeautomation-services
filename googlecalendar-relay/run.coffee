GoogleCalendarRelay = require './googlecalendar-relay'
nconf = require 'nconf'
fs = require 'fs'
path = require 'path'


configFile = path.join process.env['HOME'], '.homeautomation/homeautomation.json'

nconf.file
  file: configFile

googleCalendarRelay = new GoogleCalendarRelay
  brokerHost: nconf.get 'brokerHost'
  cron: nconf.get 'googlecalendar:cron'
  calendars: nconf.get 'googlecalendar:calendars'

googleCalendarRelay.run()
