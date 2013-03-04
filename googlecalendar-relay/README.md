# Google Calendar Relay

This provides a way to parse Google calendars and emit events onto a ZeroMQ "bus".

It's designed to talk to the broker by [@StianEikeland](https://github.com/stianeikeland/homeautomation)

You will need the 'homeauto' modules from Stian's homeautomation repository, these are not yet packaged.

## Example

Create a configuration file in ~/.homeautomation/homeautomation.json

``` js
{
  "brokerHost": "<insert the broker host>",
  "googlecalendar": {
    "cron": "00 00 07 * * *",
    "calendars": [
      {
        "calendarId": "<calendarId1>",
        "magicCookie": "<insert magic cookie>",
        "cron": "00 30 * * * *"
      },
      {
        "calendarId": "<calendarId2>",
        "magicCookie": "<insert magic cookie>"
      }
    ]
  }
}
```
To get the calendarId and magicCookie, go to your calendar, view the "Calendar settings" and look at the XML "Private Address" for the calendar.

The URL is of the form http://www.google.com/calendar/feeds/<calendarId>/<magicCookie>/basic.

The calendarId may look like your Google email address, and the magicCookie will look like "private-HASH".

In the above configuration, two calendars will be checked, calendarId1 will be checked every hour, and calendarId2 at 7am every morning.

During each cron run, the service queries the calendar for events on the same day, and emits events for them, use the uid of the event if you need to avoid responding more than once to the same calendar event.

If you run the service

``` bash
  $ npm start
```

The output will be:

```
  Adding a job for calendarId1
  Adding a job for calendarId2
```

## Messages

The messages emitted by the service

The service pushes "calendar" messages to the Broker.

```
  Relaying packet of type: calendar >> {"event":"calendar","start":"2013-03-03T17:00:00.000Z","end":"2013-03-03T18:00:00.000Z",
  "title":"Heating On","uid":"6tkfg5rbqsjlcc18glabcdefgh@google.com","timestamp":"2013-03-03T13:22:01.057Z"}
  Relaying packet of type: calendar >> {"event":"calendar","start":"2013-03-03T06:00:00.000Z","end":"2013-03-03T07:00:00.000Z",
  "title":"Heating On","uid":"rh2dpbgc8u55pmdqdcabcdefgh@google.com","timestamp":"2013-03-03T13:22:01.057Z"}
```

## Cron configuration

The cron element uses the [cron](https://npmjs.org/package/cron) patterns, but defaults to 7am every morning.

#### Author: [Kevin McDermott](http://bigkevmcd.com)
#### License: MIT
