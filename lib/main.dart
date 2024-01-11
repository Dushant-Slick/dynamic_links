import 'dart:math';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String link = 'No Link';
  @override
  void initState() {
    super.initState();
    FirebaseDynamicLinks.instance.onLink.listen(
      (pendingDynamicLinkData) {
        final Uri deepLink = pendingDynamicLinkData.link;

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("from event: $deepLink")));
          setState(() => link = deepLink.path);
        }

        print(deepLink.path);
      },
    );
    getInitialLink();
  }

  void getInitialLink() async {
    final PendingDynamicLinkData? initialLink =
        await FirebaseDynamicLinks.instance.getInitialLink();

    if (initialLink != null) {
      final Uri deepLink = initialLink.link;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("from init: $deepLink")));

      setState(() => link = deepLink.path);
      print(deepLink.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(link),
                const SizedBox(height: 10.0),
                ElevatedButton(
                  onPressed: () {
                    try {
                      throw Exception('Throw Test Exception');
                    } on Exception catch (e) {
                      FirebaseCrashlytics.instance.recordFlutterError(
                          FlutterErrorDetails(exception: e));
                    }
                  },
                  child: const Text("Throw Test Exception"),
                ),
              ],
            ),
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
                      bundleId: "com.example.dynamicLinks",
                      minimumVersion: "0"),
                );
                final dynamicLink = await FirebaseDynamicLinks.instance
                    .buildShortLink(dynamicLinkParams);
                print(dynamicLink.shortUrl);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("from event: ${dynamicLink.shortUrl}")));
                await Clipboard.setData(
                  ClipboardData(text: dynamicLink.previewLink.toString()),
                );
              } on Exception catch (e) {
                print(e);
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      }),
    );
  }
}
