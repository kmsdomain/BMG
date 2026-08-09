import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reports")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: const [
            Card(
              child: ListTile(
                leading: Icon(Icons.emoji_events),
                title: Text("Total Tournaments"),
                trailing: Text("12"),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.people),
                title: Text("Registered Players"),
                trailing: Text("84"),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.pending),
                title: Text("Pending Approvals"),
                trailing: Text("9"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
