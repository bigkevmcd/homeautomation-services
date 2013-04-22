DeviceControlRelay = require './devicecontrol-relay'
nconf = require 'nconf'
fs = require 'fs'
path = require 'path'


configFile = path.join process.env['HOME'], '.homeautomation/homeautomation.json'

nconf.file
  file: configFile

deviceControlRelay = new DeviceControlRelay
  brokerHost: nconf.get 'brokerHost'

deviceControlRelay.run()
