import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:instagram_share_plus/instagram_share_plus.dart';

final screenshotController = ScreenshotController();

class Shareable extends StatelessWidget {
  final Widget child;
  const Shareable({super.key, required this.child});
  @override
  Widget build(BuildContext context) =>
      Screenshot(controller: screenshotController, child: child);
}

Future<File?> _captureShareImage() async {
  final bytes = await screenshotController.capture();
  if (bytes == null) return null;
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/goth_mood_share.png');
  await file.writeAsBytes(bytes);
  return file;
}

Future<void> shareGeneric({String? text}) async {
  final file = await _captureShareImage();
  if (file == null) return;
  await Share.shareXFiles([XFile(file.path)], text: text ?? 'Goth Mood Tracker');
}

Future<void> shareToInstagramStories({String? attributionUrl}) async {
  final file = await _captureShareImage();
  if (file == null) return;
  final installed = await InstagramSharePlus.isInstagramInstalled();
  if (!installed) {
    await shareGeneric(text: 'Goth Mood Tracker');
    return;
  }
  await InstagramSharePlus.shareToStories(
    imagePath: file.path,
    backgroundTopColor: '#000000',
    backgroundBottomColor: '#000000',
    attributionURL: attributionUrl ?? 'https://pixelpanic.shop',
  );
}
