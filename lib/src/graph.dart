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
  late final Map<DartType /* type */, Set<DartType> /* subtypes */ > graph;

  /// The types to be highlighted in the graph.
  final List<DartType> selectedTypes;

  TypeGraph.fromTypes(
    List<DartType> types,
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
    );

    return TypeGraph.fromTypes(collection.allTypes, collection.typeSystem);
  }

  // TODO: I think we should generate a transitive reduction from here directly
  static Map<DartType, List<DartType>> _createTypeMatrix(
      List<DartType> types, TypeSystem typeSystem) {
    logger.trace('_createTypeMatrix start (types length: ${types.length})');
    final matrix = <DartType, List<DartType> /* subtypes */ >{};
    _sortTypes(types, typeSystem);
    for (var t in types) {
      final edges = types
          .where((element) => element != t && typeSystem.isSubtypeOf(element, t))
          .toSet()
          .toList();
      matrix[t] = edges;
    }

    logger.trace('_createTypeMatrix end: (matrix length = ${matrix.length})');

    return matrix;
  }

  static void _sortTypes(List<DartType> types, TypeSystem typeSystem) {
    types.sort((a, b) {
      if (a == b) return 0;

      if (typeSystem.isSubtypeOf(a, b)) {
        return 1;
      }

      if (typeSystem.isSubtypeOf(b, a)) {
        return -1;
      }
      // sort unrelated alphabetically if equal
      return a
          .getDisplayString(withNullability: true)
          .compareTo(b.getDisplayString(withNullability: true));
    });
  }

  MermaidGraph toMermaidGraph({String? graphType}) {
    final pattern = RegExp('<.*>');
    // Transform the graph into from DartTypes to Strings (display names)
    // Note: Avoid using `DartType.hashCode` as nodes in the mermaid graph.
    //       It has lot of collisons for some reason.
    //       Instead, use the display string hashcode.
    final graphAsStrings = <String, Set<String>>{};
    for (var entry in graph.entries) {
      final newKey = entry.key.getDisplayString(withNullability: true).replaceAll(pattern, '');
      final value = entry.value
          .map((e) => e.getDisplayString(withNullability: true).replaceAll(pattern, ''))
          .toSet();
      graphAsStrings.update(newKey, (v) => v..addAll(value), ifAbsent: () => value);

      // TODO: figure out why some node self reference themselves even though they should not
      //       I believe it has to do to the inaccuracy of the transitiveReduction algorithm
      graphAsStrings[newKey]!.remove(newKey);
    }

    final selectedTypesAsStrings =
        selectedTypes.map((e) => e.getDisplayString(withNullability: true)).toList();

    return MermaidGraph(
      graphAsStrings,
      typesToHighLight: selectedTypesAsStrings,
      graphType: graphType,
    );
  }
}
