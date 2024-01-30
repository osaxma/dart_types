import 'package:dart_types/dart_types.dart';

Future<void> main() async {
  final typeAnalyzer = await TypeAnalyzer.fromPath('local/sample.dart');
  final type = typeAnalyzer.getClass('E')!.thisType;
  final lattice = Lattice(type: type, typeAnalyzer: typeAnalyzer);
  print(lattice.toMermaidGraph());
}
