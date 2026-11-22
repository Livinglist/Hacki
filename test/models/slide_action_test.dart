import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';

void main() {
  test('existing saved slide action indices keep their meaning', () {
    const List<SlideAction> savedActions = <SlideAction>[
      SlideAction.upvote,
      SlideAction.downvote,
      SlideAction.timeMachine,
      SlideAction.goToParent,
      SlideAction.viewProfile,
      SlideAction.searchOnHackerNews,
      SlideAction.searchInThread,
      SlideAction.favorite,
      SlideAction.share,
      SlideAction.viewInBrowser,
      SlideAction.reply,
      SlideAction.viewInSeparateThread,
    ];

    for (int index = 0; index < savedActions.length; index++) {
      final PreferenceState restored = PreferenceState.init()
          .copyWithPreference(LeadingActionPreference(val: index))
          .copyWithPreference(SecondaryActionPreference(val: index))
          .copyWithPreference(TrailingActionPreference(val: index));

      expect(restored.leadingAction, savedActions[index]);
      expect(restored.secondaryAction, savedActions[index]);
      expect(restored.trailingAction, savedActions[index]);
    }
    expect(SlideAction.goToRoot.index, savedActions.length);
  });
}
