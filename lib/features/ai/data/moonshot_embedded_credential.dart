import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/api.dart';

class MoonshotEmbeddedCredential {
  const MoonshotEmbeddedCredential._();

  static String resolveApiKey() {
    final keyBytes = _hexToBytes(_clusterA + _clusterB + _clusterC);
    final ivBytes = _hexToBytes(_windowA + _windowB + _windowC);
    final encryptedBytes = base64Decode(_payloadA + _payloadB + _payloadC);
    final decryptedBytes = Uint8List(encryptedBytes.length);
    try {
      final cipher = CBCBlockCipher(AESEngine())
        ..init(false, ParametersWithIV(KeyParameter(keyBytes), ivBytes));
      for (var offset = 0; offset < encryptedBytes.length; offset += 16) {
        cipher.processBlock(encryptedBytes, offset, decryptedBytes, offset);
      }
      final plainBytes = _removePkcs7Padding(decryptedBytes);
      try {
        return utf8.decode(plainBytes);
      } finally {
        plainBytes.fillRange(0, plainBytes.length, 0);
      }
    } finally {
      keyBytes.fillRange(0, keyBytes.length, 0);
      ivBytes.fillRange(0, ivBytes.length, 0);
      encryptedBytes.fillRange(0, encryptedBytes.length, 0);
      decryptedBytes.fillRange(0, decryptedBytes.length, 0);
    }
  }

  static Uint8List _removePkcs7Padding(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const FormatException('API key 解密结果为空');
    }
    final padding = bytes.last;
    if (padding <= 0 || padding > 16 || padding > bytes.length) {
      throw const FormatException('API key 填充格式不合法');
    }
    for (var index = bytes.length - padding; index < bytes.length; index++) {
      if (bytes[index] != padding) {
        throw const FormatException('API key 填充校验失败');
      }
    }
    return Uint8List.fromList(bytes.sublist(0, bytes.length - padding));
  }

  static Uint8List _hexToBytes(String value) {
    if (value.length.isOdd) {
      throw const FormatException('HEX 长度不合法');
    }
    final bytes = Uint8List(value.length ~/ 2);
    for (var index = 0; index < value.length; index += 2) {
      bytes[index ~/ 2] = int.parse(
        value.substring(index, index + 2),
        radix: 16,
      );
    }
    return bytes;
  }

  static const _clusterA = 'A0CB6FF8A4CA1754FBED08';
  static const _clusterB = '4AC6C9171957C0073CA0CF';
  static const _clusterC = '7899DC80EA8A3ED63AB3';

  static const _windowA = '402398931D6F1D16';
  static const _windowB = '06EF815CACF385';
  static const _windowC = '76';

  static const _payloadA = '00h7zjJzn/WlQnt7kV3VinIF6jO3Nl';
  static const _payloadB = '6rr0YRTzbt4h/+NaxwjShquM98KQL7';
  static const _payloadC = 'YvJGdWC/l4mVffNHVb2hShDdNg==';
}
