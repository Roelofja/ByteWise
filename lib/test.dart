import 'dart:convert';

void main() {
  // Define the configuration list
  List<Map<String, dynamic>> config = [
    {
      "gpio": 5,
      "mode": 3,
      "output": 1,
    },
    {
      "gpio": 4,
      "mode": 3,
      "output": 1,
    }
  ];

  // Convert the configuration list to a JSON string
  String jsonString = jsonEncode({"config": config});

  // Print the JSON string
  print(jsonString);
}