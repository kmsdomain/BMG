import 'package:flutter/material.dart';

class TournamentTypesPage extends StatelessWidget {
  const TournamentTypesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tournament Types")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: const [
          ListTile(leading: Icon(Icons.sports_soccer), title: Text("Football")),
          ListTile(leading: Icon(Icons.sports_cricket), title: Text("Cricket")),
          ListTile(
            leading: Icon(Icons.sports_basketball),
            title: Text("Basketball"),
          ),
          ListTile(leading: Icon(Icons.sports_tennis), title: Text("Tennis")),
        ],
      ),
    );
  }
}
