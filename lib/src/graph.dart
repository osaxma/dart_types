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
  late final Map<DartTypeWrapped /* type */, Set<DartTypeWrapped> /* subtypes */ > graph;

  /// The types to be highlighted in the graph.
  final List<DartTypeWrapped> selectedTypes;

  TypeGraph.fromTypes(
    List<DartTypeWrapped> types,
    TypeSystem typeSystem, [
    this.selectedTypes = const [],
  ]) {
    logger.trace('TypeGraph - (transitiveReduction) start: (types length: ${types.length})');
    graph = transitiveReduction(types, (a, b) => typeSystem.isSubtypeOf(a.type, b.type));
    logger.trace('TypeGraph - (transitiveReduction) end:   (graph length = ${graph.length})');
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
