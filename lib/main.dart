import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'services/key_storage.dart';
import 'services/crypto.dart';
import 'screens/account_setup.dart';
import 'screens/settings.dart';
import 'widgets/verified_badge.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KeyStorage.init();
  runApp(const HasnaApp());
}

class HasnaApp extends StatelessWidget {
  const HasnaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hasna',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const RootRouter(),
    );
  }
}

class RootRouter extends StatefulWidget {
  const RootRouter({Key? key}) : super(key: key);

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
    return const HomePage();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

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
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
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
    );
  }
}

class ChatsPage extends StatefulWidget {
  const ChatsPage({Key? key}) : super(key: key);

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final List<Map<String, String>> _conversations = [
    {'id': '1', 'name': 'Hasna Help'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conv = _conversations[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.help)),
          title: Row(children: [Text(conv['name']!), const SizedBox(width: 6), VerifiedBadge()]),
          subtitle: const Text('Official Hasna help bot'),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChatScreen(peerName: conv['name']!, peerId: conv['id']!),
            ));
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
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.qr_code),
            label: const Text('Add by QR / Code'),
            onPressed: () async {
              // open QR generator for this device (share) or scanner
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
  final List<String> _messages = [];

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final me = await KeyStorage.getProfile();
    final peerPublic = await KeyStorage.getPublicKeyFor(widget.peerId);

    // Encrypt using CryptoService (note: this implementation is illustrative)
    final encrypted = await CryptoService.encrypt(peerPublic ?? '', me['private']!, text);

    setState(() {
      _messages.add('Me: $text');
      _messages.add('Encrypted (mock): $encrypted');
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [Text(widget.peerName), const SizedBox(width:6), if (widget.peerId == '1') VerifiedBadge()]),
        actions: [
          IconButton(icon: const Icon(Icons.call), onPressed: () {
            // placeholder for call action: would create QR offer flow
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('To start a call, share offer/answer via QR or copy-paste (serverless).')));
          })
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) => ListTile(title: Text(_messages[index])),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message'),
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
