import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_home.dart';

// MODEL
class TournamentType {
  final int id;
  final String name;

  TournamentType({required this.id, required this.name});

  factory TournamentType.fromJson(Map<String, dynamic> json) {
    return TournamentType(
      id: json['tournamentTypeID'],
      name: json['tournamentTypeName'],
    );
  }
}

// PAGE
class CreateTournamentPage extends StatefulWidget {
  const CreateTournamentPage({super.key});

  @override
  State<CreateTournamentPage> createState() => _CreateTournamentPageState();
}

class _CreateTournamentPageState extends State<CreateTournamentPage> {
  List<TournamentType> tournamentTypes = [];

  int? selectedTournamentTypeID;

  TextEditingController tournamentName = TextEditingController();

  TextEditingController startDate = TextEditingController();

  TextEditingController endDate = TextEditingController();

  TextEditingController entryFee = TextEditingController();

  TextEditingController prize1 = TextEditingController();

  TextEditingController prize2 = TextEditingController();

  TextEditingController prize3 = TextEditingController();

  TextEditingController maxPlayers = TextEditingController();

  String? selectedMode;

  final List<String> modes = [
    "normal",
    "knockout",
    "elimination",
    "knockoutwlf",
  ];

  Future<void> selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,

      initialDate: DateTime.now(),

      firstDate: DateTime(2020),

      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        controller.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  void initState() {
    super.initState();

    loadTournamentTypes();
  }

  // GET TOURNAMENT TYPES FROM API

  Future<void> loadTournamentTypes() async {
    try {
      final response = await http.get(
        Uri.parse("https://bmgtournies.runasp.net/api/TournamentTypes"),
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);

        setState(() {
          tournamentTypes = data
              .map((e) => TournamentType.fromJson(e))
              .toList();
        });
        print(tournamentTypes.length);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Tournament"),

        backgroundColor: Colors.black,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: ListView(
          children: [
            // TOURNAMENT TYPE DROPDOWN
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: "Tournament Type",

                border: OutlineInputBorder(),
              ),

              value: selectedTournamentTypeID,

              items: tournamentTypes.map((type) {
                return DropdownMenuItem<int>(
                  value: type.id,

                  child: Text(type.name),
                );
              }).toList(),

              onChanged: (value) {
                setState(() {
                  selectedTournamentTypeID = value;
                });
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Mode",
                border: OutlineInputBorder(),
              ),

              value: selectedMode,

              items: modes.map((mode) {
                return DropdownMenuItem<String>(value: mode, child: Text(mode));
              }).toList(),

              onChanged: (value) {
                setState(() {
                  selectedMode = value;
                });
              },
            ),

            const SizedBox(height: 15),

            TextField(
              controller: tournamentName,

              decoration: const InputDecoration(labelText: "Tournament Name"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: startDate,

              readOnly: true,

              decoration: const InputDecoration(
                labelText: "Tournament Start Date",
                suffixIcon: Icon(Icons.calendar_today),
              ),

              onTap: () {
                selectDate(context, startDate);
              },
            ),

            TextField(
              controller: endDate,

              readOnly: true,

              decoration: const InputDecoration(
                labelText: "Tournament End Date",
                suffixIcon: Icon(Icons.calendar_today),
              ),

              onTap: () {
                selectDate(context, endDate);
              },
            ),

            TextField(
              controller: entryFee,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(labelText: "Registration Fee"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: prize1,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(labelText: "Prize Money 1"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: prize2,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(labelText: "Prize Money 2"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: prize3,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(labelText: "Prize Money 3"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: maxPlayers,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(labelText: "Maximum Players"),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () async {
                try {
                  final response = await http.post(
                    Uri.parse(
                      "https://bmgtournies.runasp.net/api/Tournament/CreateTournament",
                    ),
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode({
                      "TournamentTypeID": selectedTournamentTypeID,
                      "TournamentMode": selectedMode,
                      "TournamentName": tournamentName.text,
                      "TournamentStartDate": startDate.text,
                      "TournamentEndDate": endDate.text,
                      "EntryFee": entryFee.text,
                      "Price1": prize1.text,
                      "Price2": prize2.text,
                      "Price3": prize3.text,
                      "UserCount": maxPlayers.text,
                      "CreatedUser": 1,
                    }),
                  );

                  print("Status Code: ${response.statusCode}");
                  print("Response Body: ${response.body}");

                  if (response.body.isEmpty) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Server returned an empty response."),
                      ),
                    );
                    return;
                  }

                  final data = jsonDecode(response.body);

                  if (!mounted) return;

                  if (data["success"] == true) {
                    await showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text("Success"),
                        content: Text(data["message"]),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );

                    if (!mounted) return;

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminHomePage()),
                      (route) => false,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          data["message"] ?? "Failed to create tournament.",
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },

              child: const Text("Create Tournament"),
            ),
          ],
        ),
      ),
    );
  }
}
