/**
 * @file esp32.ino
 *
 * @brief ESP-32 ByteWise code. This code must be uploaded to a ESP-32
 * to communicate with the ByteWise application.
 *
 * @authors Jayden Roelofs, Chris Lamus
 * 
 */

#include <ArduinoJson.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <SPIFFS.h>

/* Your unique ByteWise device token goes here */
#define BYTEWISE_DEVICE_TOKEN "######"

/* Your WiFi information goes here */
char ssid[] = "YourSSID";
char password[] = "YourPassword";

#define MQTT_SERVER "bytewise.cloud.shiftr.io"
#define MQTT_PORT 1883
#define MQTT_USER "bytewise"
#define MQTT_PASS "gDQI0dHuCD0bXwTG"

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

/**
 * The code run on startup
 *
 * Sets up the SPIFFS filesystem, connects to wifi, sets up MQTT
 * connection, loads the stored configuration file, and applies
 * the config file.
 * 
 */
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

/**
 * The code run continuously
 *
 * connects to the MQTT broker and handles disconnects
 * 
 */
void loop()
{
    if(!client.connected())
    {
        reconnect();
    }
    client.loop();
}

/**
 * Connects the board to wifi
 *
 * Connects to a wif network using the ssid and password
 * entered at the top of the program
 * 
 */
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

/**
 * Sets up configs for the ByteWise MQTT broker
 *
 * Creates a unique client ID from the board's MAC address.
 * Configures the client to connect to the ByeWise MQTT broker.
 * Creates unique topics for the ByteWise app to communicate over,
 * and sets up message recieved callback and keep alive period.
 * 
 */
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

/**
 * The function called whenever a message is recieved from the broker
 *
 * Parses the incomming json string and converts it to useable data.
 * Saves the config to a json file on the filesystem and then applies it
 * to the board.
 * 
 */
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

/**
 * Connects and reconnects to the MQTT broker
 *
 * Connects to the broker when there is no connection.
 * Establishes the will message when the board is diconnected and
 * sends a message on connection to notify the app that the board is
 * online.
 * 
 */
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

/**
 * Applies a json configuration
 *
 * Loops through each pin configuration and applies each setting of
 * the JsonDocument.
 * 
 */
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

/**
 * Converts a config to a json document and stores it on the ESP
 *
 * Creates a json file if there is not one already puts the JsonDocument
 * contents inside.
 * 
 */
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

/**
 * Load the config stored on the SPIFFS json and apply the settings
 *
 * Loads the config from the SPIFFS json, desearializes it, and stores it
 * into the config JsonDocument to use throughout the program.
 * 
 */
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