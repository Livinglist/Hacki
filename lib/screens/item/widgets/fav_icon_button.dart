import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';

class FavIconButton extends StatelessWidget {
  const FavIconButton({
    super.key,
    required this.storyId,
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
            featureId: Constants.featureAddStoryToFavList,
            title: const Text('Fav a Story'),
            description: const Text(
              'Add it to your favorites.',
              style: TextStyle(fontSize: TextDimens.pt16),
            ),
            child: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Palette.orange : Theme.of(context).iconTheme.color,
            ),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
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
