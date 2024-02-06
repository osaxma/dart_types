import 'package:dart_types/dart_types.dart';

Future<void> main() async {
  final path = 'example/samples/typedef.dart';

  final typeGraph = await TypeGraph.generateForFunctionType(path: path, functionName: 'Func');
  final mermaidGraph = typeGraph.toMermaidGraph();

  print('');
  print(mermaidGraph.viewUrl);
  print('');
}
