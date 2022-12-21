import 'package:hacki/styles/styles.dart';

enum FontSize {
  regular('Regular', TextDimens.pt16),
  large('Large', TextDimens.pt17),
  xlarge('XLarge', TextDimens.pt18);

  const FontSize(this.description, this.fontSize);

  final String description;
  final double fontSize;
}
