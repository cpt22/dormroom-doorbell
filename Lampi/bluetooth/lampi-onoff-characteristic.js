var util = require('util');
var events = require('events');
var bleno = require('bleno');

var CHARACTERISTIC_NAME = 'On/Off';

var OnOffCharacteristic = function(lampState) {
    bleno.Characteristic.call(this, {
        uuid: '0004A7D3-D8A4-4FEA-8174-1736E808C066',
        properties: ['read', 'write', 'notify'],
        descriptors: [
            new bleno.Descriptor({
               uuid: '2901',
               value: CHARACTERISTIC_NAME
            }),
            new bleno.Descriptor({
               uuid: '2904',
               value: Buffer.from([0x01])
            }),
        ],
    }
    )

    this.lampState = lampState;

    this._update = null;

    this.changed = function(new_value) {
        console.log('On/Off updated value - need to Notify?');
        if( this._update !== null ){
            var data = Buffer.alloc(1);
            data.writeUInt8(new_value, 0);
            this._update(data);
        }
    }

    this.lampState.on('changed-onoff', this.changed.bind(this));

}

util.inherits(OnOffCharacteristic, bleno.Characteristic);

OnOffCharacteristic.prototype.onReadRequest = function(offset, callback) {
    console.log('On/Off onReadRequest');
    if(offset) {
        callback(this.RESULT_ATTR_NOT_LONG, null);
    }
    else {
        var data = Buffer.alloc(1);
        data.writeUInt8(this.lampState.is_on);
        console.log('On/Off onReadRequest returning ', data);
        callback(this.RESULT_SUCCESS, data);
    }
}

OnOffCharacteristic.prototype.onWriteRequest = function(data, offset, withoutResponse, callback) {
    if(offset) {
        callback(this.RESULT_ATTR_NOT_LONG);
    }
    else if (data.length !== 1) {
        callback(this.RESULT_INVALID_ATTRIBUTE_LENGTH);
    }
    else {
        var onoff = data.readUInt8(0);
        this.lampState.set_onoff( onoff);
        callback(this.RESULT_SUCCESS);
    }
};

OnOffCharacteristic.prototype.onSubscribe = function(maxValueSize, updateValueCallback) {
    console.log('On/Off subscribe on ', CHARACTERISTIC_NAME);
    this._update = updateValueCallback;
}

OnOffCharacteristic.prototype.onUnsubscribe = function() {
    console.log('On/Off unsubscribe on ', CHARACTERISTIC_NAME);
    this._update = null;
}

module.exports = OnOffCharacteristic;