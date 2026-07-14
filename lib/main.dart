import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HasnaQuantumApp());
}

class HasnaQuantumApp extends StatelessWidget {
  const HasnaQuantumApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hasna Quantum P2P',
      home: const HasnaMainApp(), 
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1F2C34),
        scaffoldBackgroundColor: const Color(0xFF0B141A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A884), 
          brightness: Brightness.dark,
        ),
      ),
    );
  }
}

class HasnaMainApp extends StatefulWidget {
  const HasnaMainApp({Key? key}) : super(key: key);

  @override
  State<HasnaMainApp> createState() => _HasnaMainAppState();
}

class _HasnaMainAppState extends State<HasnaMainApp> {
  // --- STATE CONFIGURATIONS ---
  String myDisplayName = "Kushan";
  String myStatus = "Quantum Master Node 👑";
  int _livePing = 14;
  late Timer _pingTimer;
  bool _viewOnceMode = false;
  bool _globalSecretChatEnabled = false;
  
  String _selectedWallpaper = "Matrix Mesh";
  String _selectedLockType = "none";
  bool _isAppUnlocked = true;

  final Map<String, List<Map<String, dynamic>>> _privateChats = {};
  final List<String> _chatPartners = [];
  final Map<String, String> _contactNames = {};
  String? _activeChatNumber;

  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _msgController = TextEditingController();

  bool _showStickerPanel = false;
  bool _isRecordingVoice = false;
  int _voiceRecordDuration = 0;
  Timer? _voiceTimer;
  final Map<String, bool> _playingVoiceNotes = {};

  final List<String> _stickers = ["🔥", "😎", "💯", "🚀", "😂", "👑", "❤️", "👾", "🥶", "💀"];
  final List<Map<String, String>> _localGifs = [
    {"id": "gif_matrix", "name": "Matrix Rain 📟"},
    {"id": "gif_orbit", "name": "Quantum Atom ⚛️"},
  ];

  @override
  void initState() {
    super.initState();
    _bootInitialNodes();
    _pingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) setState(() { _livePing = 10 + Random().nextInt(6); });
    });
  }

  @override
  void dispose() {
    _pingTimer.cancel();
    _voiceTimer?.cancel();
    _numberController.dispose();
    _msgController.dispose();
    super.dispose();
  }

  void _bootInitialNodes() {
    String p2pNode = "+94 77 P2P MESH";
    _chatPartners.add(p2pNode);
    _contactNames[p2pNode] = "Hasna P2P Free Streamer 📡";
    _privateChats[p2pNode] = [
      {
        'id': 'init_1', 'isMe': false, 'type': 'text',
        'content': 'Welcome Kushan! ⚡\n\n100% Free WebRTC Node Engine Active.\nClick the Camera icon to trigger Real P2P Video Call Stream Layer.',
        'time': '00:00', 'viewOnce': false, 'isViewed': false
      }
    ];
  }

  void _startNewChat(String target) {
    if (target.trim().isEmpty) return;
    setState(() {
      if (!_chatPartners.contains(target)) {
        _chatPartners.insert(0, target);
        _privateChats[target] = [];
      }
      _activeChatNumber = target;
    });
    _numberController.clear();
  }

  void _sendMessage({String type = 'text', String content = ''}) {
    String finalContent = content.isEmpty ? _msgController.text : content;
    if (finalContent.trim().isEmpty && type == 'text' || _activeChatNumber == null) return;

    String msgId = Random().nextInt(100000).toString();
    final now = DateTime.now();
    String timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    setState(() {
      _privateChats[_activeChatNumber!]!.add({
        'id': msgId, 'isMe': true, 'type': type, 'content': finalContent, 'time': timeStr,
        'viewOnce': _viewOnceMode, 'isViewed': false
      });
    });

    if (content.isEmpty) _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: _activeChatNumber == null ? _buildChatList() : _buildChatConversation(),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const Text("Hasna Quantum Hub", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), Text("📡 Node Latency: ${_livePing}ms", style: const TextStyle(fontSize: 10, color: Colors.greenAccent))],
        ),
        backgroundColor: const Color(0xFF1F2C34),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _numberController, decoration: const InputDecoration(hintText: "Enter Node Address...", filled: true, border: InputBorder.none))),
                const SizedBox(width: 8),
                FloatingActionButton(mini: true, backgroundColor: const Color(0xFF00A884), onPressed: () => _startNewChat(_numberController.text), child: const Icon(Icons.add, color: Colors.white))
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _chatPartners.length,
              itemBuilder: (context, i) {
                String num = _chatPartners[i];
                return ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.router, color: Colors.greenAccent)),
                  title: Text(_contactNames[num] ?? num),
                  subtitle: const Text("P2P Direct Mesh Connection Available"),
                  onTap: () => setState(() => _activeChatNumber = num),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChatConversation() {
    var messages = _privateChats[_activeChatNumber!]!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _activeChatNumber = null)),
        title: Text(_contactNames[_activeChatNumber] ?? _activeChatNumber!),
        actions: [
          IconButton(
            icon: Icon(_viewOnceMode ? Icons.visibility_off : Icons.visibility, color: _viewOnceMode ? Colors.amber : Colors.white),
            onPressed: () => setState(() => _viewOnceMode = !_viewOnceMode),
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.greenAccent),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HasnaWebRtcEngineView()));
            },
          )
        ],
      ),
      body: Stack(
        children: [
          if (_selectedWallpaper == "Matrix Mesh") Positioned.fill(child: Opacity(opacity: 0.05, child: CustomPaint(painter: GridWallpaperPainter()))),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    var msg = messages[i]; bool isMe = msg['isMe'];
                    bool viewOnce = msg['viewOnce'] ?? false;
                    bool isViewed = msg['isViewed'] ?? false;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(6), padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: isMe ? const Color(0xFF005C4B) : const Color(0xFF202C33), borderRadius: BorderRadius.circular(12)),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end, spacing: 8,
                          children: [
                            if (viewOnce && !isViewed)
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      content: Text(msg['content']),
                                      actions: [TextButton(onPressed: () { setState(() => msg['isViewed'] = true); Navigator.pop(ctx); }, child: const Text("Destroy Payload"))],
                                    )
                                  );
                                },
                                child: const Text("Open View-Once Snapshot"),
                              )
                            else if (viewOnce && isViewed)
                              const Text("👁 Opened & Purged from Stack", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                            else ...[
                              if (msg['type'] == 'text') Text(msg['content']),
                              if (msg['type'] == 'sticker') Text(msg['content'], style: const TextStyle(fontSize: 38)),
                              if (msg['type'] == 'gif') SizedBox(width: 100, height: 100, child: LocalVectorGif(gifId: msg['content'])),
                            ],
                            Text(msg['time'], style: const TextStyle(fontSize: 9, color: Colors.white60)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_showStickerPanel) _buildDrawer(),
              Container(
                color: const Color(0xFF1F2C34), padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.emoji_emotions, color: Color(0xFF00A884)), onPressed: () => setState(() => _showStickerPanel = !_showStickerPanel)),
                    Expanded(child: TextField(controller: _msgController, decoration: const InputDecoration(hintText: "Type Encrypted Data...", border: InputBorder.none))),
                    IconButton(icon: const Icon(Icons.send, color: Color(0xFF00A884)), onPressed: () => _sendMessage()),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Container(
      height: 180, color: const Color(0xFF121B22),
      child: DefaultTabController(
        length: 2,
        child: Column(children: [
          const TabBar(tabs: [Tab(text: "Stickers"), Tab(text: "Vector GIFs")], indicatorColor: Color(0xFF00A884)),
          Expanded(child: TabBarView(children: [
            GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5), itemCount: _stickers.length, itemBuilder: (context, i) => InkWell(onTap: () => _sendMessage(type: 'sticker', content: _stickers[i]), child: Center(child: Text(_stickers[i], style: const TextStyle(fontSize: 30))))),
            GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.5), itemCount: _localGifs.length, itemBuilder: (context, i) => InkWell(onTap: () => _sendMessage(type: 'gif', content: _localGifs[i]['id']!), child: Container(margin: const EdgeInsets.all(6), color: const Color(0xFF1F2C34), child: Center(child: Text(_localGifs[i]['name']!))))),
          ])),
        ]),
      ),
    );
  }
}

// --- 100% FREE WEBRTC ENGINE CORE CONTROLLER SCREEN ---
class HasnaWebRtcEngineView extends StatefulWidget {
  const HasnaWebRtcEngineView({Key? key}) : super(key: key);
  @override
  State<HasnaWebRtcEngineView> createState() => _HasnaWebRtcEngineViewState();
}

class _HasnaWebRtcEngineViewState extends State<HasnaWebRtcEngineView> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  final Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  @override
  void initState() {
    super.initState();
    _initWebRTC();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _localStream?.dispose();
    _peerConnection?.dispose();
    super.dispose();
  }

  Future<void> _initWebRTC() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    
    await [Permission.camera, Permission.microphone].request();

    final Map<String, dynamic> constraints = {
      'audio': true,
      'video': {'mandatory': {'minWidth': '640', 'minHeight': '480', 'minFrameRate': '30'}, 'facingMode': 'user'}
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    setState(() { _localRenderer.srcObject = _localStream; });

    _peerConnection = await createPeerConnection(_iceConfig);
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        setState(() { _remoteRenderer.srcObject = event.streams[0]; });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _remoteRenderer.srcObject != null ? RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover) : const Center(child: Text("Connecting Free P2P Mesh Layer... 📡"))),
          Positioned(
            right: 20, bottom: 100, width: 110, height: 150,
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.greenAccent, width: 2), borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(borderRadius: BorderRadius.circular(6), child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)),
            ),
          ),
          Positioned(bottom: 30, left: 0, right: 0, child: Center(child: FloatingActionButton(backgroundColor: Colors.redAccent, onPressed: () => Navigator.pop(context), child: const Icon(Icons.call_end, color: Colors.white))))
        ],
      ),
    );
  }
}

// --- MATHEMATIC DRAWERS ---
class LocalVectorGif extends StatefulWidget {
  final String gifId; const LocalVectorGif({Key? key, required this.gifId}) : super(key: key);
  @override
  State<LocalVectorGif> createState() => _LocalVectorGifState();
}
class _LocalVectorGifState extends State<LocalVectorGif> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) { return AnimatedBuilder(animation: _c, builder: (ctx, child) => CustomPaint(painter: QuantumVectorGifPainter(gifId: widget.gifId, progress: _c.value))); }
}

class QuantumVectorGifPainter extends CustomPainter {
  final String gifId; final double progress; QuantumVectorGifPainter({required this.gifId, required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.0..color = Colors.greenAccent;
    if (gifId == "gif_matrix") {
      for (int i = 0; i < 4; i++) {
        double x = size.width * (i / 3);
        double phase = (progress + (i * 0.2)) % 1.0;
        canvas.drawCircle(Offset(x, size.height * phase), 2, paint);
      }
    } else {
      canvas.drawCircle(center, 6, Paint()..color = Colors.greenAccent);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(progress * 2 * pi);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: size.width * 0.8, height: size.height * 0.3), paint);
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class GridWallpaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.greenAccent..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 25) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), p); }
    for (double y = 0; y < size.height; y += 25) { canvas.drawLine(Offset(0, y), Offset(size.width, y), p); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
