import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/discoverable_feature.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/styles/theme.dart';
import 'package:hacki/utils/utils.dart';

class FavIconButton extends StatelessWidget {
  const FavIconButton({
    required this.storyId,
    super.key,
  });

  final int storyId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavCubit, FavState>(
      builder: (BuildContext context, FavState favState) {
        final bool isFav = favState.favIds.contains(storyId);
        return IconButton(
          tooltip: 'Add to favorites',
          icon: CustomDescribedFeatureOverlay(
            tapTarget: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: Palette.white,
            ),
            feature: DiscoverableFeature.addStoryToFavList,
            child: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav
                  ? Theme.of(context).responsivePrimaryColor
                  : Theme.of(context).iconTheme.color,
            ),
          ),
          onPressed: () {
            HapticFeedbackUtil.light();
            if (isFav) {
              context.read<FavCubit>().removeFav(storyId);
            } else {
              context.read<FavCubit>().addFav(storyId);
            }
          },
        );
      },
    );
  }
}
