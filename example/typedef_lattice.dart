import 'package:dart_types/dart_types.dart';

Future<void> main() async {
  final typeAnalyzer = await TypeAnalyzer.fromCode('typedef Func = int Function(int);');
  final type = typeAnalyzer.functionTypes.first;
  final lattice = Lattice(type: type, typeAnalyzer: typeAnalyzer);
  print(lattice.toMermaidGraph(highlight: [type]));
}
