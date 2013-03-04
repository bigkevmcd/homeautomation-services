d8 = require 'd8'
require 'd8/locale/en-GB'

exports.getFormattedDate = (days) ->
   day = new Date
   day.setDate(day.getDate() + (if days? then days else 0))
   day.format(Date.formats.ISO_8601_SHORT)
