import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';

final paletteProvider = FutureProvider.family<PaletteGenerator?, String>((ref, imageUrl) async {
  if (imageUrl.isEmpty) return null;
  try {
    return await PaletteGenerator.fromImageProvider(
      NetworkImage(imageUrl),
      maximumColorCount: 10,
    );
  } catch (e) {
    return null;
  }
});
