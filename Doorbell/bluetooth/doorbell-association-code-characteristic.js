var util = require('util');
var bleno = require('bleno');

var CHARACTERISTIC_NAME = 'Association Code';

var DoorbellAssociationCodeCharacteristic = function (doorbellState) {
    DoorbellAssociationCodeCharacteristic.super_.call(this, {
        uuid: '9771695f-2ca0-4144-af5d-90a86d82ab40',
        properties: ['read', 'notify'],
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

    this.changed_assoc_code = function(state, code) {
        console.log('doorbellstate changed association code');
        if ( this._update !== null ) {
            console.log('this._update is ', typeof(this._update));
            //var data = new Buffer("");
            //if (doorbellState.assoc_state == false) {
              var data = new Buffer(code);
            //}
            this._update(data);
        }
    }

    this.doorbellState = doorbellState;

    this.doorbellState.on('changed-association', this.changed_assoc_code.bind(this))
}

util.inherits(DoorbellAssociationCodeCharacteristic, bleno.Characteristic);

DoorbellAssociationCodeCharacteristic.prototype.onReadRequest = function(offset, callback) {
    console.log('onReadRequest');
    if (offset) {
        console.log('onReadRequest offset');
        callback(this.RESULT_ATTR_NOT_LONG, null);
    } else {
        //var responseData = new Buffer("");
       // if (this.doorbellState.assoc_state == false) {
          var responseData = new Buffer(this.doorbellState.assoc_code);
        //}
        console.log("onReadRequest returning ", responseData);
        callback(this.RESULT_SUCCESS, responseData);
    }
}

DoorbellAssociationCodeCharacteristic.prototype.onSubscribe = function(maxValueSize, updateValueCallback) {
    console.log('subscribe on ', CHARACTERISTIC_NAME);
    this._update = updateValueCallback;
}

DoorbellAssociationCodeCharacteristic.prototype.onUnsubscribe = function() {
    console.log('unsubscribe on ', CHARACTERISTIC_NAME);
    this._update = null;
}

module.exports = DoorbellAssociationCodeCharacteristic;