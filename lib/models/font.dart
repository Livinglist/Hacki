enum Font {
  roboto('Roboto'),
  robotoSlab('Roboto Slab', isSerif: true),
  ubuntu('Ubuntu'),
  ubuntuMono('Ubuntu Mono'),
  notoSerif('Noto Serif', isSerif: true);

  const Font(this.uiLabel, {this.isSerif = false});

  final String uiLabel;
  final bool isSerif;

  static Font fromString(String? val) {
    switch (val) {
      case 'robotoSlab':
        return Font.robotoSlab;
      case 'ubuntu':
        return Font.ubuntu;
      case 'ubuntuMono':
        return Font.ubuntuMono;
      case 'notoSerif':
        return Font.notoSerif;
      case 'roboto':
      default:
        return Font.roboto;
    }
  }
}
