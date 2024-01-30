import 'package:analyzer/dart/element/type.dart';
import 'type_analyzer.dart';

import 'util.dart';

class Lattice {
  late final Map<DartType, Set<DartType> /* subtypes */ > graph;
  final DartType type;
  Lattice({
    required this.type,
    required TypeAnalyzer typeAnalyzer,
    List<DartType>? types,
  }) {
    if (type is FunctionType) {
      types ??= typeAnalyzer.collectTypesFromFunctionType(type as FunctionType);
    } else if (type is InterfaceType) {
      types ??= typeAnalyzer.collectTypesFromInterfaceType(type as InterfaceType);
    } else {
      throw UnimplementedError('Only InterfaceType or FunctionType are supported but type: $type was given');
    }

    typeAnalyzer.sortTypes(types);
    // TODO: Combine the matrix generation step with the transitive reduction step
    final matrix = <DartType, List<DartType> /* subtypes */ >{};
    for (var t in types) {
      final edges = types.where((element) => element != t && typeAnalyzer.isSubType(element, t)).toList();
      matrix[t] = edges;
    }

    graph = transitiveReduction(matrix);
  }

  Lattice merge(Lattice lattice) => throw UnimplementedError('TODO: implement merging two lattices');

  String toMermaidGraph() {
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
    final tag = type.getDisplayString(withNullability: true).hashCode;
    buff.writeln('style $tag color:#7FFF7F');

    return buff.toString();
  }
}
