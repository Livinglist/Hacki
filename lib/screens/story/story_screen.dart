import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class StoryScreenArgs {
  StoryScreenArgs({required this.story});

  final Story story;
}

class StoryScreen extends StatelessWidget {
  const StoryScreen({Key? key, required this.story}) : super(key: key);

  static const String routeName = '/story';

  static Route route(StoryScreenArgs args) {
    return MaterialPageRoute<StoryScreen>(
      settings: const RouteSettings(name: routeName),
      builder: (context) => BlocProvider(
        create: (_) => CommentsCubit(
          commentIds: args.story.kids,
        ),
        child: StoryScreen(
          story: args.story,
        ),
      ),
    );
  }

  final Story story;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentsCubit, CommentsState>(
      builder: (context, state) {
        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).padding.top,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6, right: 6, bottom: 12),
                  child: Row(
                    children: [
                      Text(
                        story.by,
                        style: const TextStyle(
                          color: Colors.orange,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        story.postedDate,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  child: InkWell(
                    onTap: () {
                      final url = Uri.encodeFull(story.url);
                      canLaunch(url).then((val) {
                        if (val) {
                          launch(url);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 6,
                        bottom: 12,
                        right: 6,
                      ),
                      child: Text(
                        story.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                if (state.comments.isEmpty) ...[
                  const SizedBox(
                    height: 240,
                  ),
                  const Center(
                    child: Text(
                      'Nothing yet',
                      style: TextStyle(color: Colors.white30),
                    ),
                  ),
                ],
                ...state.comments.map(
                  (e) => CommentTile(
                    comment: e,
                  ),
                ),
                const SizedBox(
                  height: 60,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
