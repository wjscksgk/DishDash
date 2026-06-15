import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

enum DeliveryApp { baemin, yogiyo }

Future<void> openDeliveryApp(DeliveryApp app, String foodName) async {
  final query = Uri.encodeComponent(foodName);
  final search = switch (app) {
    DeliveryApp.baemin => Uri.parse('baemin://search?search_query=$query'),
    DeliveryApp.yogiyo => Uri.parse('yogiyo://search?query=$query'),
  };
  final home = switch (app) {
    DeliveryApp.baemin => Uri.parse('baemin://'),
    DeliveryApp.yogiyo => Uri.parse('yogiyo://'),
  };
  final store =
      Platform.isAndroid
          ? switch (app) {
            DeliveryApp.baemin => Uri.parse(
              'https://play.google.com/store/apps/details?id=com.sampleapp',
            ),
            DeliveryApp.yogiyo => Uri.parse(
              'https://play.google.com/store/apps/details?id=com.fineapp.yogiyo',
            ),
          }
          : switch (app) {
            DeliveryApp.baemin => Uri.parse(
              'https://apps.apple.com/kr/app/id378084485',
            ),
            DeliveryApp.yogiyo => Uri.parse(
              'https://apps.apple.com/kr/app/id543831532',
            ),
          };

  if (await launchUrl(search, mode: LaunchMode.externalApplication)) return;
  await Clipboard.setData(ClipboardData(text: foodName));
  if (await launchUrl(home, mode: LaunchMode.externalApplication)) return;
  await launchUrl(store, mode: LaunchMode.externalApplication);
}
