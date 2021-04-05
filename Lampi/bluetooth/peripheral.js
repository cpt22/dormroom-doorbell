#! /home/pi/.nvm/versions/node/v8.15.1/bin/node


var child_process = require('child_process');
var device_id = child_process.execSync('cat /sys/class/net/eth0/address | sed s/://g').toString().replace(/\n$/, '');
console.log("Device ID: " + device_id);

process.env['BLENO_DEVICE_NAME'] = 'LAMPI ' + device_id;

var bleno = require('bleno');

var DeviceInfoService = require('./device-info-service');

var LampState = require('./lampi-state');
var LampService = require('./lampi-service');

var lampState = new LampState();

var deviceInfoService = new DeviceInfoService( 'CWRU', 'LAMPI', '123456');
var lampService = new LampService(lampState);

lampState.on('changed-onoff', function(new_value) {
  console.log('changed-onoff:  value = %d', new_value);
});

lampState.on('changed-brightness', function(new_value) {
  console.log('changed-brightness:  value = %d', new_value);
});

lampState.on('changed-hsv', function(new_hue, new_saturation) {
  console.log('changed-hsv:  value = %d', new_hue, new_saturation);
});

bleno.on('stateChange', function(state) {
  if (state === 'poweredOn') {
    bleno.startAdvertising('Lampi Service', [lampService.uuid, deviceInfoService.uuid], function(err)  {
      if (err) {
        console.log(err);
      }
    });
  }
  else {
    bleno.stopAdvertising();
    console.log('not poweredOn');
  }
});


bleno.on('advertisingStart', function(err) {
  if (!err) {
    console.log('advertising...');
    
    bleno.setServices([
      lampService,
      deviceInfoService,
    ]);
  }
});
