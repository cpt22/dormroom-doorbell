var util = require('util');
var bleno = require('bleno');

var CHARACTERISTIC_NAME = 'UpdateCredentials';
var str = "";

var DoorbellUpdateCredentialsCharacteristic = function(doorbellState) {
    DoorbellUpdateCredentialsCharacteristic.super_.call(this, {
        uuid: '9773695f-2ca0-4144-af5d-90a86d82ab40',
        properties: ['write'],
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

util.inherits(DoorbellUpdateCredentialsCharacteristic, bleno.Characteristic);

DoorbellUpdateCredentialsCharacteristic.prototype.onWriteRequest = function(data, offset, withoutRespose, callback) {
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

module.exports = DoorbellUpdateCredentialsCharacteristic;