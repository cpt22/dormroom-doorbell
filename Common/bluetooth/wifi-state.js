var events = require('events');
var util = require('util');
var mqtt = require('mqtt');

function WifiState() {
    events.EventEmitter.call(this);

    this.ssid = "";
    this.psk = "";
    this.last_attempt = false;

    this.clientId = 'wifi_bt_peripheral';
    this.has_received_first_update;

    var that = this;
    var client_connection_topic = 'wifi/connection/' + this.clientId + '/state';
    this.wifi_publish_topic = 'wifi/set_config';
    this.wifi_subscribe_topic = 'wifi/response';

    var mqtt_options = {
        clientID: this.clientID,
        'will' : {
            topic: client_connection_topic,
            payload: '0',
            qos: 2,
            retain: true,
        },
    }

    var mqtt_client = mqtt.connect('mqtt://localhost', mqtt_options);

    mqtt_client.on('connect', function() {
        console.log("Connected to mqtt broker!")
        mqtt_client.publish(client_connection_topic,
            '1', {qos:2, retain:true})
        //mqtt_client.subscribe(wifi_subscribe_topic);
    });

    //mqtt_client.on('message', function(topic, message) {
    //    console.log("MQTT Message: ", topic, message);
    //});

    this.mqtt_client = mqtt_client;
}

util.inherits(WifiState, events.EventEmitter);

WifiState.prototype.set_ssid = function(ssid) {
    console.log("Setting state ssid to: ", ssid);
    this.ssid = ssid;
}

WifiState.prototype.set_psk = function(psk) {
    console.log("Setting state psk to: ", psk);
    this.psk = psk;
}

WifiState.prototype.join_wifi = function() {
    if (this.ssid != "") {
        var tmp = {'client' : this.clientId, 'ssid' : this.ssid}
        if (this.psk != "") {
            tmp['psk'] = this.psk;
        }
        this.mqtt_client.publish(this.wifi_publish_topic, JSON.stringify(tmp), {qos:1});
        console.log("Set wifi data");
        this.last_attempt = true;
        return true;
    } else {
        console.log("Missing SSID");
        this.last_attempt = false;
        return false;
    }
}

module.exports = WifiState;