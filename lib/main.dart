import 'dart:math';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final PendingDynamicLinkData? link = await FirebaseDynamicLinks.instance
      .getDynamicLink(Uri.parse("https://dynamiclinks9c82e.page.link/SNtE"));

  print(link?.link);
  print(link?.ios);

  final PendingDynamicLinkData? initialLink =
      await FirebaseDynamicLinks.instance.getInitialLink();

  if (initialLink != null) {
    final Uri deepLink = initialLink.link;
    print(deepLink.path);
  }

  FirebaseDynamicLinks.instance.onLink.listen(
    (pendingDynamicLinkData) {
      final Uri deepLink = pendingDynamicLinkData.link;
      print(deepLink.path);
    },
  );

  runApp(MyApp(link: initialLink?.link.toString() ?? 'No Link'));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.link});

  final String link;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        body: Center(
          child: Text(link),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            try {
              final random = Random();
              int value = random.nextInt(1000000);
              final dynamicLinkParams = DynamicLinkParameters(
                link: Uri.parse("https://dynamiclinks9c82e.page.link/$value"),
                uriPrefix: "https://dynamiclinks9c82e.page.link",
                iosParameters: const IOSParameters(
                    bundleId: "com.example.dynamicLinks", minimumVersion: "0"),
              );
              final dynamicLink = await FirebaseDynamicLinks.instance
                  .buildShortLink(dynamicLinkParams);
              print(dynamicLink.shortUrl);
              await Clipboard.setData(
                ClipboardData(text: dynamicLink.previewLink.toString()),
              );
            } on Exception catch (e) {
              print(e);
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
