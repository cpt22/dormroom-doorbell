var util = require('util');
var events = require('events');

function lampState() {
    // our state variable
    this.value = 0;
}

util.inherits(lampState, events.EventEmitter);

lampState.prototype.set_value = function(new_value) {
    if( this.value !== new_value) {
        this.value = new_value % 256;
        this.emit('lampState changed', this.value);
    }
};


module.exports = lampState;
