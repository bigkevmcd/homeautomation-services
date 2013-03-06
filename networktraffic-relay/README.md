# Network Traffic Relay

This runs on Linux machines with /proc/net/dev and parses and emits the data,
and deltas where possible, and emits the parsed data as messages on a ZeroMQ "bus".

It's designed to talk to the broker by [@StianEikeland](https://github.com/stianeikeland/homeautomation)

You will need the 'homeauto' modules from Stian's homeautomation repository, these are not yet packaged.

## Example

Create a configuration file in ~/.homeautomation/homeautomation.json

``` js
{
  "brokerHost": "<insert the broker host>",
}
```
There are several other options you can add...


``` js
{
  "time": 10000 // The data will be reported every 10000 milliseconds
                // defaults to 60000 i.e. once a minute
  "hostname": "testing": // This defaults to os.hostname()
  "file": "/other/proc/net/dev" // This defaults to /proc/net/dev
}
```

You can run the service with:

``` bash
  $ npm start
```

## Messages

The messages emitted by the service

The service pushes "bandwidth" messages to the Broker.

```
  Relaying packet of type: bandwidth >> {"recv_bytes":"3496296245","recv_packets":"15534290",
      "recv_errs":"0","recv_drop":"0","recv_fifo":"0","recv_frame":"0","recv_compressed":"0",
      "recv_multicast":"0","trans_bytes":"26104568412","trans_packets":"22742218",
      "trans_errs":"0","trans_drop":"0","trans_fifo":"1","trans_colls":"0","trans_carrier":"0",
      "trans_compressed":"0","event":"bandwidth","iface":"eth0","hostname":"myhost",
      "timestamp":"2013-03-06T10:56:22.255Z","nodeid":"myhost:eth1",
      "counter":12164,"recv_delta":294.4686099028382,"trans_delta":571.9547355965535}
```

The keys are composed from the headers in /proc/net/dev with the addition of:

``` js
{
  "iface": "eth0" // This is the interface from the device stats
  "nodeid": "myhost:eth0" // This is composed from the interface and hostname
  "hostname": "myhost" // either provided or from os.hostname()
  "recv_delta": 294.468 // Delta from previous measurement (if available)
  "trans_delta": 294.468 // Delta from previous measurement (if available)
}
```
#### Author: [Kevin McDermott](http://bigkevmcd.com)
#### License: MIT
