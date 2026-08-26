/// Categoría fija que clasifica el punto sucio reportado (FR-007). La lista
/// de 5 valores es fija para esta feature (ver Assumptions de spec.md).
enum WasteCategory {
  basuraAcumulada('Basura acumulada'),
  escombros('Escombros'),
  mueblesEnseres('Muebles/enseres'),
  residuosVerdes('Residuos verdes'),
  otros('Otros');

  const WasteCategory(this.label);

  /// Texto mostrado al usuario en la UI.
  final String label;
}
