nconf = require 'nconf'
fs = require 'fs'
path = require 'path'

NetworkTrafficRelay = require './networktraffic-relay'

configFile = path.join process.env['HOME'], '.homeautomation/homeautomation.json'

nconf.file
  file: configFile

networkTrafficRelay = new NetworkTrafficRelay
  brokerHost: nconf.get 'brokerHost'

networkTrafficRelay.run()
