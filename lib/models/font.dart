enum Font {
  roboto('Roboto'),
  robotoSlab('Roboto Slab', isSerif: true),
  ubuntu('Ubuntu'),
  ubuntuMono('Ubuntu Mono'),
  notoSerif('Noto Serif', isSerif: true),
  exo2('Exo 2'),
  atkinsonHyperlegible('AtkinsonHyperlegible'),
  courier('Courier', isSerif: true);

  const Font(this.uiLabel, {this.isSerif = false});

  final String uiLabel;
  final bool isSerif;
}
