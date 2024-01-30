import 'package:dart_types/dart_types.dart';

Future<void> main() async {
  final typeAnalyzer = await TypeAnalyzer.fromCode('typedef Func = int Function(int);');
  final type = typeAnalyzer.getFunctionTypes().first;
  final lattice = Lattice(type: type, typeAnalyzer: typeAnalyzer);
  print(lattice.toMermaidGraph());
}
