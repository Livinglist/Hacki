import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hacki/extensions/context_extension.dart';
import 'package:hacki/utils/haptic_feedback_util.dart';
import 'package:hacki/utils/log_util.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  static const String routeName = 'log';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: LogUtil.exportLogAsStrings(),
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Theme.of(context).canvasColor.withValues(
                  alpha: 0.6,
                ),
            elevation: 0,
            actions: <Widget>[
              if (snapshot.data != null)
                IconButton(
                  onPressed: () {
                    final String data = snapshot.data!.reduce(
                      (
                        String lhs,
                        String rhs,
                      ) =>
                          lhs + rhs,
                    );
                    Clipboard.setData(ClipboardData(text: data))
                        .whenComplete(HapticFeedbackUtil.selection);
                    context.showSnackBar(content: 'Log copied.');
                  },
                  icon: const Icon(Icons.copy),
                ),
            ],
          ),
          body: ListView(
            children: <Widget>[
              ...?snapshot.data?.map(Text.new),
            ],
          ),
        );
      },
    );
  }
}
