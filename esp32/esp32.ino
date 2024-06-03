#include <WiFi.h>
#include <PubSubClient.h>

/* Your unique ByteWise device token goes here */
#define BYTEWISE_DEVICE_TOKEN "mA2Prw6ZqllC9PXr"

/* Your WiFi information goes here */
const char ssid[] = "NETGEAR61";
const char password[] = "pastelapple849";
 

const char mqttServer[] = "bytewise.cloud.shiftr.io";
const int mqttPort = 1883;
const char mqttUser[] = "bytewise";
const char mqttPassword[] = "gDQI0dHuCD0bXwTG";

WiFiClient espClient;
PubSubClient client(espClient);

String clientId; // Unique client ID variable
String deviceTopic; // Unique device topic variable

void setupWifi() {
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

void setupMqtt() {
    uint64_t chipId = ESP.getEfuseMac(); // ESP32 MAC address

    clientId = "ESP32-" + String(chipId, HEX);
    deviceTopic = "/devices/" BYTEWISE_DEVICE_TOKEN;

    client.setServer(mqttServer, mqttPort);
    client.setCallback(messageRecievedCallback);
}

void messageRecievedCallback(char* topic, byte* payload, unsigned int length) {
    Serial.print("Message arrived [");
    Serial.print(topic);
    Serial.print("] ");
    for (int i = 0; i < length; i++) {
        Serial.print((char)payload[i]);
    }
    Serial.println();
}

void reconnect() {
    while (!client.connected()) {
        Serial.print("Attempting MQTT connection...");
        if (client.connect(clientId.c_str(), mqttUser, mqttPassword)) {
            Serial.println("connected");
            client.subscribe(deviceTopic.c_str());
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
    setupWifi();
    setupMqtt();
}

// Main loop 
void loop() {
    if (!client.connected()) {
        reconnect();
    }
    client.loop();
    // if(client.publish(byteWiseTopic.c_str(), "Hello")) {
    //     Serial.println("Message sent");
    // }
    // delay(5000);
}
