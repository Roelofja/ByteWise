#include <WiFi.h>
#include <PubSubClient.h>

const char* ssid = "NETGEAR61";
const char* password = "pastelapple849";
const char* mqttServer = "bytewise.cloud.shiftr.io";
const int mqttPort = 1883;
const char* mqttUser = "bytewise";
const char* mqttPassword = "gDQI0dHuCD0bXwTG";

WiFiClient espClient;
PubSubClient client(espClient);

void setup_wifi() {
    delay(10);
    Serial.println();
    Serial.print("Connecting to ");
    Serial.println(ssid);
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("");
    Serial.println("WiFi connected");
    Serial.println("IP address: ");
    Serial.println(WiFi.localIP());
}

void reconnect() {
    while (!client.connected()) {
        Serial.print("Attempting MQTT connection...");
        if (client.connect("ESP32Client", mqttUser, mqttPassword)) {
            Serial.println("connected");
            client.subscribe("esp/send");
        } else {
            Serial.print("failed, rc=");
            Serial.print(client.state());
            Serial.println(" try again in 5 seconds");
            delay(5000);
        }
    }
}

// Setup before loop
void setup() {
    Serial.begin(115200);
    setup_wifi();
    client.setServer(mqttServer, mqttPort);
}

// Main loop 
void loop() {
    if (!client.connected()) {
        reconnect();
    }
    client.loop();
    // Your main code goes here
    if(client.publish("esp/send", "Hello")) {
        Serial.println("Message sent");
    }
    delay(5000);
}
