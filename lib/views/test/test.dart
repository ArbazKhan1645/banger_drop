import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Test extends StatefulWidget {
  const Test({super.key});

  @override
  State<Test> createState() => _TestState();
}

class _TestState extends State<Test> {
  late Future<DocumentSnapshot> _bangerFuture;

  @override
  void initState() {
    super.initState();
    _bangerFuture =
        FirebaseFirestore.instance
            .collection('Bangers')
            .doc('1750679798735632')
            .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Banger Detail")),
      body: FutureBuilder<DocumentSnapshot>(
        future: _bangerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Banger not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          // final title = data['title'] ?? 'No Title';
          // final artist = data['artist'] ?? 'Unknown Artist';
          // final imageUrl = data['imageUrl'] ?? '';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('data ${data['id']}')],
            ),
          );
        },
      ),
    );
  }
}
