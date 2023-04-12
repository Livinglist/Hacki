import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

void main() => runApp(const InAppReviewExampleApp());

enum Availability { loading, available, unavailable }

class InAppReviewExampleApp extends StatefulWidget {
  const InAppReviewExampleApp({Key? key}) : super(key: key);

  @override
  InAppReviewExampleAppState createState() => InAppReviewExampleAppState();
}

class InAppReviewExampleAppState extends State<InAppReviewExampleApp> {
  final InAppReview _inAppReview = InAppReview.instance;

  String _appStoreId = '';
  String _microsoftStoreId = '';
  Availability _availability = Availability.loading;

  @override
  void initState() {
    super.initState();

    (<T>(T? o) => o!)(WidgetsBinding.instance).addPostFrameCallback((_) async {
      try {
        final isAvailable = await _inAppReview.isAvailable();

        setState(() {
          // This plugin cannot be tested on Android by installing your app
          // locally. See https://github.com/britannio/in_app_review#testing for
          // more information.
          _availability = isAvailable && !Platform.isAndroid
              ? Availability.available
              : Availability.unavailable;
        });
      } catch (_) {
        setState(() => _availability = Availability.unavailable);
      }
    });
  }

  void _setAppStoreId(String id) => _appStoreId = id;

  void _setMicrosoftStoreId(String id) => _microsoftStoreId = id;

  Future<void> _requestReview() => _inAppReview.requestReview();

  Future<void> _openStoreListing() => _inAppReview.openStoreListing(
        appStoreId: _appStoreId,
        microsoftStoreId: _microsoftStoreId,
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'In App Review Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('In App Review Example')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('In App Review status: ${_availability.name}'),
            TextField(
              onChanged: _setAppStoreId,
              decoration: const InputDecoration(hintText: 'App Store ID'),
            ),
            TextField(
              onChanged: _setMicrosoftStoreId,
              decoration: const InputDecoration(hintText: 'Microsoft Store ID'),
            ),
            ElevatedButton(
              onPressed: _requestReview,
              child: const Text('Request Review'),
            ),
            ElevatedButton(
              onPressed: _openStoreListing,
              child: const Text('Open Store Listing'),
            ),
          ],
        ),
      ),
    );
  }
}
