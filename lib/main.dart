import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'services/key_storage.dart';
import 'services/crypto.dart';
import 'services/db.dart';
import 'screens/account_setup.dart';
import 'screens/settings.dart';
import 'widgets/verified_badge.dart';
import 'screens/call_offer.dart';
import 'screens/call_receive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KeyStorage.init();
  await DBService.init();
  runApp(const HasnaApp());
}

class HasnaApp extends StatefulWidget {
  const HasnaApp({Key? key}) : super(key: key);

  @override
  State<HasnaApp> createState() => _HasnaAppState();
}

class _HasnaAppState extends State<HasnaApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final t = await KeyStorage.getThemeMode();
    setState(() => _themeMode = t);
  }

  void _updateTheme(ThemeMode mode) async {
    await KeyStorage.setThemeMode(mode);
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hasna',
      theme: ThemeData.light().copyWith(primaryColor: Colors.indigo),
      darkTheme: ThemeData.dark().copyWith(primaryColor: Colors.indigo),
      themeMode: _themeMode,
      home: RootRouter(onThemeChanged: _updateTheme),
    );
  }
}

class RootRouter extends StatefulWidget {
  final void Function(ThemeMode) onThemeChanged;
  const RootRouter({Key? key, required this.onThemeChanged}) : super(key: key);

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  bool _hasAccount = false;

  @override
  void initState() {
    super.initState();
    _checkAccount();
  }

  Future<void> _checkAccount() async {
    final exists = await KeyStorage.hasKeyPair();
    setState(() => _hasAccount = exists);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAccount) return const AccountSetupScreen();
    return HomePage(onThemeChanged: widget.onThemeChanged);
  }
}

class HomePage extends StatefulWidget {
  final void Function(ThemeMode) onThemeChanged;
  const HomePage({Key? key, required this.onThemeChanged}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    ChatsPage(),
    ContactsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final mode = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen()));
              if (mode is ThemeMode) widget.onThemeChanged(mode);
            },
          )
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Contacts',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.call),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CallOfferScreen(peerId: '1')));
        },
      ),
    );
  }
}

class ChatsPage extends StatefulWidget {
  const ChatsPage({Key? key}) : super(key: key);

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final convs = await DBService.getConversations();
    setState(() => _conversations = convs);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _conversations.isEmpty ? 1 : _conversations.length,
      itemBuilder: (context, index) {
        if (_conversations.isEmpty) {
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.help)),
            title: Row(children: [const Text('Hasna Help'), const SizedBox(width: 6), VerifiedBadge()]),
            subtitle: const Text('Official Hasna help bot'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatScreen(peerName: 'Hasna Help', peerId: '1'),
              ));
            },
          );
        }
        final conv = _conversations[index];
        return ListTile(
          title: Row(children: [Text(conv['name']), const SizedBox(width: 6), if (conv['verified'] == 1) VerifiedBadge()]),
          subtitle: Text(conv['last_message'] ?? ''),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(peerName: conv['name'], peerId: conv['peer_id'].toString())));
          },
        );
      },
    );
  }
}

class ContactsPage extends StatefulWidget {
  const ContactsPage({Key? key}) : super(key: key);

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final contacts = <Map<String, String>>[];

  @override
  void initState() {
    super.initState();
    _loadHelpContact();
  }

  void _loadHelpContact() {
    contacts.add({'id': '1', 'name': 'Hasna Help', 'code': 'HASNA-HELP-0001'});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) => ListTile(
              title: Row(children: [Text(contacts[index]['name']!), const SizedBox(width:6), VerifiedBadge()]),
              subtitle: Text(contacts[index]['code']!),
              trailing: const Icon(Icons.chat),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(peerName: contacts[index]['name']!, peerId: contacts[index]['id']!))),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.qr_code),
            label: const Text('Add by QR / Code'),
            onPressed: () async {
              final me = await KeyStorage.getProfile();
              showModalBottomSheet(context: context, builder: (_) => SizedBox(
                height: 360,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text('Share your contact code with others'),
                    const SizedBox(height: 12),
                    QrImage(
                      data: me['contact_code']!,
                      version: QrVersions.auto,
                      size: 220.0,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(me['contact_code']!),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close), label: const Text('Close'))
                  ],
                ),
              ));
            },
          ),
        )
      ],
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String peerName;
  final String peerId;

  const ChatScreen({Key? key, required this.peerName, required this.peerId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false; // local typing
  bool _peerTyping = false; // remote typing indicator
  Timer? _botTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // mark as read when opening
    DBService.markMessagesRead(widget.peerId);
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final msgs = await DBService.getMessagesForPeer(widget.peerId);
    setState(() {
      _messages.clear();
      _messages.addAll(msgs);
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final me = await KeyStorage.getProfile();
    final peerPublic = await KeyStorage.getPublicKeyFor(widget.peerId);
    final encrypted = peerPublic != null ? await CryptoService.encrypt(peerPublic, me['private']!, text) : text;

    final msg = {
      'peer_id': widget.peerId,
      'sender': 'me',
      'content': encrypted,
      'type': 'text',
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'sent'
    };

    final id = await DBService._db?.insert('messages', msg);
    await DBService.insertMessage(msg);
    setState(() {
      _messages.add(msg);
      _controller.clear();
      _isTyping = false;
    });

    // mark as delivered locally (demo)
    if (id != null) await DBService.updateMessageStatus(id as int, 'delivered');

    // If chatting with the official Hasna Help bot, simulate typing and a canned reply
    if (widget.peerId == '1') {
      setState(() => _peerTyping = true);
      _botTimer?.cancel();
      _botTimer = Timer(const Duration(milliseconds: 900), () async {
        final reply = {
          'peer_id': widget.peerId,
          'sender': 'them',
          'content': 'Hello! This is Hasna Help. How can I assist you?',
          'type': 'text',
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'delivered'
        };
        await DBService.insertMessage(reply);
        setState(() {
          _peerTyping = false;
          _messages.add(reply);
        });
      });
    }
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final docs = await getApplicationDocumentsDirectory();
    final file = File('${docs.path}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}');
    await file.writeAsBytes(bytes);

    // For demo, we store local file path. For real E2EE, encrypt bytes and send via P2P.
    final msg = {
      'peer_id': widget.peerId,
      'sender': 'me',
      'content': file.path,
      'type': 'image',
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'sent'
    };

    await DBService.insertMessage(msg);
    setState(() => _messages.add(msg));
  }

  Future<void> _addReaction(int msgIndex) async {
    final msg = _messages[msgIndex];
    final reactions = ['❤️', '👍', '😂', '😮', '😢', '😡'];
    final choice = await showModalBottomSheet<String>(context: context, builder: (_) {
      return GridView.count(
        crossAxisCount: 6,
        children: reactions.map((r) => InkWell(onTap: () => Navigator.of(context).pop(r), child: Center(child: Text(r, style: const TextStyle(fontSize: 24))))).toList(),
      );
    });
    if (choice != null) {
      final idRes = await DBService._db?.rawQuery('SELECT id FROM messages WHERE timestamp=? AND peer_id=?', [msg['timestamp'], msg['peer_id']]);
      int? id;
      if (idRes != null && idRes.isNotEmpty) id = idRes.first['id'] as int?;
      if (id != null) await DBService.addReaction(id, choice);
      setState(() {
        _messages[msgIndex]['reaction'] = choice;
      });
    }
  }

  Widget _buildMessage(Map<String, dynamic> m, int index) {
    final isMe = m['sender'] == 'me';
    final time = DateTime.parse(m['timestamp']);
    final formattedTime = '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}';
    String content = m['content'];

    Widget messageBody;
    if (m['type'] == 'image') {
      final file = File(content);
      messageBody = GestureDetector(
        onLongPress: () => _addReaction(index),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Image.file(file, width: 200, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formattedTime, style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black54)),
                const SizedBox(width: 6),
                if (isMe) Icon(Icons.check, size: 12, color: Colors.white70),
              ],
            ),
            if (m['reaction'] != null) Text(m['reaction'], style: const TextStyle(fontSize: 18))
          ],
        ),
      );
    } else {
      if (!isMe && m['content'] != null) {
        if (widget.peerId == '1') {
          content = m['content'];
        } else {
          content = m['content'];
        }
      }

      messageBody = GestureDetector(
        onLongPress: () => _addReaction(index),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(content, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formattedTime, style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black54)),
                const SizedBox(width: 6),
                if (isMe) Icon(m['status'] == 'read' ? Icons.done_all : Icons.check, size: 12, color: Colors.white70),
              ],
            ),
            if (m['reaction'] != null) Text(m['reaction'], style: const TextStyle(fontSize: 18))
          ],
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.indigo[300] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: messageBody,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [Text(widget.peerName), const SizedBox(width:6), if (widget.peerId == '1') VerifiedBadge()]),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CallOfferScreen(peerId: widget.peerId)))),
          IconButton(icon: const Icon(Icons.call), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CallOfferScreen(peerId: widget.peerId)))),
          IconButton(icon: const Icon(Icons.call_end), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CallReceiveScreen()))),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length + (_peerTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_peerTyping && index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: const [SizedBox(width: 8), Text('typing...'), SizedBox(width: 8),]),
                    ),
                  );
                }
                return _buildMessage(_messages[index], index);
              },
            ),
          ),
          if (_isTyping) const Padding(padding: EdgeInsets.all(8.0), child: Text('You are typing...', style: TextStyle(fontStyle: FontStyle.italic))),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.image), onPressed: _sendImage),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message'),
                    onChanged: (v) {
                      setState(() => _isTyping = v.isNotEmpty);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
