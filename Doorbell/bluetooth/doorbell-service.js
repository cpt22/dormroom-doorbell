var util = require('util');
var bleno = require('bleno');

var DoorbellAssociationStateCharacteristic = require('./doorbell-association-state-characteristic');
var DoorbellAssociationCodeCharacteristic = require('./doorbell-association-code-characteristic');

function DoorbellService(doorbellState) {
    bleno.PrimaryService.call(this, {
        uuid: '9770695f-2ca0-4144-af5d-90a86d82ab40',
        characteristics: [
            new DoorbellAssociationStateCharacteristic(doorbellState),
            new DoorbellAssociationCodeCharacteristic(doorbellState),
        ]
    });
}

util.inherits(DoorbellService, bleno.PrimaryService);

module.exports = DoorbellService;