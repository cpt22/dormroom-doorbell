var events = require('events');
var util = require('util');
var mqtt = require('mqtt');

function DoorbellState() {
    events.EventEmitter.call(this);

    //this.ssid = "";
    //this.psk = "";
    //this.last_attempt = false;
    this.assoc_code = "";
    this.assoc_state = false;
    this.clientId = 'doorbell_bt_peripheral';
    this.has_received_first_update = false;

    var that = this;
    var client_connection_topic = 'doorbell/connection/' + this.clientId + '/state';
    var association_topic = 'doorbell/associated';

    var mqtt_options = {
        clientId: this.clientId,
        'will' : {
            topic: client_connection_topic,
            payload: '0',
            qos: 2,
            retain: true,
        },
    }

    var mqtt_client = mqtt.connect('mqtt://localhost', mqtt_options);

    mqtt_client.on('connect', function() {
        console.log('connected!');
        mqtt_client.publish(client_connection_topic,
            '1', {qos:2, retain:true})
        mqtt_client.subscribe(association_topic);
    });

    mqtt_client.on('message', function(topic, message) {
        console.log('MQTT Message on: ', topic);
        if (topic === association_topic) {
            let new_data = JSON.parse(message);
            console.log(new_data['code'] == that.assoc_code);
            if ( (new_data['associated'] == false && new_data['code'] == that.assoc_code) &&
            new_data['associated'] == that.assoc_state ) {
                console.log("Returning");
                return;
            }

            that.assoc_code = "";
            if( new_data['associated'] === false) {
                that.assoc_state = false;
                that.assoc_code = new_data['code'];
                console.log("Association Code: ", that.assoc_code);
            } else {
                that.assoc_state = true;
                console.log("Associated");
            }
            that.emit('changed-association', that.assoc_state, that.assoc_code);
            that.has_received_first_update = true;
        } else {
            console.log('unknown mqtt topic');
        }
    });

    this.mqtt_client = mqtt_client;
}

util.inherits(DoorbellState, events.EventEmitter);

/*DoorbellState.prototype.set_ssid = function(ssid) {
    console.log("setting ssid: ", ssid);
    this.ssid = ssid;
}

DoorbellState.prototype.set_psk = function(psk) {
    console.log("setting psk: ", psk);
    this.psk = psk;
}

DoorbellState.prototype.join_wifi = function() {
    if (this.ssid != "") {
        var tmp = {'client': this.clientId, 'ssid': this.ssid, 'psk': this.psk}
        this.mqtt_client.publish('doorbell/set_wifi', JSON.stringify(tmp));
        console.log('set wifi data');
        this.last_attempt = true;
        return true;
    } else {
        console.log('missing ssid');
        this.last_attempt = false;
        return false;
    }
}*/

module.exports = DoorbellState;