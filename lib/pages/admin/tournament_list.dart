import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

class TournamentListPage extends StatefulWidget {
  const TournamentListPage({super.key});

  @override
  State<TournamentListPage> createState() => _TournamentListPageState();
}

class _TournamentListPageState extends State<TournamentListPage> {
  List<Tournament> tournaments = [];

  List<Tournament> searchedList = [];

  String selectedStatus = "UPCOMING";

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    getTournaments();
  }

  Future<void> getTournaments() async {
    String url = "http://bmgtournies.runasp.net/api/Tournament/TournamentList";

    url += "?status=$selectedStatus";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);

      setState(() {
        tournaments = data.map((e) => Tournament.fromJson(e)).toList();

        searchedList = tournaments;
      });
    }
  }

  void searchTournament(String value) {
    setState(() {
      if (value.isEmpty) {
        searchedList = tournaments;
      } else {
        searchedList = tournaments.where((t) {
          return t.tournamentID.toString().contains(value) ||
              t.tournamentName.toLowerCase().contains(value.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tournament List"),

        backgroundColor: Colors.black,
      ),

      body: Column(
        children: [
          // SEARCH
          Padding(
            padding: const EdgeInsets.all(10),

            child: TextField(
              controller: searchController,

              onChanged: searchTournament,

              decoration: InputDecoration(
                hintText: "Search Tournament ID or Name",

                prefixIcon: const Icon(Icons.search),

                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),

                  onPressed: () {
                    searchController.clear();

                    searchTournament("");
                  },
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          // STATUS BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,

            children: [
              statusButton("UPCOMING"),

              statusButton("ONGOING"),

              statusButton("FINISHED"),
            ],
          ),

          const SizedBox(height: 10),

          Expanded(
            child: searchedList.isEmpty
                ? const Center(child: Text("No Tournament Found"))
                : ListView.builder(
                    itemCount: searchedList.length,

                    itemBuilder: (context, index) {
                      final t = searchedList[index];

                      return tournamentCard(t);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget tournamentCard(Tournament t) {
    return Card(
      margin: const EdgeInsets.all(12),

      elevation: 8,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),

        side: BorderSide(color: statusColor(t.status), width: 2),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: Colors.green.shade50,

                  borderRadius: BorderRadius.circular(15),
                ),

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
            ),

            const Divider(),

            Text(
              t.tournamentName,

              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.sports),

                const SizedBox(width: 5),

                Text("Mode : ${t.tournamentMode}"),
              ],
            ),

            Text("Start : ${t.startDate.substring(0, 10)}"),

            Text("End : ${t.endDate.substring(0, 10)}"),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Text("Players"),

                Text("${t.enrolledPlayers}/${t.userCount}"),
              ],
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

              decoration: BoxDecoration(
                color: statusColor(t.status),

                borderRadius: BorderRadius.circular(20),
              ),

              child: Text(
                t.status,

                style: const TextStyle(
                  color: Colors.white,

                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statusButton(String status) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedStatus == status ? Colors.black : Colors.grey,
      ),

      onPressed: () {
        setState(() {
          selectedStatus = status;
        });

        getTournaments();
      },

      child: Text(status, style: const TextStyle(color: Colors.white)),
    );
  }

  Color statusColor(String status) {
    switch (status) {
      case "UPCOMING":
        return Colors.blue;

      case "ONGOING":
        return Colors.green;

      case "FINISHED":
        return Colors.red;

      default:
        return Colors.grey;
    }
  }
}
