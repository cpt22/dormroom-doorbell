var util = require('util');
var bleno = require('bleno');

var CHARACTERISTIC_NAME = 'PSK';
var str = "";

var  DoorbellPSKCharacteristic = function(doorbellState) {
    DoorbellPSKCharacteristic.super_.call(this, {
        uuid: '9772695f-2ca0-4144-af5d-90a86d82ab40',
        properties: ['read', 'write'],
        secure: [],
        descriptors: [
            new bleno.Descriptor({
                uuid: '2901',
                value: CHARACTERISTIC_NAME,
            }),
            new bleno.Descriptor({
                uuid: '2904',
                value: new Buffer([0x04, 0x00, 0x27, 0x00, 0x01, 0x00, 0x00])
            }),
        ],
    });

    this._update = null;
    this.doorbellState = doorbellState;

}

util.inherits(DoorbellPSKCharacteristic, bleno.Characteristic);

DoorbellPSKCharacteristic.prototype.onReadRequest = function(offset, callback) {
    console.log('onReadRequest');
    if (offset) {
        console.log('onReadRequest offset');
        callback(this.RESULT_ATTR_NOT_LONG, null);
    } else {
        let responseData = new Buffer(str);
        console.log("onReadRequest returning ", responseData);
        callback(this.RESULT_SUCCESS, responseData);
    }
}

DoorbellPSKCharacteristic.prototype.onWriteRequest = function(data, offset, withoutRespose, callback) {
    if (offset) {
        callback(this.RESULT_ATTR_NOT_LONG);
    } else if (data.length <= 0) {
        callback(this.RESULT_INVALID_ATTRIBUTE_LENGTH);
    } else {
        str = data.toString();
        console.log(data.toString());
        callback(this.RESULT_SUCCESS);
    }
}

module.exports = DoorbellPSKCharacteristic;