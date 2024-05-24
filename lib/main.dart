import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ByteWise MQTT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter MQTT Communication'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  late MqttServerClient _client;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _setupMqtt();
  }

  void _setupMqtt() {
    _client = MqttServerClient('broker.hivemq.com', 'flutter_client');
    _client.logging(on: true);
    _client.keepAlivePeriod = 20;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;
    _client.connect();
  }

  void _onConnected() {
    print('Connected to MQTT broker');
    setState(() {
      _isConnected = true;
    });
    _subscribeToPongTopic();
  }

  void _onDisconnected() {
    print('Disconnected from MQTT broker');
    setState(() {
      _isConnected = false;
    });
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void _incrementCounterAndSendMessage() {
    setState(() {
      _counter++;
    });

    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString('Ping $_counter');

    if (_isConnected) {
      _client.publishMessage(
        'app/ping', // Publish to "ping" topic
        MqttQos.atLeastOnce,
        builder.payload!,
      );
    } else {
      print('Not connected to MQTT broker');
    }
  }

  void _subscribeToPongTopic() {
    _client.subscribe('esp/response', MqttQos.atLeastOnce);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
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
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounterAndSendMessage,
        tooltip: 'Increment and Send Message to ESP32',
        child: const Icon(Icons.add),
      ),
    );
  }
}
