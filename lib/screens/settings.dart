import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/key_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _contactCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await KeyStorage.getProfile();
    _nameController.text = p['name'] ?? '';
    _contactCode = p['contact_code'];
    setState(() {});
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked != null) {
      await KeyStorage.saveProfileImage(picked.path);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile image updated (local only)')));
    }
  }

  Future<void> _save() async {
    await KeyStorage.updateDisplayName(_nameController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Display name')),
            const SizedBox(height: 12),
            ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo), label: const Text('Choose profile photo')),
            const SizedBox(height: 12),
            if (_contactCode != null) SelectableText('Your contact code: $_contactCode'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _save, child: const Text('Save'))
          ],
        ),
      ),
    );
  }
}
