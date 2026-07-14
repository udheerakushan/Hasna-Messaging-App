import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/db.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _name = TextEditingController();
  List<Map<String, dynamic>> _convs = [];
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadConvs();
  }

  Future<void> _loadConvs() async {
    final c = await DBService.getConversations();
    setState(() => _convs = c);
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty || _selected.isEmpty) return;
    final id = await DBService.createGroup(_name.text.trim(), _selected.toList());
    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Group name')),
            const SizedBox(height: 12),
            const Text('Select members'),
            Expanded(
              child: ListView.builder(
                itemCount: _convs.length,
                itemBuilder: (context, index) {
                  final c = _convs[index];
                  final pid = c['peer_id'] as String;
                  final checked = _selected.contains(pid);
                  return CheckboxListTile(
                    title: Text(c['name'] ?? pid),
                    value: checked,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) _selected.add(pid); else _selected.remove(pid);
                      });
                    },
                  );
                },
              ),
            ),
            ElevatedButton(onPressed: _create, child: const Text('Create'))
          ],
        ),
      ),
    );
  }
}
