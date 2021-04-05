var util = require('util');
var events = require('events');
var bleno = require('bleno');

var CHARACTERISTIC_NAME = 'HSV';

var HSVCharacteristic = function(lampState) {
    bleno.Characteristic.call(this, {
        uuid: '0002A7D3-D8A4-4FEA-8174-1736E808C066',
        properties: ['read', 'write', 'notify'],
        descriptors: [
            new bleno.Descriptor({
               uuid: '2901',
               value: CHARACTERISTIC_NAME
            }),
            new bleno.Descriptor({
               uuid: '2904',
               value: Buffer.from([0x04,0x04,0x04])
            }),
        ],
    }
    )

    this.lampState = lampState;

    this._update = null;

    this.changed = function(new_hue, new_saturation) {
        console.log('HSV updated value - need to Notify?');
        if( this._update !== null ){
            var data = Buffer.alloc(2);
            data.writeUInt8(new_hue, 0);
            data.writeUInt8(new_saturation, 1);
            this._update(data);
        }
    }

    this.lampState.on('changed-hsv', this.changed.bind(this));

}

util.inherits(HSVCharacteristic, bleno.Characteristic);

HSVCharacteristic.prototype.onReadRequest = function(offset, callback) {
    console.log('HSV onReadRequest');
    if(offset) {
        callback(this.RESULT_ATTR_NOT_LONG, null);
    }
    else {
        var hsv = Buffer.alloc(3);
        hsv.writeUInt8(this.lampState.hue,0);
        hsv.writeUInt8(this.lampState.saturation,1);
        hsv.writeUInt8(0xFF,2);
        console.log('HSV onReadRequest returning ', hsv);
        callback(this.RESULT_SUCCESS, hsv);
    }
}

HSVCharacteristic.prototype.onWriteRequest = function(data, offset, withoutResponse, callback) {
    if(offset) {
        callback(this.RESULT_ATTR_NOT_LONG);
    }
    else if (data.length !== 3) {
        callback(this.RESULT_INVALID_ATTRIBUTE_LENGTH);
    }
    else {
        var hue = data.readUInt8(0);
        var saturation = data.readUInt8(1);
        
        this.lampState.set_hue_saturation(hue, saturation);
        callback(this.RESULT_SUCCESS);
    }
};

HSVCharacteristic.prototype.onSubscribe = function(maxValueSize, updateValueCallback) {
    console.log('HSV subscribe on ', CHARACTERISTIC_NAME);
    this._update = updateValueCallback;
}

HSVCharacteristic.prototype.onUnsubscribe = function() {
    console.log('HSV unsubscribe on ', CHARACTERISTIC_NAME);
    this._update = null;
}

module.exports = HSVCharacteristic;