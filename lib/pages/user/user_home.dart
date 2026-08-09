import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'user_tournament_details.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Tournament {
  final int tournamentID;
  final String tournamentName;
  final String tournamentMode;
  final String startDate;
  final String endDate;
  final double price1;
  final double price2;
  final double price3;
  final int enrolledPlayers;
  final int userCount;
  final String status;

  Tournament({
    required this.tournamentID,
    required this.tournamentName,
    required this.tournamentMode,
    required this.startDate,
    required this.endDate,
    required this.price1,
    required this.price2,
    required this.price3,
    required this.enrolledPlayers,
    required this.userCount,
    required this.status,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      tournamentID: json["tournamentID"] ?? 0,
      tournamentName: json["tournamentName"] ?? "",
      tournamentMode: json["tournamentMode"] ?? "",
      startDate: json["tournamentStartDate"] ?? "",
      endDate: json["tournamentEndDate"] ?? "",
      price1: double.tryParse(json["price1"].toString()) ?? 0,
      price2: double.tryParse(json["price2"].toString()) ?? 0,
      price3: double.tryParse(json["price3"].toString()) ?? 0,
      enrolledPlayers: json["enrolledPlayers"] ?? 0,
      userCount: json["userCount"] ?? 0,
      status: json["status"] ?? "",
    );
  }
}

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  List<Tournament> tournaments = [];
  List<Tournament> filtered = [];

  TextEditingController searchController = TextEditingController();

  int playerID = 0;
  String userType = "";

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      playerID = prefs.getInt("playerID") ?? 0;
      userType = prefs.getString("userType") ?? "";
    });
  }

  @override
  void initState() {
    super.initState();
    loadSession();
    loadTournaments();
  }

  Future<void> loadTournaments() async {
    final response = await http.get(
      Uri.parse("http://bmgtournies.runasp.net/api/Tournament/TournamentList"),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);

      setState(() {
        tournaments = data.map((e) => Tournament.fromJson(e)).toList();

        filtered = tournaments;
      });
    }
  }

  void searchTournament(String value) {
    setState(() {
      filtered = tournaments.where((t) {
        return t.tournamentName.toLowerCase().contains(value.toLowerCase()) ||
            t.tournamentID.toString().contains(value);
      }).toList();
    });
  }

  Future<void> joinTournament(int tournamentID) async {
    final prefs = await SharedPreferences.getInstance();

    int? playerID = prefs.getInt("playerID");

    if (playerID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User session expired. Please login again."),
        ),
      );
      return;
    }

    final response = await http.post(
      Uri.parse("http://bmgtournies.runasp.net/api/Tournament/JoinTournament"),

      headers: {"Content-Type": "application/json"},

      body: jsonEncode({"tournamentID": tournamentID, "playerID": playerID}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Join request sent")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tournament App"),

        backgroundColor: Colors.black,
      ),

      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),

              child: Text(
                "User Menu",
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.emoji_events),

              title: const Text("Tournaments"),
            ),

            ListTile(
              leading: const Icon(Icons.list),

              title: const Text("My Requests"),
            ),

            ListTile(
              leading: const Icon(Icons.logout),

              title: const Text("Logout"),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),

            child: TextField(
              controller: searchController,

              decoration: const InputDecoration(
                hintText: "Search Tournament ID or Name",

                prefixIcon: Icon(Icons.search),

                border: OutlineInputBorder(),
              ),

              onChanged: searchTournament,
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("No Tournament Found"))
                : ListView.builder(
                    itemCount: filtered.length,

                    itemBuilder: (context, index) {
                      final t = filtered[index];

                      return Card(
                        margin: const EdgeInsets.all(10),

                        elevation: 6,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),

                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (_) => TournamentDetailsPage(
                                  tournamentID: t.tournamentID,

                                  tournamentName: t.tournamentName,
                                ),
                              ),
                            );
                          },

                          child: Padding(
                            padding: const EdgeInsets.all(15),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Center(
                                  child: Column(
                                    children: [
                                      const Text(
                                        "🏆 PRIZE MONEY",

                                        style: TextStyle(
                                          fontSize: 18,

                                          fontWeight: FontWeight.bold,

                                          color: Colors.green,
                                        ),
                                      ),

                                      Text("🥇 ${t.price1}"),

                                      Text("🥈 ${t.price2}"),

                                      Text("🥉 ${t.price3}"),
                                    ],
                                  ),
                                ),

                                const Divider(),

                                Text(
                                  t.tournamentName,

                                  style: const TextStyle(
                                    fontSize: 22,

                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                Text("Mode : ${t.tournamentMode}"),

                                Text("Start : ${t.startDate.substring(0, 10)}"),

                                Text("End : ${t.endDate.substring(0, 10)}"),

                                Text(
                                  "Players : ${t.enrolledPlayers}/${t.userCount}",
                                ),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,

                                  children: [
                                    Text(
                                      t.status,

                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    if (t.status == "UPCOMING" &&
                                        t.enrolledPlayers < t.userCount)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle,

                                          color: Colors.green,

                                          size: 35,
                                        ),

                                        onPressed: () async {
                                          bool?
                                          confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                "Join Tournament",
                                              ),
                                              content: const Text(
                                                "Have you paid the tournament entry fee?\n\nDo you want to send a join request?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text("No"),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text("Yes"),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            joinTournament(t.tournamentID);
                                          }
                                        },
                                      )
                                    else if (t.enrolledPlayers >= t.userCount)
                                      const Text(
                                        "FULL",

                                        style: TextStyle(
                                          color: Colors.red,

                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
