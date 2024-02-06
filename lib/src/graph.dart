import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:dart_types/src/collector.dart';

import 'mermaid.dart';
import 'util.dart';

class TypeGraph {
  late final Map<DartType /* nodes */, Set<DartType> /* edges | subtypes */ > graph;
  final List<DartType> selectedTypes;

  TypeGraph.fromTypes(List<DartType> types, TypeSystem typeSystem,
      [this.selectedTypes = const []]) {
    final matrix = _createTypeMatrix(types, typeSystem);

    graph = transitiveReduction(matrix);
  }

  static Future<TypeGraph> generateForInterfaceTypes({
    required String path,
    List<String> filters = const [],
    List<String> selectedTypes = const [],
  }) async {
    final collection = await TypesCollection.collectTypeInfoForInterfaceTypes(
      path: path,
      selectedTypes: selectedTypes,
      filters: filters, // privates
    );

    return TypeGraph.fromTypes(
        collection.allTypes, collection.typeSystem, collection.selectedTypes);
  }

  static Future<TypeGraph> generateForFunctionType({
    required String path,
    required String functionName,
    List<String> filters = const [],
    List<String> selectedTypes = const [],
  }) async {
    final collection = await TypesCollection.collectTypeInfoForFunctionTypes(
      path: path,
      functionName: functionName,
      filters: filters, // privates
    );

    return TypeGraph.fromTypes(collection.allTypes, collection.typeSystem);
  }

  static Map<DartType, List<DartType>> _createTypeMatrix(
      List<DartType> types, TypeSystem typeSystem) {
    logger.trace('_createTypeMatrix start (types length: ${types.length})');
    final matrix = <DartType, List<DartType> /* subtypes */ >{};
    sortTypes(types, typeSystem);
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

  // // Note:
  // static Map<DartType, List<DartType>> _createTypeMatrix2(
  //     List<DartType> types, TypeSystem typeSystem) {
  //   logger.trace('_createTypeMatrix2 start (types length: ${types.length})');
  //   sortTypes(types, typeSystem);
  //   final matrix = <DartType, List<DartType> /* subtypes */ >{};
  //   final edges = <DartType>[];

  //   for (var i = types.length - 1; i > 0; i--) {
  //     if (!typeSystem.isSubtypeOf(types[i], types[i - 1])) {
  //       matrix[types[i - 1]] = edges;
  //       edges.clear();
  //     } else {
  //       edges.add(types[i]);
  //     }
  //   }

  //   logger.trace('_createTypeMatrix2 end: (matrix length = ${matrix.length})');

  //   return matrix;
  // }

  static void sortTypes(List<DartType> types, TypeSystem typeSystem) {
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

  MermaidGraph toMermaidGraph({String? graphType}) => MermaidGraph(
        graph,
        typesToHighLight: selectedTypes,
        graphType: graphType,
      );
}