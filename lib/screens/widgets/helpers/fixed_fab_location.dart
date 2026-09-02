import 'package:material_ui/material_ui.dart';

class FixedFabLocation extends FloatingActionButtonLocation {
  const FixedFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    const double margin = 16;

    return Offset(
      geometry.scaffoldSize.width -
          geometry.floatingActionButtonSize.width -
          margin,
      geometry.scaffoldSize.height -
          geometry.floatingActionButtonSize.height -
          margin,
    );
  }
}
