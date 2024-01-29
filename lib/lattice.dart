import 'package:analyzer/dart/element/type.dart';
import 'package:dartypes/type_analyzer.dart';

import 'misc.dart';

class Lattice {
  late final Map<DartType, Set<DartType> /* subtypes */ > graph;

  Lattice(List<DartType> types, TypeAnalyzer typeAnalyzer) {
    // TODO: Combine the matrix generation step with the transitive reduction step
    final matrix = <DartType, List<DartType> /* subtypes */ >{};
    for (var t in types) {
      final edges = types.where((element) => element != t && typeAnalyzer.isSubType(element, t)).toList();
      matrix[t] = edges;
    }

    graph = transitiveReduction(matrix);
  }

  Lattice merge(Lattice lattice) => throw UnimplementedError('TODO: implement merging two lattices');

  String toMermaidGraphCode() => throw UnimplementedError('TODO: implement mermaid graph generation');
}

class Node {
  final DartType type;
  final List<Node> edges;

  Node({required this.type, required this.edges});
}
