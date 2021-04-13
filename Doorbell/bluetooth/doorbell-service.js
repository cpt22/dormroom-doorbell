var util = require('util');
var bleno = require('bleno');

var DoorbellSSIDCharacteristic = require('./doorbell-ssid-characteristic');
var DoorbellPSKCharacteristic = require('./doorbell-psk-characteristic');
var DoorbellUpdateCredentialsService = require('./doorbell-update-credentials-characteristic');
var DoorbellAssociationStateCharacteristic = require('./doorbell-association-state-characteristic');
var DoorbellAssociationCodeCharacteristic = require('./doorbell-association-code-characteristic');

function DoorbellService(doorbellState) {
    bleno.PrimaryService.call(this, {
        uuid: '9770695f-2ca0-4144-af5d-90a86d82ab40',
        characteristics: [
            new DoorbellSSIDCharacteristic(doorbellState),
            new DoorbellPSKCharacteristic(doorbellState),
            new DoorbellUpdateCredentialsService(doorbellState),
            new DoorbellAssociationStateCharacteristic(doorbellState),
            new DoorbellAssociationCodeCharacteristic(doorbellState),
        ]
    });
}

util.inherits(DoorbellService, bleno.PrimaryService);

module.exports = DoorbellService;