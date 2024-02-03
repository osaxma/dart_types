// import 'dart:developer';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:dart_types/dart_types.dart';
import 'package:dart_types/src/search.dart';
// import 'package:path/path.dart' as p;

// this thing is slow because it analyzes the entire flutter library
void main() async {
  final path = '/Users/osaxma/.pub-cache/hosted/pub.dev/provider-6.0.5/lib';

  final engine = await SimpleSearchEngine.create(path);
  final types = await engine.getAllTypes();
  // final typeProvider = types.first.enclosingElement.library.typeProvider;
  final typeSystem = types.first.enclosingElement.library.typeSystem;

  final subtypesFuture = <Future<List<InterfaceElement>>>[];
  for (var type in types) {
    // only add subtypes to types within the given library
    subtypesFuture.add(engine.findSubtypes(type, recursive: false));
  }
  final allSubTypes = (await Future.wait(subtypesFuture)).flattened;

  final allTypes = <DartType>[
    // typeProvider.objectType,
    // add super types
    ...types.map((t) => t.allSupertypes).flattened,
    // add the types themselves
    ...types.map((t) => t.thisType),
    // add the subtypes
    ...allSubTypes.map((t) => t.thisType),
    // typeProvider.neverType,
  ].where((t) => !t.getDisplayString(withNullability: false).startsWith('_')).toSet().toList();

  final lattice = Lattice.fromTypes(allTypes, typeSystem);

  final graph = lattice.toMermaidGraph2();
  print(graph);
  print('');

  // this will be a huge URL .. but it works
  print(MermaidGraph.generateMermaidUrl(graph));

  await engine.dispose();
}
