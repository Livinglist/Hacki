import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

class MaxLineComputationParams extends Equatable {
  const MaxLineComputationParams(
    this.fontFamily,
    this.layoutWidth,
    this.layoutHeight,
    this.titleHeight,
    this.textScaler,
    // ignore: avoid_positional_boolean_parameters
    this.showUrl,
    this.showMetadata,
  );

  final String fontFamily;
  final double layoutWidth;
  final double layoutHeight;
  final double titleHeight;
  final TextScaler textScaler;
  final bool showUrl;
  final bool showMetadata;

  @override
  List<Object?> get props => <Object>[
        fontFamily,
        layoutWidth,
        layoutHeight,
        titleHeight,
        textScaler,
        showUrl,
        showMetadata,
      ];
}
