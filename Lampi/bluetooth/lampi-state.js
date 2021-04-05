var events = require('events');
var util = require('util');
var mqtt = require('mqtt');

const BLUETOOTH_CLIENT_ID = "bluetooth";

function LampiState() {
    events.EventEmitter.call(this);

    this.is_on = true;
    this.brightness = 0xFF;
    this.hue = 0xFF;
    this.saturation = 0xFF;

    var that = this;

    mqtt_client = mqtt.connect('mqtt://localhost');
    mqtt_client.on('connect', function() {
        console.log('connected!');
        mqtt_client.subscribe('lamp/changed');
    });

    mqtt_client.on('message', function(topic, message) {
        new_state = JSON.parse(message);
        console.log('MQTT - NEW UPDATE', new_state);

        if (new_state.client != "bluetooth"){
            console.log('NEW STATE: ', new_state);
            var new_onoff = new_state['on']  ? 0X01 : 0X00;
            var new_brightness = Math.round(new_state['brightness']*0xFF);
            var new_hue = Math.round(new_state['color']['h']*0xFF);
            var new_saturation = Math.round(new_state['color']['s']*0xFF);

            
            if (that.is_on !== new_onoff) {
                that.is_on = new_onoff;
                that.emit('changed-onoff', that.is_on);
            }
            if (that.brightness !== new_brightness) {
                that.brightness = new_brightness;
                that.emit('changed-brightness', that.brightness);
            }
            if (that.hue !== new_hue || that.saturation !== new_saturation) {
                that.hue = new_hue;
                that.saturation = new_saturation;
                that.emit('changed-hsv', that.hue, that.saturation);
            }
        }
    });

    this.mqtt_client = mqtt_client;

    this.mqtt_message = function() {
        var msg =  {'color': {'h': that.hue/256, 's': that.saturation/256},
                   'brightness': that.brightness/256,
                   'on': that.is_on == 0x01,
                   'client': BLUETOOTH_CLIENT_ID};
        that.mqtt_client.publish('lamp/set_config', JSON.stringify(msg));
        console.log('Updated set_config channel: ', msg);
    }
}

util.inherits(LampiState, events.EventEmitter);

LampiState.prototype.set_onoff = function(new_onoff) {
    console.log('BLUETOOTH - NEW ON/OFF');
    if (new_onoff == 0x00 || new_onoff == 0x01){
        this.is_on = new_onoff;
    }
    else {
        console.log("Error, invalid on/off value given")
    }
    this.mqtt_message();
};

LampiState.prototype.set_brightness = function(new_brightness) {
    console.log('BLUETOOTH - NEW BRIGHTNESS');
    this.brightness = new_brightness;
    this.mqtt_message();
};

LampiState.prototype.set_hue_saturation = function(new_hue, new_saturation) {
    console.log('BLUETOOTH - NEW HUE, SATURATION');
    this.hue = new_hue;
    this.saturation = new_saturation;
    this.mqtt_message();
};


module.exports = LampiState;