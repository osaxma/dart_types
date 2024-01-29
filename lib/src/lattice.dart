import 'package:analyzer/dart/element/type.dart';
import 'type_analyzer.dart';

import 'util.dart';

class Lattice {
  late final Map<DartType, Set<DartType> /* subtypes */ > graph;
  final DartType type;
  Lattice({
    required this.type,
    required TypeAnalyzer typeAnalyzer,
  }) {
    if (type is! FunctionType) {
      throw UnimplementedError('Only FunctionType is supported at the moment');
    }

    final types = typeAnalyzer.collectTypesFromFunctionType(type as FunctionType);

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

  String toMermaidGraphCode() {
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

    buff.write('\n\n\n');
    final tag = type.getDisplayString(withNullability: true).hashCode;
    buff.writeln('style $tag color:#7FFF7F');

    return buff.toString();
  }
}
/* 

graph TD
    subgraph "Type hierarchy of int Function(int)"
        O("Object") --> F
        F("Function") --> ON
        ON("Object? Function(Never)") --> IN
        ON --> OI
        IN("int Function(Never)") --> NN
        IN --> II
        OI("Object Function(int)") --> II
        OI --> OO
        NN("Never Function(Never)") --> NI
        II("int Function(int)") --> NI
        II --> IO
        OO("Object? Function(Object?)") --> IO
        NI("Never Function(int)") --> NO
        IO("int Function(Object?)") --> NO
        NO("Never Function(Object?)") --> N           
        N("Never")
    end

 */