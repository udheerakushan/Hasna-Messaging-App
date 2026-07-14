import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/webrtc_service.dart';

class CallReceiveScreen extends StatefulWidget {
  const CallReceiveScreen({Key? key}) : super(key: key);

  @override
  State<CallReceiveScreen> createState() => _CallReceiveScreenState();
}

class _CallReceiveScreenState extends State<CallReceiveScreen> {
  final WebRTCService _webrtc = WebRTCService.getOrCreate('placeholder');
  String _offerInput = '';
  String? _answerPackage;
  String _status = '';

  Future<void> _createAnswer() async {
    if (_offerInput.trim().isEmpty) return;
    setState(() => _status = 'Processing offer...');
    try {
      // since we don't have a peerId here, use a temp id 'remote'
      final svc = WebRTCService.getOrCreate('remote');
      final ans = await svc.handleOfferAndCreateAnswerPackage(_offerInput.trim());
      setState(() {
        _answerPackage = ans;
        _status = 'Answer ready. Provide this to the caller.';
      });
    } catch (e) {
      setState(() => _status = 'Failed to create answer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive Offer (Scan/Paste)')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text('Paste the offer (from caller) here or scan the QR using another device and paste the text'),
            TextField(onChanged: (v) => _offerInput = v, maxLines: 4),
            ElevatedButton(onPressed: _createAnswer, child: const Text('Create Answer & Show QR')),
            const SizedBox(height: 12),
            if (_answerPackage != null) ...[
              QrImage(data: _answerPackage!, size: 260.0),
              const SizedBox(height: 8),
              SelectableText(_answerPackage!),
            ],
            const SizedBox(height: 12),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
