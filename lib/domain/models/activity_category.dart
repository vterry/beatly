/// Grupo pré-determinado e fechado de 5 classificações para atividades (RN-06.1 / RN-09.1).
enum ActivityCategory {
  tecnica(label: 'Técnica'),
  velocidade(label: 'Velocidade'),
  teoriaMusical(label: 'Teoria Musical'),
  improviso(label: 'Improviso'),
  freeStyle(label: 'Free Style');

  const ActivityCategory({required this.label});

  /// Nome canônico exibido na UI e nos eixos do Gráfico de Teia.
  final String label;
}

