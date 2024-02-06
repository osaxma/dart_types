import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:dart_types/src/collector.dart';

import 'mermaid.dart';
import 'util.dart';

/// A Helper class with static methods to construct and store a [graph] of dart types hierarchy.
class TypeGraph {
  /// The [graph] is simply a Map consiting of:
  /// - Keys -> A [DartType] (i.e. node)
  /// - Values -> List of all known subtypes (i.e. edges)
  late final Map<DartType2 /* type */, Set<DartType2> /* subtypes */ > graph;

  /// The types to be highlighted in the graph.
  final List<DartType2> selectedTypes;

  TypeGraph.fromTypes(
    List<DartType2> types,
    TypeSystem typeSystem, [
    this.selectedTypes = const [],
  ]) {
    final matrix = _createTypeMatrix(types, typeSystem);

    graph = transitiveReduction(matrix);
  }

  static Future<TypeGraph> generateForInterfaceTypes({
    required String path,
    List<String> filters = const [],
    List<String> selectedTypes = const [],
  }) async {
    final collection = await TypesCollector.collectTypeInfoForInterfaceTypes(
      path: path,
      selectedTypes: selectedTypes,
      filters: filters, // privates
      sortedBySubTypes: true,
    );

    return TypeGraph.fromTypes(
      collection.allTypes,
      collection.typeSystem,
      collection.selectedTypes,
    );
  }

  static Future<TypeGraph> generateForFunctionType({
    required String path,
    required String functionName,
    List<String> filters = const [],
  }) async {
    final collection = await TypesCollector.collectTypeInfoForFunctionTypes(
      path: path,
      functionName: functionName,
      filters: filters,
      sortedBySubTypes: true,
    );

    return TypeGraph.fromTypes(collection.allTypes, collection.typeSystem);
  }

  // TODO: I think we should generate a transitive reduction from here directly
  static Map<DartType2, Set<DartType2>> _createTypeMatrix(
    List<DartType2> types,
    TypeSystem typeSystem,
  ) {
    logger.trace('_createTypeMatrix start (types length: ${types.length})');

    final matrix = <DartType2, Set<DartType2> /* subtypes */ >{};

    for (var t in types) {
      final edges = types
          .where((element) => element != t && typeSystem.isSubtypeOf(element.type, t.type))
          .map((t) => DartType2(type: t.type))
          .toSet();
      matrix[t] = edges;
    }

    logger.trace('_createTypeMatrix end: (matrix length = ${matrix.length})');

    return matrix;
  }

  MermaidGraph toMermaidGraph({String? graphType}) {
    final pattern = RegExp('<.*>');
    // Transform the graph into from DartTypes to Strings (display names)
    // Note: Avoid using `DartType.hashCode` as nodes in the mermaid graph.
    //       It has lot of collisons for some reason.
    //       Instead, use the display string hashcode.
    final graphAsStrings = <String, Set<String>>{};
    for (var entry in graph.entries) {
      final newKey = entry.key.name.replaceAll(pattern, '');
      final value = entry.value.map((e) => e.name.replaceAll(pattern, '')).toSet();
      graphAsStrings.update(newKey, (v) => v..addAll(value), ifAbsent: () => value);

      // TODO: figure out why some node self reference themselves even though they should not
      //       I believe it has to do to the inaccuracy of the transitiveReduction algorithm
      graphAsStrings[newKey]!.remove(newKey);
    }

    final selectedTypesAsStrings = selectedTypes.map((e) => e.name).toList();

    return MermaidGraph(
      graphAsStrings,
      typesToHighLight: selectedTypesAsStrings,
      graphType: graphType,
    );
  }
}
