import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/webrtc_service.dart';

class CallOfferScreen extends StatefulWidget {
  final String peerId;
  const CallOfferScreen({Key? key, required this.peerId}) : super(key: key);

  @override
  State<CallOfferScreen> createState() => _CallOfferScreenState();
}

class _CallOfferScreenState extends State<CallOfferScreen> {
  final WebRTCService _webrtc = WebRTCService();
  String? _offerPackage;
  String _answerInput = '';
  String _status = '';

  Future<void> _createOffer() async {
    setState(() {
      _status = 'Creating offer...';
    });
    final pack = await _webrtc.createOfferPackage();
    setState(() {
      _offerPackage = pack;
      _status = 'Offer ready. Share via QR or copy text and ask peer to provide an answer.';
    });
  }

  Future<void> _submitAnswer() async {
    if (_answerInput.trim().isEmpty) return;
    setState(() => _status = 'Applying answer...');
    try {
      await _webrtc.handleAnswerPackage(_answerInput.trim());
      setState(() => _status = 'Call connected (if NAT allows).');
    } catch (e) {
      setState(() => _status = 'Failed to apply answer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start Call (Share Offer)')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ElevatedButton(onPressed: _createOffer, child: const Text('Create Offer & Show QR')),
            const SizedBox(height: 12),
            if (_offerPackage != null) ...[
              QrImage(data: _offerPackage!, size: 260.0),
              const SizedBox(height: 8),
              SelectableText(_offerPackage!),
            ],
            const SizedBox(height: 12),
            const Text('Paste the answer from the callee here:'),
            TextField(onChanged: (v) => _answerInput = v, maxLines: 3),
            ElevatedButton(onPressed: _submitAnswer, child: const Text('Apply Answer')),
            const SizedBox(height: 12),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
