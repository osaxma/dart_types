import 'package:dart_types/dart_types.dart';

Future<void> main() async {
  final path = 'example/samples/organism.dart';
  final type = 'UltimateOrganism';
  final typeGraph = await TypeGraph.generateForInterfaceTypes(path: path, selectedTypes: [type]);
  final mermaidGraph = typeGraph.toMermaidGraph();

  print('view as image at:');
  print(mermaidGraph.imageUrl);
  print('');
  print('view interactively at:');
  print(mermaidGraph.viewUrl);
  print('');
  print('edit interactively at:');
  print(mermaidGraph.editUrl);
  print('');
}
