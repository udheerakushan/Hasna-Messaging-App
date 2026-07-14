Hasna

This commit adds a serverless-first feature set and UI polish per your request.

What I added in this change
- Account creation flow with auto-generated Hasna number and local key material (stored in flutter_secure_storage)
- Contact code QR generation so users can add each other without a central server
- Settings screen with editable display name and local profile picture selection
- Lottie animation on onboarding
- Verified Help bot seeded in contacts and chats with a green badge
- A stronger placeholder crypto layer that derives a shared secret and encrypts payloads (demo only) — NOT production-grade

Notes & security
- This implementation intentionally avoids any external paid services and remains serverless by default. Signalling for WebRTC calls is supported via manual QR / copy-paste exchange as requested (no signalling server required).
- The current encryption is still a demo/prototype (derives keys via SHA-256 and uses a simple XOR keystream). For real E2EE, replace with X25519 + HKDF + ChaCha20-Poly1305 or Signal Protocol.

Next steps I can implement immediately
- Replace demo crypto with proper X25519/HKDF/ChaCha20-Poly1305 using the cryptography package.
- Add QR-based offer/answer flow for seamless serverless WebRTC calling (generate offer, encode to QR, scan to reply with answer).
- Add a small self-hostable signalling server (optional) if you later want automatic call setup.

Run instructions
1. flutter pub get
2. flutter run

If you want, I will now replace the demo crypto with a proper X25519-based E2EE implementation (preferred) and add the QR-based offer/answer call flow so that two users can call without any server — say "Implement E2EE and QR call flow" and I will add that next.