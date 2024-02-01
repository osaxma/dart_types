import 'package:dart_types/dart_types.dart';

Future<void> main() async {
  final typeAnalyzer = await TypeAnalyzer.fromPath('example/samples/organism.dart');
  final type = typeAnalyzer.getClass('UltimateOrganism')!.thisType;
  final lattice = Lattice(type: type, typeAnalyzer: typeAnalyzer);
  final graph = lattice.toMermaidGraph(highlight: [type]);

  print('view as image at:');
  print(MermaidGraph.generateMermaidImageUrl(graph));
  print('');
  print('view interactively at:');
  print(MermaidGraph.generateMermaidUrl(graph));
  print('');
}
