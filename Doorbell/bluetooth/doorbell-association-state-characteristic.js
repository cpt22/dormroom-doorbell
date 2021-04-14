var util = require('util');
var bleno = require('bleno');

var CHARACTERISTIC_NAME = 'Association State';

var DoorbellAssociationStateCharacteristic = function (doorbellState) {
    DoorbellAssociationStateCharacteristic.super_.call(this, {
        uuid: '9772695f-2ca0-4144-af5d-90a86d82ab40',
        properties: ['read', 'write', 'notify'],
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

    this.changed_assoc_state = function(state, code) {
        console.log('doorbellstate changed association state');
        if ( this._update !== null ) {
            console.log('this._update is ', typeof(this._update));
            var data = new Buffer(1);
            console.log("StateL ", state);
            if (state) {
                data.writeUInt8(0x01, 0);
            } else {
                data.writeUInt8(0x00, 0);
            }
            this._update(data);
        }
    }

    this._update = null;
    this.doorbellState = doorbellState;

    this.doorbellState.on('changed-association', this.changed_assoc_state.bind(this))
}

util.inherits(DoorbellAssociationStateCharacteristic, bleno.Characteristic);

DoorbellAssociationStateCharacteristic.prototype.onReadRequest = function(offset, callback) {
    console.log('onReadRequest');
    if (offset) {
        console.log('onReadRequest offset');
        callback(this.RESULT_ATTR_NOT_LONG, null);
    } else {
        var responseData = new Buffer(1);
        if (this.doorbellState.assoc_state) {
            responseData.writeUInt8(0x01, 0);
        } else {
            responseData.writeUInt8(0x00, 0);
        }
        console.log("onReadRequest returning ", responseData);
        callback(this.RESULT_SUCCESS, responseData);
    }
}

DoorbellAssociationStateCharacteristic.prototype.onSubscribe = function(maxValueSize, updateValueCallback) {
    console.log('subscribe on ', CHARACTERISTIC_NAME);
    this._update = updateValueCallback;
}

DoorbellAssociationStateCharacteristic.prototype.onUnsubscribe = function() {
    console.log('unsubscribe on ', CHARACTERISTIC_NAME);
    this._update = null;
}


module.exports = DoorbellAssociationStateCharacteristic;