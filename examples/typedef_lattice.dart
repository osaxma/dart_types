import 'package:analyzer/dart/element/type.dart';
import 'package:dartypes/misc.dart';
import 'package:dartypes/session.dart';

final sample = '''
typedef Func = int Function(int);
typedef Func = int Function(num);
''';
Future<void> main() async {
  print('loading code...');
  final session = await Session.create(sample);

  final types = session.getTypes();
  final typeA = types[0] as FunctionType;
  // final typeB = types[1] as FunctionType;

  final allTypes = collectTypesFromFunctionType(typeA, session.typeProvider);
  session.sortType(allTypes);
  allTypes.forEach((t) {
    print(t.getDisplayString(withNullability: true));
  });
  print('total: ${allTypes.length}');
}
