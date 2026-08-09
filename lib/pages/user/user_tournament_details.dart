import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TournamentDetailsPage extends StatefulWidget {
  final int tournamentID;
  final String tournamentName;

  const TournamentDetailsPage({
    super.key,
    required this.tournamentID,
    required this.tournamentName,
  });

  @override
  State<TournamentDetailsPage> createState() => _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends State<TournamentDetailsPage> {
  List players = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPlayers();
  }

  Future<void> loadPlayers() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://bmgtournies.runasp.net/api/TournamentPlayers/ByTournament/${widget.tournamentID}",
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          players = jsonDecode(response.body);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int tableCount = players.isEmpty ? 0 : (players.length / 4).ceil();

    return Scaffold(
      appBar: AppBar(title: Text(widget.tournamentName)),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),

              children: [
                Text(
                  widget.tournamentName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Tournament ID : ${widget.tournamentID}",
                  style: const TextStyle(fontSize: 18),
                ),

                const SizedBox(height: 20),

                for (int table = 0; table < tableCount; table++)
                  _buildTable(table),
              ],
            ),
    );
  }

  Widget _buildTable(int tableIndex) {
    int start = tableIndex * 4;

    List tablePlayers = [];

    for (int i = 0; i < 4; i++) {
      if (start + i < players.length) {
        tablePlayers.add(players[start + i]);
      } else {
        tablePlayers.add(null);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 20),

      elevation: 5,

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          children: [
            Text(
              "Table ${tableIndex + 1}",

              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,

              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  Colors.blue.shade100,
                ),

                columns: const [
                  DataColumn(
                    label: Text(
                      "Seat",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  DataColumn(
                    label: Text(
                      "Player",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  DataColumn(
                    label: Text(
                      "Played",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  DataColumn(
                    label: Text(
                      "GF",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  DataColumn(
                    label: Text(
                      "GA",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  DataColumn(
                    label: Text(
                      "Points",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],

                rows: List.generate(4, (index) {
                  final p = tablePlayers[index];

                  return DataRow(
                    cells: [
                      DataCell(Text("${index + 1}")),

                      DataCell(
                        Text(
                          p == null
                              ? "Available"
                              : p["playerName"]?.toString() ?? "-",
                        ),
                      ),

                      DataCell(
                        Text(p == null ? "-" : p["played"]?.toString() ?? "0"),
                      ),

                      DataCell(
                        Text(
                          p == null ? "-" : p["goalsFor"]?.toString() ?? "0",
                        ),
                      ),

                      DataCell(
                        Text(
                          p == null
                              ? "-"
                              : p["goalsAgainst"]?.toString() ?? "0",
                        ),
                      ),

                      DataCell(
                        Text(p == null ? "-" : p["points"]?.toString() ?? "0"),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
