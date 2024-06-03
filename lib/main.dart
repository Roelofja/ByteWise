import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late MqttServerClient _client;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _setupMqtt();
  }

  void _setupMqtt() {
    _client = MqttServerClient('bytewise.cloud.shiftr.io', 'BW-mA2Prw6ZqllC9PXr');
    _client.port = 1883;
    _client.keepAlivePeriod = 20;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.connect('bytewise', 'gDQI0dHuCD0bXwTG');
  }

  void _onConnected() {
    print('Connected to MQTT broker');
    setState(() {
      _isConnected = true;
    });
  }

  void _onDisconnected() {
    print('Disconnected from MQTT broker');
    setState(() {
      _isConnected = false;
    });
  }

  void _sendMessageToESP32() {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString('Hello from Flutter');
    if (_isConnected) {
      _client.publishMessage('/devices/mA2Prw6ZqllC9PXr', MqttQos.atLeastOnce, builder.payload!);
    } else {
      print('Not connected to MQTT broker');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MQTT Communication'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _isConnected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                color: _isConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendMessageToESP32,
              child: const Text('Send Message to ESP32'),
            ),
          ],
        ),
      ),
    );
  }
}
