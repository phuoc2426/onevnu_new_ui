import 'dart:convert';
import 'package:flutter/services.dart';

class SimpleTokenizer {
  SimpleTokenizer({
    required this.vocab,
    this.maxLength = 128,
  });

  final Map<String, int> vocab;
  final int maxLength;

  static Future<SimpleTokenizer> fromAsset(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return SimpleTokenizer(
        vocab: decoded.map((key, value) => MapEntry(key, value as int)),
      );
    } catch (e) {
      // Fallback vocabulary
      return SimpleTokenizer(
        vocab: {
          '[PAD]': 0,
          '[UNK]': 100,
          '[CLS]': 101,
          '[SEP]': 102,
        },
      );
    }
  }

  TokenizedText encode(String text) {
    final normalized = text.trim().toLowerCase();

    final tokens = normalized
        .split(RegExp(r'\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final clsId = vocab['[CLS]'] ?? 101;
    final sepId = vocab['[SEP]'] ?? 102;
    final padId = vocab['[PAD]'] ?? 0;
    final unkId = vocab['[UNK]'] ?? 100;

    final ids = <int>[clsId];

    for (final token in tokens) {
      if (ids.length >= maxLength - 1) break;
      ids.add(vocab[token] ?? unkId);
    }

    ids.add(sepId);

    final attentionMask = List<int>.filled(ids.length, 1);

    while (ids.length < maxLength) {
      ids.add(padId);
      attentionMask.add(0);
    }

    return TokenizedText(
      inputIds: ids,
      attentionMask: attentionMask,
      tokenTypeIds: List<int>.filled(maxLength, 0),
    );
  }
}

class TokenizedText {
  const TokenizedText({
    required this.inputIds,
    required this.attentionMask,
    required this.tokenTypeIds,
  });

  final List<int> inputIds;
  final List<int> attentionMask;
  final List<int> tokenTypeIds;
}
