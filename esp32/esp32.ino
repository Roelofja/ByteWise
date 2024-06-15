#include <ArduinoJson.h>
#include <WiFi.h>
#include <PubSubClient.h>

/* Your unique ByteWise device token goes here */
#define BYTEWISE_DEVICE_TOKEN "mA2Prw6ZqllC9PXr"

#define MQTT_SERVER "bytewise.cloud.shiftr.io"
#define MQTT_PORT 1883
#define MQTT_USER "bytewise"
#define MQTT_PASS "gDQI0dHuCD0bXwTG"

/* Your WiFi information goes here */
char ssid[] = "NETGEAR61";
char password[] = "pastelapple849";

WiFiClient espClient;
PubSubClient client(espClient);

String clientId; // Unique client ID for this device
String instanceTopic; // Unique app instance topic
String statusTopic; // Unique status/will topic for this device 

String messageRecieved;

void setupWifi();
void setupMqtt();
void messageRecievedCallback(char* topic, byte* payload, unsigned int length);
void reconnect();

// Setup before loop
void setup()
{
    Serial.begin(115200);
    setupWifi();
    setupMqtt();
}

// Main loop 
void loop()
{
    if(!client.connected())
    {
        reconnect();
    }
    client.loop();
}

void setupWifi()
{
    delay(10);
    Serial.println();
    Serial.print("Connecting to ");
    Serial.println(ssid);
    WiFi.begin(ssid, password);
    while(WiFi.status() != WL_CONNECTED)
    {
        delay(500);
        Serial.print(".");
    }
    Serial.println("");
    Serial.println("WiFi connected");
    Serial.println("IP address: ");
    Serial.println(WiFi.localIP());
}

void setupMqtt()
{
    uint64_t chipId = ESP.getEfuseMac(); // ESP32 MAC address

    clientId = "ESP32-" + String(chipId, HEX);
    instanceTopic = "/instances/" BYTEWISE_DEVICE_TOKEN;
    statusTopic = "/devices/" + clientId + "/status";

    client.setServer(MQTT_SERVER, MQTT_PORT);
    client.setCallback(messageRecievedCallback);
    client.setKeepAlive(1);
}

void messageRecievedCallback(char* topic, byte* payload, unsigned int length)
{
    // Parse the JSON message
    JsonDocument config;
    DeserializationError error = deserializeJson(config, payload);
    
    // Check for parsing errors
    if(error)
    {
        Serial.print("deserializeJson() failed: ");
        Serial.println(error.c_str());
        return;
    }

    JsonArray configArray = config["config"];

    for(JsonObject obj : configArray)
    {
        uint8_t gpio = obj["gpio"];
        uint8_t mode = obj["mode"];
        uint8_t output = obj["output"];

        pinMode(gpio, mode);
        Serial.println("Pin " + String(gpio) + " set to " + String(mode));
        if(mode == OUTPUT)
        {
            digitalWrite(gpio, output);
            Serial.println(", Pin " + String(gpio) + " mode set to " + String(output));
        }
    }
}

void reconnect()
{
    while(!client.connected())
    {
        Serial.print("Attempting MQTT connection...");
        if(client.connect(clientId.c_str(), MQTT_USER, MQTT_PASS, 
                          statusTopic.c_str(), 1, false, "0"))
        {
            Serial.println("connected");
            client.subscribe(instanceTopic.c_str());
            client.publish(statusTopic.c_str(), "1", true);
        }
        else
        {
            Serial.print("Failed, rc=");
            Serial.print(client.state());
            Serial.println("Trying again in 5 seconds...");
            delay(5000);
        }
    } 
}
