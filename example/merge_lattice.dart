import 'package:dart_types/dart_types.dart';

Future<void> main() async {
  final typeAnalyzer = await TypeAnalyzer.fromPath('example/samples/merge_sample.dart');
  final typeA = typeAnalyzer.getClass('C')!.thisType;
  final typeB = typeAnalyzer.getClass('D')!.thisType;

  final lattice = Lattice.merged(selectedTypes: [typeA, typeB], typeAnalyzer: typeAnalyzer);

  final lub = typeAnalyzer.lub(typeA, typeB);
  final glb = typeAnalyzer.glb(typeA, typeB);
  print(lattice.toMermaidGraph(
    highlight: [
      typeA,
      typeB,
      lub,
      glb,
    ],
  ));
}
