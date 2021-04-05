var child_process = require('child_process');
var device_id = child_process.execSync('cat /sys/class/net/eth0/address | sed s/://g').toString().replace(/\n$/, '');

process.env['BLENO_DEVICE_NAME'] = 'LAMPI ' + device_id;

var bleno = require('bleno');

// iBeacon UUID and variables
var uuid = 'B9407F30-F5F8-466E-AFF9-25556B57FE6D'; // Estimote iBeacon UUID
var major = 0;
var minor = 0;
var measuredPower = -59;

bleno.on('stateChange', function(state) {
  if (state === 'poweredOn') {
    console.log('poweredOn');
    bleno.startAdvertisingIBeacon(uuid, major, minor, measuredPower, function(err)  {
      if (err) {
        console.log(err);
      }
    });
  }
  else {
    console.log('not poweredOn');
  }
});

bleno.on('advertisingStart', function(err) {
  if (!err) {
    console.log('advertising...');
    // normally after 'advertisingStart' we would set our services
    //   for iBeacon, though, that is not useful
  }
});
