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

      price1: double.tryParse(json["price1"]?.toString() ?? "0") ?? 0,

      price2: double.tryParse(json["price2"]?.toString() ?? "0") ?? 0,

      price3: double.tryParse(json["price3"]?.toString() ?? "0") ?? 0,

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

  final TextEditingController searchController = TextEditingController();

  bool isLoading = false;

  // Used to prevent multiple start requests
  int? startingTournamentID;

  @override
  void initState() {
    super.initState();

    getTournaments();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // GET TOURNAMENTS
  // ============================================================

  Future<void> getTournaments() async {
    setState(() {
      isLoading = true;
    });

    const baseUrl =
        "https://bmgtournies.runasp.net/api/Tournament/TournamentList";

    final url = "$baseUrl?status=$selectedStatus";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        final List<Tournament> loadedTournaments = data
            .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
            .toList();

        if (!mounted) return;

        setState(() {
          tournaments = loadedTournaments;

          // Re-apply search
          searchTournament(searchController.text);
        });
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to load tournaments. Status: ${response.statusCode}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading tournaments: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void searchTournament(String value) {
    final searchValue = value.trim().toLowerCase();

    setState(() {
      if (searchValue.isEmpty) {
        searchedList = tournaments;
      } else {
        searchedList = tournaments.where((t) {
          return t.tournamentID.toString().contains(searchValue) ||
              t.tournamentName.toLowerCase().contains(searchValue);
        }).toList();
      }
    });
  }

  // ============================================================
  // START TOURNAMENT
  // ============================================================

  Future<void> startTournament(Tournament tournament) async {
    // Prevent duplicate requests
    if (startingTournamentID != null) {
      return;
    }

    setState(() {
      startingTournamentID = tournament.tournamentID;
    });

    final url =
        "https://bmgtournies.runasp.net/api/Tournament/StartTournament/${tournament.tournamentID}";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tournament started successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the list.
        //
        // Since the selected tab is UPCOMING,
        // the tournament should disappear from this list
        // if its status becomes ONGOING.
        await getTournaments();
      } else {
        String message = "Failed to start tournament.";

        try {
          final body = jsonDecode(response.body);

          if (body is Map && body["message"] != null) {
            message = body["message"].toString();
          }
        } catch (_) {
          if (response.body.isNotEmpty) {
            message = response.body;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$message\nStatus: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error starting tournament: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          startingTournamentID = null;
        });
      }
    }
  }

  // ============================================================
  // CONFIRM START
  // ============================================================

  void confirmStartTournament(Tournament tournament) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.play_circle_fill, color: Colors.green),
              SizedBox(width: 8),
              Text("Start Tournament"),
            ],
          ),

          content: Text(
            "Are you sure you want to start "
            "\"${tournament.tournamentName}\"?",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("CANCEL"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),

              onPressed: () {
                Navigator.pop(context);

                startTournament(tournament);
              },

              child: const Text("START"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Tournament List",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),

        backgroundColor: Colors.black,

        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Column(
        children: [
          // ======================================================
          // SEARCH
          // ======================================================
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

                filled: true,

                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // ======================================================
          // STATUS BUTTONS
          // ======================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              children: [
                statusButton("UPCOMING"),

                statusButton("ONGOING"),

                statusButton("FINISHED"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ======================================================
          // TOURNAMENT LIST
          // ======================================================
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : searchedList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 70,
                          color: Colors.grey.shade400,
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          "No Tournament Found",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: getTournaments,

                    child: ListView.builder(
                      itemCount: searchedList.length,

                      itemBuilder: (context, index) {
                        final t = searchedList[index];

                        return tournamentCard(t);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOURNAMENT CARD
  // ============================================================

  Widget tournamentCard(Tournament t) {
    final bool isStarting = startingTournamentID == t.tournamentID;

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
            // ==================================================
            // PRIZE MONEY
            // ==================================================
            Center(
              child: Container(
                width: double.infinity,

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

                    const SizedBox(height: 5),

                    Text(
                      "🥇 ${t.price1}",
                      style: const TextStyle(fontSize: 16),
                    ),

                    Text(
                      "🥈 ${t.price2}",
                      style: const TextStyle(fontSize: 16),
                    ),

                    Text(
                      "🥉 ${t.price3}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            const Divider(),

            // ==================================================
            // TOURNAMENT NAME
            // ==================================================
            Text(
              t.tournamentName,

              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // ==================================================
            // TOURNAMENT ID
            // ==================================================
            Row(
              children: [
                const Icon(Icons.tag, size: 20),

                const SizedBox(width: 5),

                Text("Tournament ID: ${t.tournamentID}"),
              ],
            ),

            const SizedBox(height: 5),

            // ==================================================
            // MODE
            // ==================================================
            Row(
              children: [
                const Icon(Icons.sports, size: 20),

                const SizedBox(width: 5),

                Text("Mode: ${t.tournamentMode}"),
              ],
            ),

            const SizedBox(height: 5),

            // ==================================================
            // START DATE
            // ==================================================
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 20),

                const SizedBox(width: 5),

                Text("Start: ${formatDate(t.startDate)}"),
              ],
            ),

            const SizedBox(height: 5),

            // ==================================================
            // END DATE
            // ==================================================
            Row(
              children: [
                const Icon(Icons.event, size: 20),

                const SizedBox(width: 5),

                Text("End: ${formatDate(t.endDate)}"),
              ],
            ),

            const SizedBox(height: 10),

            // ==================================================
            // PLAYERS
            // ==================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                const Row(
                  children: [
                    Icon(Icons.people, size: 20),

                    SizedBox(width: 5),

                    Text(
                      "Players",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                Text(
                  "${t.enrolledPlayers}/${t.userCount}",

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ==================================================
            // STATUS
            // ==================================================
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

            // ==================================================
            // START BUTTON
            // ==================================================
            if (t.status.toUpperCase() == "UPCOMING") ...[
              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,

                height: 50,

                child: ElevatedButton.icon(
                  icon: isStarting
                      ? const SizedBox(
                          width: 22,
                          height: 22,

                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.play_arrow, color: Colors.white),

                  label: Text(
                    isStarting ? "STARTING..." : "START TOURNAMENT",

                    style: const TextStyle(
                      color: Colors.white,

                      fontWeight: FontWeight.bold,

                      fontSize: 15,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,

                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  onPressed: isStarting
                      ? null
                      : () {
                          confirmStartTournament(t);
                        },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BUTTON
  // ============================================================

  Widget statusButton(String status) {
    final bool selected = selectedStatus == status;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),

        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: selected ? Colors.black : Colors.grey,

            foregroundColor: Colors.white,

            padding: const EdgeInsets.symmetric(vertical: 12),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          onPressed: isLoading
              ? null
              : () {
                  if (selectedStatus == status) {
                    return;
                  }

                  setState(() {
                    selectedStatus = status;
                  });

                  getTournaments();
                },

          child: Text(
            status,
            style: const TextStyle(
              color: Colors.white,

              fontWeight: FontWeight.bold,

              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color statusColor(String status) {
    switch (status.toUpperCase()) {
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

  // ============================================================
  // SAFE DATE FORMAT
  // ============================================================

  String formatDate(String date) {
    if (date.isEmpty) {
      return "-";
    }

    try {
      final parsedDate = DateTime.parse(date);

      final year = parsedDate.year.toString().padLeft(4, "0");

      final month = parsedDate.month.toString().padLeft(2, "0");

      final day = parsedDate.day.toString().padLeft(2, "0");

      return "$year-$month-$day";
    } catch (_) {
      // If API returns an unexpected format,
      // don't crash the app.
      if (date.length >= 10) {
        return date.substring(0, 10);
      }

      return date;
    }
  }
}
