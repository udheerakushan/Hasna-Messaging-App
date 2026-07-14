import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/key_storage.dart';

class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({Key? key}) : super(key: key);

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _creating = false;
  Map<String, String>? _profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              SizedBox(height: 180, child: Center(child: Lottie.network('https://assets3.lottiefiles.com/packages/lf20_totrpclr.json'))),
              const SizedBox(height: 12),
              const Text('Welcome to Hasna', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Create your local Hasna account. A unique Hasna number and keypair will be generated on this device.'),
              const SizedBox(height: 12),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Display name')),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _creating ? null : _create,
                child: _creating ? const CircularProgressIndicator() : const Text('Create account'),
              ),
              if (_profile != null) ...[
                const SizedBox(height: 12),
                Text('Your Hasna contact code (share to add contacts):'),
                const SizedBox(height: 8),
                QrImage(data: _profile!['contact_code']!, size: 200.0),
                const SizedBox(height: 8),
                SelectableText(_profile!['contact_code']!),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SizedBox())), child: const Text('Done'))
              ]
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create() async {
    setState(() => _creating = true);
    final prof = await KeyStorage.createKeyPairAndProfile(displayName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim());
    setState(() {
      _profile = prof;
      _creating = false;
    });
  }
}
