# Hasna

Hasna is a starter Flutter scaffold for a secure messaging app. This repository contains an initial UI, mock encryption placeholders, and a WebRTC service placeholder for voice/video calls.

IMPORTANT: The current implementation is a scaffold and educational example only. The included crypto code is a mock and NOT secure. Do NOT use this code as-is for any real confidential communication.

What I added in this commit
- lib/main.dart — App UI with Chats, Contacts, and a Chat screen
- lib/services/crypto.dart — mock encryption service (placeholder)
- lib/services/webrtc_service.dart — flutter_webrtc integration skeleton
- README.md — this file

Next recommended steps to build a secure app
1. Backend / signalling: implement a secure signalling server (TLS, authenticated) to exchange encrypted messages and WebRTC SDP/ICE.
2. End-to-end encryption: integrate a proven E2EE protocol such as Signal Protocol or use libsodium for authenticated encryption. Manage long-term identity keys and ephemeral session keys.
3. Key verification: support safety numbers or QR codes so users can verify identities.
4. Secure storage: store keys in platform secure storage (Android Keystore / iOS Keychain).
5. Code audit: have cryptography and security experts review the implementation.

How to run
1. Install Flutter SDK (>=3.0)
2. flutter pub get
3. flutter run

If you want, I can:
- Implement a simple signalling server (Node.js + WebSocket) and connect the WebRTC placeholder to enable calls.
- Replace the mock crypto with libsodium and demonstrate E2EE for text messages (still needs careful design for production).
- Add authentication, push notifications, and media/file sending.

Tell me which of the above you want me to implement next and I will add it to the repo.