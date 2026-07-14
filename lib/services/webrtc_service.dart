import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  static final Map<String, WebRTCService> _instances = {};

  final String peerId;
  RTCPeerConnection? _pc;
  RTCDataChannel? _dc;
  final List<RTCIceCandidate> _localCandidates = [];
  final StreamController<String> _inController = StreamController.broadcast();
  final List<String> _sendQueue = [];

  WebRTCService._(this.peerId);

  static WebRTCService getOrCreate(String peerId) {
    return _instances.putIfAbsent(peerId, () => WebRTCService._(peerId));
  }

  Stream<String> get onMessage => _inController.stream;

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

  Future<String> createOfferPackage({bool withDataChannel = true}) async {
    _localCandidates.clear();
    _pc = await _createPeerConnection();

    if (withDataChannel) {
      _dc = await _pc!.createDataChannel('hasna-data', RTCDataChannelInit());
      _dc?.onMessage = (e) {
        if (e != null && e.text != null) _inController.add(e.text!);
      };
      _dc?.onDataChannelState = (s) {
        if (s == RTCDataChannelState.RTCDataChannelOpen) {
          // flush queue
          for (final m in _sendQueue) {
            _dc?.send(RTCDataChannelMessage(m));
          }
          _sendQueue.clear();
        }
      };
    }

    final offer = await _pc!.createOffer({'offerToReceiveVideo': 1, 'offerToReceiveAudio': 1});
    await _pc!.setLocalDescription(offer);

    // wait a short time for ICE candidates to be gathered
    await Future.delayed(const Duration(seconds: 2));

    final localDesc = await _pc!.getLocalDescription();

    final pack = {
      'sdp': localDesc?.sdp ?? offer.sdp,
      'type': localDesc?.type ?? offer.type,
      'candidates': _localCandidates.map((c) => {
        'candidate': c.candidate,
        'sdpMid': c.sdpMid,
        'sdpMLineIndex': c.sdpMLineIndex
      }).toList()
    };

    return base64UrlEncode(utf8.encode(jsonEncode(pack)));
  }

  Future<String> handleOfferAndCreateAnswerPackage(String offerPackageBase64, {bool withDataChannel = true}) async {
    _localCandidates.clear();
    final decoded = jsonDecode(utf8.decode(base64Url.decode(offerPackageBase64)));

    _pc = await _createPeerConnection();

    if (withDataChannel) {
      _pc!.onDataChannel = (dc) {
        _dc = dc;
        _dc?.onMessage = (e) {
          if (e != null && e.text != null) _inController.add(e.text!);
        };
      };
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
      'candidates': _localCandidates.map((c) => {
        'candidate': c.candidate,
        'sdpMid': c.sdpMid,
        'sdpMLineIndex': c.sdpMLineIndex
      }).toList()
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

  Future<void> sendData(String text) async {
    if (_dc != null && _dc!.state == RTCDataChannelState.RTCDataChannelOpen) {
      _dc!.send(RTCDataChannelMessage(text));
    } else {
      // queue until channel opens
      _sendQueue.add(text);
    }
  }

  void dispose() {
    _inController.close();
    _dc?.close();
    _pc?.close();
    _instances.remove(peerId);
  }
}
