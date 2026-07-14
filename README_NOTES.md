---
layout: none
---

# Hasna - Notes

This set of commits adds encrypted media storage (image pick/camera capture) and forwarding/group scaffolds.

Security notes & TODOs
- Groups currently store a group_key in the DB; full secure distribution of the group key to other members (encrypting the group key to each member's public key) requires that each contact's public key is available in the local contacts table.
- For now the group_key is stored encrypted with the creator's private material or as plaintext in the groups table depending on availability of members' public keys. You should review the `lib/services/crypto.dart` helpers and implement secure distribution to new members.

Run & test
- flutter pub get
- flutter run

