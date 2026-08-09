import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Player {
  final int tournamentPlayerID;
  final int tournamentID;
  final String tournamentName;
  final String playerName;
  final String status;

  Player({
    required this.tournamentPlayerID,
    required this.tournamentID,
    required this.tournamentName,
    required this.playerName,
    required this.status,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      tournamentPlayerID: json["tournamentPlayerID"] ?? 0,
      tournamentID: json["tournamentID"] ?? 0,
      tournamentName: json["tournamentName"] ?? "",
      playerName: json["playerName"] ?? "",
      status: json["status"] ?? "",
    );
  }
}

class PlayerApprovalPage extends StatefulWidget {
  const PlayerApprovalPage({super.key});

  @override
  State<PlayerApprovalPage> createState() => _PlayerApprovalPageState();
}

class _PlayerApprovalPageState extends State<PlayerApprovalPage> {
  List<Player> players = [];

  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadPlayers();
  }

  Future<void> loadPlayers() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          "http://bmgtournies.runasp.net/api/TournamentPlayers/Pending",
        ),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          setState(() {
            players = decoded.map((e) => Player.fromJson(e)).toList();
          });
        } else if (decoded is Map) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(decoded["message"] ?? "Invalid response")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error : $e")));
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> updatePlayer(
    int tournamentID,
    int tournamentPlayerID,
    String status,
  ) async {
    try {
      String url = "";

      if (status == "APPROVED") {
        url =
            "http://bmgtournies.runasp.net/api/TournamentPlayers/ApprovePlayer?tournamentID=$tournamentID&tournamentPlayerID=$tournamentPlayerID";
      } else {
        url =
            "http://bmgtournies.runasp.net/api/TournamentPlayers/RejectPlayer?tournamentID=$tournamentID&tournamentPlayerID=$tournamentPlayerID";
      }

      final response = await http.post(Uri.parse(url));

      if (response.statusCode == 200) {
        loadPlayers();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Player $status")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Player Approval"),
        backgroundColor: Colors.black,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : players.isEmpty
          ? const Center(
              child: Text("No Pending Players", style: TextStyle(fontSize: 18)),
            )
          : RefreshIndicator(
              onRefresh: loadPlayers,

              child: ListView.builder(
                itemCount: players.length,

                itemBuilder: (context, index) {
                  final p = players[index];

                  return Card(
                    margin: const EdgeInsets.all(10),

                    elevation: 5,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(12),

                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,

                          backgroundColor: Colors.blue,

                          child: Text(
                            p.playerName.isNotEmpty
                                ? p.playerName[0].toUpperCase()
                                : "?",

                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        title: Text(
                          p.playerName,

                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const SizedBox(height: 5),

                            Text("Tournament : ${p.tournamentName}"),

                            Text("Status : ${p.status}"),
                          ],
                        ),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 32,
                              ),

                              onPressed: () {
                                updatePlayer(
                                  p.tournamentID,
                                  p.tournamentPlayerID,
                                  "APPROVED",
                                );
                              },
                            ),

                            IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.red,
                                size: 32,
                              ),

                              onPressed: () {
                                updatePlayer(
                                  p.tournamentID,
                                  p.tournamentPlayerID,
                                  "REJECTED",
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
