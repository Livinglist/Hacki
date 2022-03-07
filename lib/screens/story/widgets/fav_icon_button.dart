import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';

class FavIconButton extends StatelessWidget {
  const FavIconButton({
    Key? key,
    required this.storyId,
  }) : super(key: key);

  final int storyId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavCubit, FavState>(
      builder: (context, favState) {
        final isFav = favState.favIds.contains(storyId);
        return IconButton(
          icon: DescribedFeatureOverlay(
            barrierDismissible: false,
            overflowMode: OverflowMode.extendBackground,
            targetColor: Theme.of(context).primaryColor,
            tapTarget: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            featureId: Constants.featureAddStoryToFavList,
            title: const Text('Fav a Story'),
            description: const Text(
              'Add it to your favorites.',
              style: TextStyle(fontSize: 16),
            ),
            child: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.orange : Theme.of(context).iconTheme.color,
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
