#include <ArduinoJson.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <SPIFFS.h>

/* Your unique ByteWise device token goes here */
#define BYTEWISE_DEVICE_TOKEN "HOfycXUt"

/* Your WiFi information goes here */
char ssid[] = "NETGEAR61";
char password[] = "pastelapple849";

#define MQTT_SERVER "bytewisetest.cloud.shiftr.io"
#define MQTT_PORT 1883
#define MQTT_USER "bytewisetest"
#define MQTT_PASS "DDTBF09zOgqyk97y"

JsonDocument config; // Locally stored device config variable

WiFiClient espClient;
PubSubClient client(espClient);

String clientId; // Unique client ID for this device
String deviceTopic; // Unique app instance topic
String statusTopic; // Unique status/will topic for this device

void setupWifi();
void setupMqtt();
void messageRecievedCallback(char* topic, byte* payload, unsigned int length);
void reconnect();
void applyConfig(JsonDocument config);
void saveConfigToFile(JsonDocument config);
void loadConfigFromFile(JsonDocument& config);

// Setup before loop
void setup()
{
    Serial.begin(115200);
    if(!SPIFFS.begin(true))
    {
        Serial.println("Failed to mount file system");
        return;
    }
    setupWifi();
    setupMqtt();
    loadConfigFromFile(config);
    applyConfig(config);
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
    Serial.print(ssid);
    WiFi.begin(ssid, password);
    while(WiFi.status() != WL_CONNECTED)
    {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\nWiFi connected");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
}

void setupMqtt()
{
    uint64_t chipId = ESP.getEfuseMac(); // ESP32 MAC address

    clientId = "ESP32-" + String(chipId, HEX);
    deviceTopic = "/devices/" BYTEWISE_DEVICE_TOKEN;
    statusTopic = deviceTopic + "/status";

    client.setServer(MQTT_SERVER, MQTT_PORT);
    client.setCallback(messageRecievedCallback);
    client.setKeepAlive(1);
}

void messageRecievedCallback(char* topic, byte* payload, unsigned int length)
{
    // Parse the JSON message
    DeserializationError error = deserializeJson(config, payload);
    
    // Check for parsing errors
    if(error)
    {
        Serial.print("deserializeJson() failed: ");
        Serial.println(error.c_str());
        return;
    }

    saveConfigToFile(config);
    applyConfig(config);
}

void reconnect()
{
    while(!client.connected())
    {
        Serial.println("Attempting MQTT connection...");
        if(client.connect(clientId.c_str(), MQTT_USER, MQTT_PASS, 
                          statusTopic.c_str(), 1, true, "0"))
        {
            Serial.println("MQTT connected");
            client.subscribe(deviceTopic.c_str());
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

void applyConfig(JsonDocument config)
{
    JsonArray configArray = config["config"];

    for(JsonObject obj : configArray)
    {
        uint8_t gpio = obj["gpio"];
        uint8_t mode = obj["mode"];
        uint8_t output = obj["output"];

        pinMode(gpio, mode);
        Serial.println("Pin " + String(gpio) + " set to mode " + String(mode));
        if(mode == OUTPUT)
        {
            digitalWrite(gpio, output);
            Serial.println("Pin " + String(gpio) + " output set to " + String(output));
        }
    }
}

void saveConfigToFile(JsonDocument config)
{
    File configFile = SPIFFS.open("/config.json", "w");
    if(!configFile)
    {
        Serial.println("Failed to open config file for writing");
        return;
    }

    serializeJson(config, configFile);
    configFile.close();
    Serial.println("Config saved to file");
}

void loadConfigFromFile(JsonDocument& config)
{
    File configFile = SPIFFS.open("/config.json", "r");
    if(!configFile)
    {
        Serial.println("Failed to open config file");
        return;
    }

    DeserializationError error = deserializeJson(config, configFile);
    if(error)
    {
        Serial.print("deserializeJson() failed: ");
        Serial.println(error.c_str());
        return;
    }

    configFile.close();
    Serial.println("Config loaded from file");
}