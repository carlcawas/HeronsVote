import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// AES-256 encryption service for face embeddings
/// Uses a derived key from user's UID for unique encryption per user
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  Key? _cachedKey;
  String? _cachedUid;

  /// Derives a 256-bit AES key from user's UID
  /// Uses SHA-256 hash of UID + salt to generate consistent 32-byte key
  Future<Key> _getUserKey() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    // Return cached key if same user
    if (_cachedKey != null && _cachedUid == user.uid) {
      return _cachedKey!;
    }

    // Derive key using SHA-256 hash of UID + app-specific salt
    const salt = 'HeronsVote_FaceEmbedding_Salt_2024';
    final keyMaterial = utf8.encode('${user.uid}_$salt');
    final hash = sha256.convert(keyMaterial);
    
    _cachedKey = Key(Uint8List.fromList(hash.bytes));
    _cachedUid = user.uid;
    
    return _cachedKey!;
  }

  /// Encrypts a list of doubles (embedding) and returns base64-encoded string
  Future<String> encryptEmbedding(List<double> embedding) async {
    try {
      final key = await _getUserKey();
      final iv = IV.fromSecureRandom(16); // Random IV for each encryption

      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

      // Convert embedding to JSON string
      final embeddingJson = jsonEncode(embedding);

      // Encrypt
      final encrypted = encrypter.encryptBytes(
        utf8.encode(embeddingJson),
        iv: iv,
      );

      // Combine IV + encrypted data and encode as base64
      final combined = Uint8List.fromList(iv.bytes + encrypted.bytes);
      return base64Encode(combined);
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypts a base64-encoded string back to list of doubles
  Future<List<double>> decryptEmbedding(String encryptedBase64) async {
    try {
      final key = await _getUserKey();
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

      // Decode base64 and extract IV + encrypted data
      final combined = base64Decode(encryptedBase64);
      final iv = IV(Uint8List.fromList(combined.sublist(0, 16)));
      final encryptedData = Uint8List.fromList(combined.sublist(16));

      // Decrypt
      final decryptedBytes = encrypter.decryptBytes(
        Encrypted(encryptedData),
        iv: iv,
      );

      // Parse JSON back to list of doubles
      final embeddingJson = utf8.decode(decryptedBytes);
      final List<dynamic> decoded = jsonDecode(embeddingJson);
      return decoded.map((e) => (e as num).toDouble()).toList();
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Clears cached key (useful on logout)
  void clearCache() {
    _cachedKey = null;
    _cachedUid = null;
  }
}
