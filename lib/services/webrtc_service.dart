import 'dart:convert';
import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _pc;
  MediaStream? localStream;
  final List<RTCIceCandidate> _localCandidates = [];

  Future<void> initLocalStream() async {
    if (localStream != null) return;
    final Map<String, dynamic> mediaConstraints = {'audio': true, 'video': {'facingMode': 'user'}};
    localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    };
    final pc = await createPeerConnection(configuration);
    pc.onIceCandidate = (candidate) {
      if (candidate != null) _localCandidates.add(candidate);
    };
    pc.onIceConnectionState = (state) {
      // handle state if needed
    };
    return pc;
  }

  Future<String> createOfferPackage() async {
    _localCandidates.clear();
    _pc = await _createPeerConnection();
    await initLocalStream();
    if (localStream != null) {
      for (var track in localStream!.getTracks()) {
        await _pc?.addTrack(track, localStream!);
      }
    }

    final offer = await _pc!.createOffer({'offerToReceiveVideo': 1, 'offerToReceiveAudio': 1});
    await _pc!.setLocalDescription(offer);

    // wait a short time for ICE candidates to be gathered
    await Future.delayed(const Duration(seconds: 2));

    final localDesc = await _pc!.getLocalDescription();

    final pack = {
      'sdp': localDesc?.sdp ?? offer.sdp,
      'type': localDesc?.type ?? offer.type,
      'candidates': _localCandidates.map((c) => {'candidate': c.candidate, 'sdpMid': c.sdpMid, 'sdpMLineIndex': c.sdpMlineIndex}).toList()
    };

    return base64UrlEncode(utf8.encode(jsonEncode(pack)));
  }

  Future<String> handleOfferAndCreateAnswerPackage(String offerPackageBase64) async {
    _localCandidates.clear();
    final decoded = jsonDecode(utf8.decode(base64Url.decode(offerPackageBase64)));

    _pc = await _createPeerConnection();
    await initLocalStream();
    if (localStream != null) {
      for (var track in localStream!.getTracks()) {
        await _pc?.addTrack(track, localStream!);
      }
    }

    final offer = RTCSessionDescription(decoded['sdp'], decoded['type']);
    await _pc!.setRemoteDescription(offer);

    // add remote candidates if any
    if (decoded['candidates'] != null) {
      for (var c in decoded['candidates']) {
        try {
          final cand = RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']);
          await _pc!.addCandidate(cand);
        } catch (_) {}
      }
    }

    final answer = await _pc!.createAnswer({'offerToReceiveVideo': 1, 'offerToReceiveAudio': 1});
    await _pc!.setLocalDescription(answer);

    await Future.delayed(const Duration(seconds: 2));
    final localDesc = await _pc!.getLocalDescription();

    final pack = {
      'sdp': localDesc?.sdp ?? answer.sdp,
      'type': localDesc?.type ?? answer.type,
      'candidates': _localCandidates.map((c) => {'candidate': c.candidate, 'sdpMid': c.sdpMid, 'sdpMLineIndex': c.sdpMlineIndex}).toList()
    };

    return base64UrlEncode(utf8.encode(jsonEncode(pack)));
  }

  Future<void> handleAnswerPackage(String answerPackageBase64) async {
    final decoded = jsonDecode(utf8.decode(base64Url.decode(answerPackageBase64)));
    final answer = RTCSessionDescription(decoded['sdp'], decoded['type']);
    await _pc?.setRemoteDescription(answer);

    if (decoded['candidates'] != null) {
      for (var c in decoded['candidates']) {
        try {
          final cand = RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']);
          await _pc?.addCandidate(cand);
        } catch (_) {}
      }
    }
  }

  void dispose() {
    localStream?.dispose();
    _pc?.close();
  }
}
