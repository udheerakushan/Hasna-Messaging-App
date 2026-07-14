*** Begin Patch
*** Add File: lib/screens/forward.dart
+import 'package:flutter/material.dart';
+
+import '../services/db.dart';
+
+class ForwardScreen extends StatefulWidget {
+  final Map<String, dynamic> message;
+  const ForwardScreen({Key? key, required this.message}) : super(key: key);
+
+  @override
+  State<ForwardScreen> createState() => _ForwardScreenState();
+}
+
+class _ForwardScreenState extends State<ForwardScreen> {
+  List<Map<String, dynamic>> _convs = [];
+  final Set<String> _selected = {};
+
+  @override
+  void initState() {
+    super.initState();
+    _loadConvs();
+  }
+
+  Future<void> _loadConvs() async {
+    final c = await DBService.getConversations();
+    setState(() => _convs = c);
+  }
+
+  Future<void> _forward() async {
+    if (_selected.isEmpty) return;
+    for (final pid in _selected) {
+      final newMsg = Map<String, dynamic>.from(widget.message);
+      newMsg['peer_id'] = pid;
+      newMsg['is_forwarded'] = 1;
+      newMsg['forwarded_from'] = widget.message['peer_id'];
+      // TODO: re-encrypt media for new recipient if needed
+      await DBService.insertMessage(newMsg);
+    }
+    Navigator.of(context).pop(true);
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    return Scaffold(
+      appBar: AppBar(title: const Text('Forward message')),
+      body: Column(
+        children: [
+          Expanded(
+            child: ListView.builder(
+              itemCount: _convs.length,
+              itemBuilder: (context, index) {
+                final c = _convs[index];
+                final pid = c['peer_id'] as String;
+                final checked = _selected.contains(pid);
+                return CheckboxListTile(
+                  title: Text(c['name'] ?? pid),
+                  value: checked,
+                  onChanged: (v) {
+                    setState(() {
+                      if (v == true) _selected.add(pid); else _selected.remove(pid);
+                    });
+                  },
+                );
+              },
+            ),
+          ),
+          ElevatedButton(onPressed: _forward, child: const Text('Forward'))
+        ],
+      ),
+    );
+  }
+}
+
*** End Patch
