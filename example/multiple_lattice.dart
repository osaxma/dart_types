import 'package:dart_types/dart_types.dart';

Future<void> main() async {
  final typeAnalyzer = await TypeAnalyzer.fromPath('example/samples/multiple.dart');
  final typeA = typeAnalyzer.getClass('C')!.thisType;
  final typeB = typeAnalyzer.getClass('D')!.thisType;

  final lattice = Lattice.merged(selectedTypes: [typeA, typeB], typeAnalyzer: typeAnalyzer);

  print(lattice.toMermaidGraph(
    highlight: [
      typeA,
      typeB,
    ],
  ));
}
