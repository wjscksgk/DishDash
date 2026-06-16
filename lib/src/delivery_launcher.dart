import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

enum DeliveryApp { baemin, coupangEats }

Future<void> openDeliveryApp(DeliveryApp app, String foodName) async {
  final query = Uri.encodeComponent(foodName);
  final search = switch (app) {
    DeliveryApp.baemin => Uri.parse('baemin://search?search_query=$query'),
    DeliveryApp.coupangEats => null,
  };
  final home = switch (app) {
    DeliveryApp.baemin => Uri.parse('baemin://'),
    DeliveryApp.coupangEats => Uri.parse('coupangeats://'),
  };
  final store =
      Platform.isAndroid
          ? switch (app) {
            DeliveryApp.baemin => Uri.parse(
              'https://play.google.com/store/apps/details?id=com.sampleapp',
            ),
            DeliveryApp.coupangEats => Uri.parse(
              'https://play.google.com/store/apps/details?id=com.coupang.mobile.eats',
            ),
          }
          : switch (app) {
            DeliveryApp.baemin => Uri.parse(
              'https://apps.apple.com/kr/app/id378084485',
            ),
            DeliveryApp.coupangEats => Uri.parse(
              'https://apps.apple.com/kr/search?term=%EC%BF%A0%ED%8C%A1%EC%9D%B4%EC%B8%A0',
            ),
          };

  if (search != null &&
      await launchUrl(search, mode: LaunchMode.externalApplication)) {
    return;
  }
  await Clipboard.setData(ClipboardData(text: foodName));
  if (await launchUrl(home, mode: LaunchMode.externalApplication)) return;
  await launchUrl(store, mode: LaunchMode.externalApplication);
}
