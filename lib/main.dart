*** Begin Patch
*** Update File: lib/main.dart
@@
   Future<void> _sendMessage() async {
@@
     await DBService.insertMessage(msg);
     setState(() {
       _messages.add(msg);
       _controller.clear();
       _isTyping = false;
     });
@@
     // mark as delivered locally (demo)
     if (id != null) await DBService.updateMessageStatus(id as int, 'delivered');
+
+    // Send message metadata over data channel if connected
+    try {
+      final svc = WebRTCService.getOrCreate(widget.peerId);
+      final payload = jsonEncode({'type': 'message', 'message': msg});
+      await svc.sendData(payload);
+    } catch (_) {}
*** End Patch
