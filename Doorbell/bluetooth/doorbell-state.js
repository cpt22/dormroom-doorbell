var events = require('events');
var util = require('util');
var mqtt = require('mqtt');

function DoorbellState() {
    events.EventEmitter.call(this);

    this.ssid = "";
    this.psk = "";
    this.assoc_code = "";
    this.isAssociated = false;
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
        mqtt_client.subscribe('')
    })

    mqtt_client.on('message', function(topic, message) {
        if (topic === association_topic) {
            let new_data = JSON.parse(message);

            if ( new_data['associated'] != that.isAssociated ||
                (new_data['associated'] == false && new_data['code'] != that.code)) {
                return;
            }

            that.assoc_code = "";
            if( new_data['associated'] == false ) {
                that.isAssociated = false;
                that.assoc_code = new_data['code'];
                console.log("Association Code: ", assoc_code);
            } else {
                that.isAssociated = true;
            }
            that.emit('changed-association', that.isAssociated, that.assoc_code);
            that.has_received_first_update = true;
        } else {
            console.log('unknown mqtt topic');
        }
    });

    this.mqtt_client = mqtt_client;
}

util.inherits(DoorbellState, events.EventEmitter);

DoorbellState.prototype.setSSID = function(ssid) {
    this.ssid = ssid;
}

DoorbellState.prototype.setPSK = function(psk) {
    this.psk = psk;
}

DoorbellState.prototype.joinWiFi = function(button) {
    if (this.ssid != "") {
        var tmp = {'client': this.clientId, 'ssid': this.ssid, 'psk': this.psk}
        this.mqtt_client.publish('doorbell/set_wifi', JSON.stringify(tmp));
        console.log('set wifi data');
    } else {
        console.log('missing ssid');
    }
}

module.exports = DoorbellState;