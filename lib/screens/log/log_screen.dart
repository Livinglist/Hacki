import 'package:flutter/material.dart';
import 'package:hacki/utils/log_util.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  static const String routeName = 'log';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 0,
      ),
      body: FutureBuilder<List<String>>(
        future: LogUtil.exportLogAsStrings(),
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          return ListView(
            children: <Widget>[
              ...?snapshot.data?.map(Text.new),
            ],
          );
        },
      ),
    );
  }
}
