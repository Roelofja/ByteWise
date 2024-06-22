import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:provider/provider.dart';
import 'package:bytewise/main.dart'; 

// Create a test client to test simulated status updates
final testingClient = MqttServerClient(mqttServer, 'TestingClient');

void simulateStatusMessage(Board board, String payload) async {
  final builder = MqttClientPayloadBuilder();
  builder.addString(payload);
  testingClient.publishMessage('devices/${board.authToken}/status', MqttQos.atLeastOnce, builder.payload!);
}

void main() async{
  // Set up MQTT clients for testing
  setUpAll(() async {
    client.setProtocolV311();
    client.keepAlivePeriod = 20;
    try {
      await client.connect(mqttUser, mqttPass);
    } catch (e) {
      client.disconnect();
    }

  //   testingClient.setProtocolV311();
  //   testingClient.keepAlivePeriod = 20;
  //   try {
  //     await testingClient.connect(mqttUser, mqttPass);
  //   } catch (e) {
  //     testingClient.disconnect();
  //   }
  });

  tearDownAll(() async {
    client.disconnect();
    testingClient.disconnect();
  });

  testWidgets('Test adding and removing boards', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => BoardStatusHandler(),
        child: const ByteWise(),
      ),
    );

    // Verify if the Add Board button is present
    expect(find.text('+ Add Board'), findsOneWidget);

    // Tap the Add Board button
    await tester.tap(find.text('+ Add Board'));
    await tester.pumpAndSettle();

    // Verify if the BoardConfigPage is displayed
    expect(find.text('Create Pin Function'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(
      tester.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundColor,
      equals(const Color(0xFF901616)), // Initial status color
    );

    // Go back to the BoardSelectPage
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Verify if the board is added to the list
    expect(find.textContaining('Board: 1'), findsOneWidget);
    expect(find.textContaining('Token:'), findsOneWidget);

    // Delete the added board
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    // Verify if the board is removed from the list
    expect(find.textContaining('Board: 1'), findsNothing);

    // Clear boards for subsequent tests
    boards.clear();
  });

  testWidgets('Test adding configuration to a board', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => BoardStatusHandler(),
        child: const ByteWise(),
      ),
    );

    // Tap the Add Board button
    await tester.tap(find.text('+ Add Board'));
    await tester.pumpAndSettle();

    // Verify if the BoardConfigPage is displayed
    expect(find.text('Create Pin Function'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(
      tester.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundColor,
      equals(const Color(0xFF901616)), // Initial status color
    );

    // Select GPIO pin and mode
    await tester.tap(find.byType(DropdownMenu<GPIO>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('GPIO1').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownMenu<Mode>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OUTPUT').last);
    await tester.pumpAndSettle();

    // Tap the Apply button
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    // Verify if the configuration is added to the list
    expect(find.textContaining('GPIO: 1, Mode: 3, Output: 1'), findsOneWidget);

    // Clear boards for subsequent tests
    boards.clear();
  });

  testWidgets('Test boards are independent', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => BoardStatusHandler(),
        child: const ByteWise(),
      ),
    );

    // Tap the Add Board button
    await tester.tap(find.text('+ Add Board'));
    await tester.pumpAndSettle();

    // Verify if the BoardConfigPage is displayed and board 1 is created
    expect(find.textContaining('Board: 1'), findsOneWidget);
    expect(find.text('Create Pin Function'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(
      tester.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundColor,
      equals(const Color(0xFF901616)), // Initial status color
    );

    // Add multiple output configurations for board 1
    for (int i = 1; i <= 2; i++) {
      await tester.tap(find.byType(DropdownMenu<GPIO>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('GPIO$i').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownMenu<Mode>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OUTPUT').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
    }

    // Verify if multiple configurations are added to the list
    for (int i = 1; i <= 2; i++) {
      expect(find.textContaining('GPIO: $i, Mode: 3, Output: 1'), findsOneWidget);
    }

    // Create a new board
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Add Board'));
    await tester.pumpAndSettle();

    // Verify if the BoardConfigPage is displayed and board 2 is created
    expect(find.textContaining('Board: 2'), findsOneWidget);
    expect(find.text('Create Pin Function'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(
      tester.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundColor,
      equals(const Color(0xFF901616)), // Initial status color
    );

    // Add multiple input configurations for board 2
    for (int i = 3; i <= 4; i++) {
      await tester.tap(find.byType(DropdownMenu<GPIO>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('GPIO$i').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownMenu<Mode>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('INPUT').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
    }

    // Verify if multiple configurations are added to the list
    for (int i = 3; i <= 4; i++) {
      expect(find.textContaining('GPIO: $i, Mode: 1, Output: 1'), findsOneWidget);
    }

    // Go back to first board
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    
    await tester.tap(find.textContaining('Board: 1'));
    await tester.pumpAndSettle();

    // Verify settings were remebered for board 1
    for (int i = 1; i <= 2; i++) {
      expect(find.textContaining('GPIO: $i, Mode: 3, Output: 1'), findsOneWidget);
    }

    // Clear boards for subsequent tests
    boards.clear();
  });

//   testWidgets('Test board status change on message reception', (WidgetTester tester) async {
//     await tester.pumpWidget(
//       ChangeNotifierProvider(
//         create: (context) => BoardStatusHandler(),
//         child: const ByteWise(),
//       ),
//     );

//     // Tap the Add Board button
//     await tester.tap(find.text('+ Add Board'));
//     await tester.pumpAndSettle();

//     // Verify default status color
//     expect(
//       tester.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundColor,
//       equals(const Color(0xFF901616)), // Initial status color
//     );
//     client.subscribe('devices/${boards.first.authToken}/status', MqttQos.atLeastOnce);

//     simulateStatusMessage(boards.first, '1');
//     await tester.pumpAndSettle();

//     //Verify the status color changes
//     expect(
//       tester.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundColor,
//       equals(const Color(0xFF16906C)), // Status color after receiving '1'
//     );

//     testingClient.disconnect();
//   });
}
