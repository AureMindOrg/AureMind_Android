import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  // Your secret master key
  static final _key = encrypt.Key.fromBase64('8FwtQCZ1Qd6ozeREDK3Co_sUhr7J2PDbzrgFUvWFvdA=');
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  static String encryptText(String text) {
    if (text.isEmpty) return '';
    
    // 1. Generate a new, secure random 16-byte IV for this specific note
    final iv = encrypt.IV.fromSecureRandom(16);
    
    // 2. Encrypt the text
    final encrypted = _encrypter.encrypt(text, iv: iv);
    
    // 3. Store them together separated by a colon (IV:EncryptedText)
    return '${iv.base64}:${encrypted.base64}';
  }

  static String decryptText(String combinedData) {
    if (combinedData.isEmpty) return '';
    
    try {
      // Check if the data contains our colon separator
      if (combinedData.contains(':')) {
        final parts = combinedData.split(':');
        final iv = encrypt.IV.fromBase64(parts[0]);
        final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
        
        return _encrypter.decrypt(encrypted, iv: iv);
      } else {
        // Fallback: If it doesn't have a colon, it was from the old bugged code.
        // We will try to decrypt it using a blank IV, but if it was truly randomized
        // on the old version, this will intentionally fail to protect the app from crashing.
        final fallbackIv = encrypt.IV.fromLength(16);
        final encrypted = encrypt.Encrypted.fromBase64(combinedData);
        return _encrypter.decrypt(encrypted, iv: fallbackIv);
      }
    } catch (e) {
      return 'Decryption Failed: Invalid data.';
    }
  }
}