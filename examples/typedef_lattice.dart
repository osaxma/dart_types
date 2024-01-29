import 'package:analyzer/dart/element/type.dart';
import 'package:dartypes/lattice.dart';
import 'package:dartypes/type_analyzer.dart';

final sample = '''
typedef Func = int Function(int);
typedef Func = Object Function();
''';
Future<void> main() async {
  print('loading code...');
  final typeAnalyzer = await TypeAnalyzer.create(sample);

  final types = typeAnalyzer.getTypes();
  final typeA = types[1] as FunctionType;
  // final typeB = types[1] as FunctionType;

  final allTypes = typeAnalyzer.collectTypesFromFunctionType(typeA);
  typeAnalyzer.sortType(allTypes);
  allTypes.forEach((t) {
    print(t.getDisplayString(withNullability: true));
  });
  print('total: ${allTypes.length}');

  final lattice = Lattice(allTypes, typeAnalyzer);

  print('-------------------');
  for (var entry in lattice.graph.entries) {
    print('${entry.key} -> ${entry.value}');
  }
}
