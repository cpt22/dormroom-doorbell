var util = require('util');
var events = require('events');
var bleno = require('bleno');

var CHARACTERISTIC_NAME = 'Brightness';

var BrightnessCharacteristic = function(lampState) {
    bleno.Characteristic.call(this, {
        uuid: '0003A7D3-D8A4-4FEA-8174-1736E808C066',
        properties: ['read', 'write', 'notify'],
        descriptors: [
            new bleno.Descriptor({
               uuid: '2901',
               value: CHARACTERISTIC_NAME
            }),
            new bleno.Descriptor({
               uuid: '2904',
               value: Buffer.from([0x04])
            }),
        ],
    }
    )

    this.lampState = lampState;

    this._update = null;

    this.changed = function(new_value) {
        console.log('Brightness updated value - need to Notify?');
        if( this._update !== null ){
            var data = Buffer.alloc(1);
            data.writeUInt8(new_value, 0);
            this._update(data);
        }
    }

    this.lampState.on('changed-brightness', this.changed.bind(this));

}

util.inherits(BrightnessCharacteristic, bleno.Characteristic);

BrightnessCharacteristic.prototype.onReadRequest = function(offset, callback) {
    console.log('Brightness onReadRequest');
    if(offset) {
        callback(this.RESULT_ATTR_NOT_LONG, null);
    }
    else {
        var brightness = Buffer.alloc(1);
        brightness.writeUInt8(this.lampState.brightness);
        console.log('Brightness onReadRequest returning ', brightness);
        callback(this.RESULT_SUCCESS, brightness);
    }
}

BrightnessCharacteristic.prototype.onWriteRequest = function(data, offset, withoutResponse, callback) {
    if(offset) {
        callback(this.RESULT_ATTR_NOT_LONG);
    }
    else if (data.length !== 1) {
        callback(this.RESULT_INVALID_ATTRIBUTE_LENGTH);
    }
    else {
        var brightness = data.readUInt8(0);
        this.lampState.set_brightness( brightness);
        callback(this.RESULT_SUCCESS);
    }
};

BrightnessCharacteristic.prototype.onSubscribe = function(maxValueSize, updateValueCallback) {
    console.log('Brightness subscribe on ', CHARACTERISTIC_NAME);
    this._update = updateValueCallback;
}

BrightnessCharacteristic.prototype.onUnsubscribe = function() {
    console.log('Brightness unsubscribe on ', CHARACTERISTIC_NAME);
    this._update = null;
}

module.exports = BrightnessCharacteristic;