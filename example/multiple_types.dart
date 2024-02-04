import 'package:dart_types/dart_types.dart';

Future<void> main() async {
  final path = 'example/samples/multiple.dart';
  final typeA = 'C';
  final typeB = 'D';

  final typeGraph =
      await TypeGraph.generateForInterfaceTypes(path: path, selectedTypes: [typeA, typeB]);
  final mermaidGraph = typeGraph.toMermaidGraph();

  print('');
  print(mermaidGraph.viewUrl);
  print('');
}
