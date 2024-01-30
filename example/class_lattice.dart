import 'package:dart_types/dart_types.dart';

Future<void> main() async {
  final typeAnalyzer = await TypeAnalyzer.fromPath('example/samples/organism.dart');
  final type = typeAnalyzer.getClass('UltimateOrganism')!.thisType;
  final lattice = Lattice(type: type, typeAnalyzer: typeAnalyzer);
  print(lattice.toMermaidGraph(highlight: [type]));
}
