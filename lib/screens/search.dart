import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../services/db.dart';
import '../services/key_storage.dart';
import '../services/crypto.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _q = TextEditingController();
  List<Map<String, dynamic>> _results = [];

  Future<void> _doSearch() async {
    final query = _q.text.trim();
    if (query.isEmpty) return;
    // naive search over DB content; decrypting image/text not attempted here for encrypted blobs
    final rows = await DBService.searchMessages(query);
    setState(() => _results = rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search messages')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(controller: _q, decoration: const InputDecoration(labelText: 'Search'), onSubmitted: (_) => _doSearch()),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _doSearch, child: const Text('Search')),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final r = _results[index];
                  return ListTile(
                    title: Text(r['content'] ?? ''),
                    subtitle: Text('${r['peer_id']} • ${r['timestamp']}'),
                    onTap: () {
                      // open conversation (not implemented: navigate to chat with peer)
                      Navigator.of(context).pop();
                      // In a full app we'd navigate to the chat screen and scroll to message
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
