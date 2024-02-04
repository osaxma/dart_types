import 'package:dart_types/dart_types.dart';

Future<void> main() async {
  final path = 'example/samples/organism.dart';

  final typeGraph =
      await TypeGraph.generateForInterfaceTypes(path: path, selectedTypes: ['UltimateOrganism']);
  final mermaidGraph = typeGraph.toMermaidGraph();

  print('');
  print(mermaidGraph.code);
  print('');
}
