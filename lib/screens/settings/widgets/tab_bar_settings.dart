import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:material_ui/material_ui.dart';

class TabBarSettings extends StatefulWidget {
  const TabBarSettings({super.key});

  @override
  State<TabBarSettings> createState() => _TabBarSettingsState();
}

class _TabBarSettingsState extends State<TabBarSettings> {
  static const double height = 60;
  static const double width = 300;

  @override
  Widget build(BuildContext context) {
    final double fontSize = DefaultTextStyle.of(context).style.fontSize ?? 14;
    final double textScale =
        (MediaQuery.textScalerOf(context).scale(fontSize) / fontSize).clamp(
          1,
          double.infinity,
        );
    return Column(
      children: <Widget>[
        const Row(
          children: <Widget>[
            SizedBox(width: Dimens.pt16),
            Text('Default tab bar'),
            Spacer(),
          ],
        ),
        BlocBuilder<TabCubit, TabState>(
          builder: (BuildContext context, TabState state) {
            return Center(
              child: SizedBox(
                height: height * textScale,
                width: width * textScale,
                child: ReorderableListView(
                  scrollDirection: Axis.horizontal,
                  onReorderItem: context.read<TabCubit>().update,
                  onReorderStart: (_) => HapticFeedbackUtils.light(),
                  children: <Widget>[
                    for (final StoryType tab in state.tabs)
                      InkWell(
                        key: ValueKey<StoryType>(tab),
                        child: SizedBox(
                          width: 60 * textScale,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(tab.label),
                              const Icon(
                                Icons.drag_handle_outlined,
                                color: Palette.grey,
                                size: TextDimens.pt14,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
