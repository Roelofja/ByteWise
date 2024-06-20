import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:math';
import 'package:provider/provider.dart';

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

class Board {
  static int idCounter = 0;

  final int id = ++idCounter;
  final String authToken = generateUniqueToken(8);
  Config config = []; // ESP-32 board configuration
  Color statusColor = const Color(0xFF901616);
}

class BoardStatusHandler with ChangeNotifier {

  void listenForStatus(Board board) {
    print("Created");
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
      final MqttReceivedMessage<MqttMessage?> message = messages![0];
      final topic = message.topic;

      if(topic == 'devices/${board.authToken}/status') {
        final pubMessage = message.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(pubMessage.payload.message);
        if(payload.isNotEmpty) {
          if(payload == '1') {
            board.statusColor = const Color(0xFF16906C);
          } else {
            board.statusColor = const Color(0xFF901616);
          }
          notifyListeners();
        }
        print(payload);
      }
    });
  }
}

const String mqttServer = "bytewisetest.cloud.shiftr.io";
const String mqttUser = "bytewisetest";
const String mqttPass = "DDTBF09zOgqyk97y";

List<Board> boards = []; // List of added boards

final client = MqttServerClient(mqttServer, 'BW-${generateUniqueToken(16)}');

const String tokenChars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

void onConnected() {
  print('Connected to MQTT broker');
}

void onDisconnected() {
  print('Disconnected from MQTT broker');
}

String generateUniqueToken(int length) {
  Random r = Random.secure();
  return String.fromCharCodes(Iterable.generate(
    length, (_) => tokenChars.codeUnitAt(r.nextInt(tokenChars.length))
  ));
}

void main() async {
  client.setProtocolV311(); // Needed or shiftr MQTT breaks on unsubscribe
  client.keepAlivePeriod = 20;
  client.onConnected = onConnected;
  client.onDisconnected = onDisconnected;

  try {
    await client.connect(mqttUser, mqttPass);
  } catch(e) {
    print('Exception: $e');
    client.disconnect();
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => BoardStatusHandler(),
      child: const ByteWise(),
    )
  );
}

// App Building //

class ByteWise extends StatelessWidget {
  const ByteWise({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const BoardSelectPage(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Inter",
      ),
    );
  }
}

class BoardSelectPage extends StatefulWidget {
  const BoardSelectPage({super.key});

  @override
  State<BoardSelectPage> createState() => BoardSelectState();
}

class BoardSelectState extends State<BoardSelectPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF2D4963),
        title: Image.asset(
          "images/logo_text_plain.png",
          height: 25,
        )
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: boards.length,
                  itemBuilder: (BuildContext context, int index) {
                    final board = boards[index];
                    return ListTile(
                      title: Text(
                        "Board: ${board.id}\nToken: ${board.authToken}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red
                        ),
                        onPressed: () {
                          setState(() {
                            client.unsubscribe('devices/${board.authToken}/status');
                            boards.removeAt(index);
                          });
                        },
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => BoardConfigPage(board: board)),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              const Divider(),
              const SizedBox(
                height: 24,
              ),
              ElevatedButton(
                onPressed: () async {
                  Board board = Board();
                  client.subscribe('devices/${board.authToken}/status', MqttQos.atLeastOnce);
                  var handler = context.read<BoardStatusHandler>();
                  handler.listenForStatus(board);
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BoardConfigPage(board: board)
                    ),
                  );
                  setState(() {
                    boards.add(board);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF436C92),
                  minimumSize: const Size(450, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "+ Add Board",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ]
          )
        )
      )
    );
  }
}

class BoardConfigPage extends StatefulWidget {

  final Board board;
  const BoardConfigPage({super.key, required this.board});

  @override
  State<BoardConfigPage> createState() => BoardConfigState();
}

class BoardConfigState extends State<BoardConfigPage> {
  GPIO? selectedGpio;
  Mode? selectedMode;

  void addConfig(String authToken) {
    if(selectedGpio != null && selectedMode != null) {
      bool isUnique = widget.board.config.every((element) =>
        element['gpio'] != selectedGpio!.value
      );
      if(isUnique){
        widget.board.config.add(
          {
            "gpio": selectedGpio!.value,
            "mode": selectedMode!.value,
            "output": 1,
          }
        );
        sendConfig(authToken);
      }
    }
  }

  void sendConfig(String authToken) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    final String jsonData = jsonEncode({"config": widget.board.config});
    builder.addString(jsonData);
    client.publishMessage('/devices/$authToken', MqttQos.atLeastOnce, builder.payload!);
    print(jsonData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D4963),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Connection Status",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Consumer<BoardStatusHandler>(
              builder: (context, status, child) => CircleAvatar(
                backgroundColor: widget.board.statusColor,
                maxRadius: 8,
              )
            )
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "Board: ${widget.board.id}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    "Token: ${widget.board.authToken}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
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
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF303030),
                ),
                child: DropdownMenu<GPIO>(
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
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(15)
                  ),
                  dropdownMenuEntries: GPIO.values.map<DropdownMenuEntry<GPIO>>((GPIO gpio) {
                    return DropdownMenuEntry<GPIO>(
                      value: gpio,
                      label: gpio.name.toUpperCase(),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF303030),
                ),
                child: DropdownMenu<Mode>(
                  onSelected: (value) {
                    setState(() {
                      selectedMode = value;
                    });
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
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(15),
                  ),
                  dropdownMenuEntries: Mode.values.map<DropdownMenuEntry<Mode>>((Mode mode) {
                    return DropdownMenuEntry<Mode>(
                      value: mode,
                      label: mode.name.toUpperCase(),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    addConfig(widget.board.authToken);
                  });
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
              const SizedBox(
                height: 24,
              ),
              const Divider(),
              const SizedBox(
                height: 24,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.board.config.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> item = widget.board.config[index];
                    return ListTile(
                      title: Text(
                        'GPIO: ${item["gpio"]}, Mode: ${item["mode"]}, Output: ${item["output"]}',
                        style: const TextStyle(
                          color: Colors.white
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red
                        ),
                        onPressed: () {
                          setState(() {
                            widget.board.config.removeAt(index);
                            sendConfig(widget.board.authToken);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
