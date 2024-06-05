import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

typedef Config = List<Map<String, dynamic>>;

enum GPIO {
  gpio1(1),
  gpio2(2),
  gpio3(3),
  gpio4(4),
  gpio5(5),
  gpio12(12),
  gpio13(13),
  gpio14(14),
  gpio15(15),
  gpio16(16),
  gpio17(17),
  gpio18(18),
  gpio19(19),
  gpio21(21),
  gpio22(22),
  gpio23(23),
  gpio25(25),
  gpio26(26),
  gpio27(27),
  gpio32(32),
  gpio33(33),
  gpio34(34),
  gpio35(35),
  gpio36(36),
  gpio39(39);

  const GPIO(this.value);
  final int value;
}

enum Mode {
  input(1),
  output(3);

  const Mode(this.value);
  final int value;
}

Config config = []; // ESP-32 board configuration

final client = MqttServerClient('bytewise.cloud.shiftr.io', 'BW-mA2Prw6ZqllC9PXr');

void main() {
  client.keepAlivePeriod = 20;
  client.onConnected = onConnected;
  client.onDisconnected = onDisconnected;
  client.connect('bytewise', 'gDQI0dHuCD0bXwTG');

  runApp(const ByteWise());
}

void onConnected() {
  print('Connected to MQTT broker');
}

void onDisconnected() {
  print('Disconnected from MQTT broker');
}

class ByteWise extends StatelessWidget {
  const ByteWise({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Inter",
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => BoardConfigPage();
}

class BoardConfigPage extends State<MyHomePage> {
  GPIO? selectedGpio;
  Mode? selectedMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D4963),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Connection Status",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
            SizedBox(
              width: 10,
            ),
            CircleAvatar(
              backgroundColor: Color(0xFF16906C),
              maxRadius: 8,
            )
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Create Pin Function",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              DropdownMenu<GPIO>(
                onSelected: (value) {
                  setState(() {
                    selectedGpio = value;
                  });
                },
                hintText: "Pin",
                width: 400,
                menuHeight: 400,
                textStyle: const TextStyle(
                  color: Color(0xFF828282)
                ),
                inputDecorationTheme: const InputDecorationTheme(
                  hintStyle: TextStyle(
                    color: Color(0xFF828282),
                  ),
                  filled: true,
                  fillColor: Color(0xFF303030),
                  border: InputBorder.none,
                ),
                dropdownMenuEntries: GPIO.values.map<DropdownMenuEntry<GPIO>>((GPIO gpio) {
                  return DropdownMenuEntry<GPIO>(
                    value: gpio,
                    label: gpio.name.toUpperCase(),
                  );
                }).toList(),
              ),
              const SizedBox(
                height: 24,
              ),
              DropdownMenu<Mode>(
                onSelected: (value) {
                  setState(() {
                    selectedMode = value;
                  });
                  print(selectedMode);
                },
                hintText: "Function",
                width: 400,
                menuHeight: 400,
                textStyle: const TextStyle(
                  color: Color(0xFF828282)
                ),
                inputDecorationTheme: const InputDecorationTheme(
                  hintStyle: TextStyle(
                    color: Color(0xFF828282),
                  ),
                  filled: true,
                  fillColor: Color(0xFF303030),
                  border: InputBorder.none
                ),
                dropdownMenuEntries: Mode.values.map<DropdownMenuEntry<Mode>>((Mode mode) {
                  return DropdownMenuEntry<Mode>(
                    value: mode,
                    label: mode.name.toUpperCase(),
                  );
                }).toList(),
              ),
              const SizedBox(
                height: 24,
              ),
              ElevatedButton(
                onPressed: () {
                  if(selectedGpio != null && selectedMode != null) {
                    bool isUnique = config.every((element) =>
                      element['gpio'] != selectedGpio!.value
                    );
                    if(isUnique){
                      setState(() {
                        config.add(
                          {
                            "gpio": selectedGpio?.value,
                            "mode": selectedMode?.value,
                            "output": 1,
                          }
                        );
                      });
                      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
                      final String jsonData = jsonEncode({"config": config});
                      builder.addString(jsonData);
                      client.publishMessage('/devices/mA2Prw6ZqllC9PXr', MqttQos.exactlyOnce, builder.payload!);
                      print(jsonData);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF436C92),
                  minimumSize: const Size(450, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Apply",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
