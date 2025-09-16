import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // ✅ needed for RenderRepaintBoundary
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Global key to find the widget we want to turn into an image.
final GlobalKey _shareKey = GlobalKey();

/// Wrap the UI you want to share with this widget.
class Shareable extends StatelessWidget {
  final Widget child;
  const Shareable({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _shareKey,
      child: child,
    );
  }
}

/// Capture the widget wrapped by [Shareable] into a PNG file.
Future<File?> _captureShareImage() async {
  final ctx = _shareKey.currentContext;
  if (ctx == null) return null;

  // Ensure it painted at least once.
  await Future.delayed(const Duration(milliseconds: 30));

  final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return null;

  if (boundary.debugNeedsPaint) {
    await Future.delayed(const Duration(milliseconds: 30));
  }

  final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
  final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return null;

  final bytes = byteData.buffer.asUint8List();
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/goth_mood_share.png');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

/// Generic share (Discord, SMS, etc.)
Future<void> shareGeneric({String? text}) async {
  final file = await _captureShareImage();
  if (file == null) return;
  await Share.shareXFiles([XFile(file.path)], text: text ?? 'Goth Mood Tracker');
}

/// Instagram Stories via MethodChannel (falls back to generic if IG missing)
const _igChannel = MethodChannel('goth_mood/ig_share');

Future<void> shareToInstagramStories({String? attributionUrl}) async {
  final file = await _captureShareImage();
  if (file == null) return;

  try {
    final installed =
        await _igChannel.invokeMethod<bool>('isInstagramInstalled') ?? false;
    if (!installed) {
      await shareGeneric(text: 'Goth Mood Tracker');
      return;
    }

    final ok = await _igChannel.invokeMethod<bool>('shareToStories', {
      'imagePath': file.path,
      'attributionURL': attributionUrl,
    });

    if (ok != true) {
      await shareGeneric(text: 'Goth Mood Tracker');
    }
  } on PlatformException {
    await shareGeneric(text: 'Goth Mood Tracker');
  }
}

