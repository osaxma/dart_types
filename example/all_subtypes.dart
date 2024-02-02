import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_types/dart_types.dart';
import 'package:dart_types/src/search.dart';
import 'package:path/path.dart' as p;
import 'package:analyzer/dart/element/element.dart';

// this thing is slow because it analyzes the entire project
void main() async {
  final sw = Stopwatch()..start();

  final path = _getFlutterLibPath();
  final typeToFind = 'StatefulWidget';
  final engine = SimpleSearchEngine(path);
  final type = await engine.findElement(typeToFind);
  final subtypes = <InterfaceElement>[];
  if (type is ClassElement) {
    subtypes.addAll(await engine.findSubtypes(type, recursive: true));
  } else {
    print('could not find $typeToFind');
    exit(0);
  }
  final typeProvider = type.enclosingElement.library.typeProvider;
  final typeSystem = type.enclosingElement.library.typeSystem;

  final allTypes = [
    typeProvider.objectType,
    ...TypeAnalyzer.getSuperTypes(type.thisType, typeProvider),
    type.thisType,
    ...subtypes.map((e) => e.thisType),
    ...subtypes.map((e) => TypeAnalyzer.getSuperTypes(e.thisType, typeProvider)).flattened,
    // typeProvider.neverType,
  ].where((t) => !t.getDisplayString(withNullability: false).startsWith('_')).toList();

  final lattice = Lattice.fromTypes(allTypes, typeSystem);

  final graph = lattice.toMermaidGraph(highlight: [type.thisType]);

  // this will be a huge URL .. but it works
  print(MermaidGraph.generateMermaidUrl(graph));

  print('took ${sw.elapsed.inSeconds}');
  await engine.dispose();
}

String _getFlutterLibPath() {
  var flutterLibPath = Process.runSync('which', ['flutter']).stdout;
  if (flutterLibPath is! String || flutterLibPath.isEmpty) {
    print('could not find flutter path to run this example');
    exit(1);
  }
  flutterLibPath = flutterLibPath.trim();
  flutterLibPath = p.dirname(p.dirname(flutterLibPath)); // remove "bin/flutter" from path
  flutterLibPath = p.join(flutterLibPath, 'packages', 'flutter', 'lib');
  flutterLibPath = p.normalize(p.absolute(flutterLibPath));
  return flutterLibPath;
}
