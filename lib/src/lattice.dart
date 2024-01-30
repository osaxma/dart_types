import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'type_analyzer.dart';

import 'util.dart';

class Lattice {
  late final Map<DartType, Set<DartType> /* subtypes */ > graph;

  Lattice({
    required DartType type,
    required TypeAnalyzer typeAnalyzer,
    List<String> filter = const [],
  }) {
    final types = _collectTypes(type, typeAnalyzer, filter);
    final matrix = _createTypeMatrix(types, typeAnalyzer);
    graph = transitiveReduction(matrix);
  }

  Lattice.merged({
    required List<DartType> selectedTypes,
    required TypeAnalyzer typeAnalyzer,
    List<String> filter = const [],
  }) {
    selectedTypes = selectedTypes.map((t) => _collectTypes(t, typeAnalyzer, filter)).flattened.toList();
    typeAnalyzer.sortTypes(selectedTypes);
    final matrix = _createTypeMatrix(selectedTypes, typeAnalyzer);
    graph = transitiveReduction(matrix);
  }

  String toMermaidGraph({List<DartType>? highlight}) {
    final buff = StringBuffer();

    final tags = <int>{};

    buff.writeln('graph TD');
    for (var entry in graph.entries) {
      final from = entry.key.getDisplayString(withNullability: true);
      // note: do not use `DartType.hashCode` -- a lot of collisons there.
      //       so we use the display string hashcode instead
      final fromTag = from.hashCode;
      for (var type in entry.value) {
        final to = type.getDisplayString(withNullability: true);
        final toTag = to.hashCode;

        buff.write('  ${fromTag}');
        if (tags.add(fromTag)) {
          buff.write('("$from")');
        }
        buff.write(' --> $toTag');
        if (tags.add(toTag)) {
          buff.write('("$to")');
        }
        buff.writeln();
      }
    }

    buff.write('\n\n');
    if (highlight != null) {
      for (var type in highlight) {
        final tag = type.getDisplayString(withNullability: true).hashCode;
        buff.writeln('style $tag color:#7FFF7F');
      }
    }

    return buff.toString();
  }

  static List<DartType> _collectTypes(DartType type, TypeAnalyzer typeAnalyzer, List<String> filter,
      [bool sorted = true]) {
    final List<DartType> types;
    if (type is FunctionType) {
      types = typeAnalyzer.collectTypesFromFunctionType(type);
    } else if (type is InterfaceType) {
      types = typeAnalyzer.collectTypesFromInterfaceType(type);
    } else {
      throw UnimplementedError('Only InterfaceType or FunctionType are supported but type: $type was given');
    }
    if (filter.isNotEmpty) {
      types.removeWhere((t) {
        var typeName = t.getDisplayString(withNullability: false);
        // TODO: maybe we need to make the interpolated value as raw if it contains `$` or something else
        return filter.map((e) => RegExp('(?![^a-zA-Z0-9_])$e(?=[^a-zA-Z0-9_])')).any((f) => typeName.contains(f));
      });
    }
    if (sorted) {
      typeAnalyzer.sortTypes(types);
    }
    return types;
  }

  static Map<DartType, List<DartType>> _createTypeMatrix(List<DartType> types, TypeAnalyzer typeAnalyzer) {
    final matrix = <DartType, List<DartType> /* subtypes */ >{};
    for (var t in types) {
      final edges = types.where((element) => element != t && typeAnalyzer.isSubType(element, t)).toList();
      matrix[t] = edges;
    }

    return matrix;
  }
}
