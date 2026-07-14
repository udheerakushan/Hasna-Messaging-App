import 'package:flutter/material.dart';
import 'services/crypto.dart';

void main() {
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
      home: const HomePage(),
    );
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
    {'id': '1', 'name': 'Alice'},
    {'id': '2', 'name': 'Bob'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conv = _conversations[index];
        return ListTile(
          title: Text(conv['name']!),
          subtitle: const Text('Tap to open chat'),
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

class ContactsPage extends StatelessWidget {
  const ContactsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final contacts = ['Alice', 'Bob', 'Charlie'];
    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(contacts[index]),
        trailing: const Icon(Icons.person_add),
      ),
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

    // Placeholder: encrypt before sending
    final encrypted = await CryptoService.encryptMessage(widget.peerId, text);

    setState(() {
      _messages.add('Me: $text');
      _messages.add('Encrypted (mock): $encrypted');
    });

    _controller.clear();

    // TODO: send encrypted payload to server / peer via signalling
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(_messages[index]),
              ),
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
