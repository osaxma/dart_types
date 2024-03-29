import 'dart:io';
import 'dart:typed_data';

import 'package:analyzer/dart/element/type.dart';
import 'package:cli_util/cli_logging.dart';

/// Generate all possible combination for elements in multiple lists.
// gracias a @lrhn: https://stackoverflow.com/a/68816742/10976714
Iterable<List<T>> allCombinations<T>(List<List<T>> sources) sync* {
  if (sources.isEmpty || sources.any((l) => l.isEmpty)) {
    yield [];
    return;
  }
  var indices = List<int>.filled(sources.length, 0);
  var next = 0;
  while (true) {
    yield [for (var i = 0; i < indices.length; i++) sources[i][indices[i]]];
    while (true) {
      var nextIndex = indices[next] + 1;
      if (nextIndex < sources[next].length) {
        indices[next] = nextIndex;
        break;
      }
      next += 1;
      if (next == sources.length) return;
    }
    indices.fillRange(0, next, 0);
    next = 0;
  }
}

/// Return the [Transitive Reduction] for a directed acyclic graph (DAG).
///
/// This function assumes the graph is acyclic and it doesn't check for that.
///
/// [nodes] should be a list of all nodes in the graph.
///
/// [hasPath] should return `true` when the first argument has a path to the second argument.
/// > Note: [hasPath] should return `true` when there is a **path**, not only an edge.
///
/// This function is a port of [jgrapht][] implementation of Harry Hsu's paper:
/// "An Algorithm for Finding a Minimal Equivalent Graph of a Digraph" ([doi][])
///
/// [Transitive Reduction]: https://en.wikipedia.org/wiki/Transitive_reductio
/// [jgrapht]: https://github.com/jgrapht/jgrapht/blob/master/jgrapht-core/src/main/java/org/jgrapht/alg/TransitiveReduction.java
/// [doi]: https://doi.org/10.1145/321864.321866
Map<T, Set<T>> transitiveReduction<T>(List<T> nodes, bool Function(T from, T to) hasPath) {
  
  final length = nodes.length; // square matrix (#row == #col == length)
  final dimension = length * length;
  final pathMatrix = Uint8List(dimension);

  int index(int row, int col) => (row * length) + col;

  // Create the path matrix
  // "1" indicates a path and "0" indicates no path
  for (var i = 0; i < length; i++) {
    for (var j = 0; j < length; j++) {
      // don't create a path from a node to itself.
      if (i == j) continue;
      if (hasPath(nodes[i], nodes[j])) {
        pathMatrix[index(i, j)] = 1;
      }
    }
  }

  // Reduce the graph in the path matrix
  for (var i = 0; i < length; i++) {
    for (var j = 0; j < length; j++) {
      if (pathMatrix[index(i, j)] > 0) {
        for (var k = 0; k < length; k++) {
          if (pathMatrix[index(j, k)] > 0) {
            pathMatrix[index(i, k)] = 0;
          }
        }
      }
    }
  }

  // Create the reduced graph with the original nodes
  final reducedGraph = <T, Set<T>>{};
  for (var i = 0; i < length; i++) {
    final rowIndex = index(i, 0);
    final row = pathMatrix.sublist(rowIndex, rowIndex + length);
    final set = <T>{};
    for (var j = 0; j < row.length; j++) {
      if (row[j] > 0) {
        set.add(nodes[j]);
      }
    }
    reducedGraph[nodes[i]] = set;
  }

  return reducedGraph;
}

/// Throws an Exception if [path] is not an existing [File] or [Directory].
void throwIfPathIsNotValid(String path) {
  if (!File(path).existsSync() && !Directory(path).existsSync()) {
    throw Exception('Path is not a valid File or Directory: $path');
  }
}

/* -------------------------------------------------------------------------- */
/*                                   LOGGING                                  */
/* -------------------------------------------------------------------------- */
bool verbose = false; // YOLO
Logger? _logger;
Logger get logger => _logger ??= verbose ? Logger.verbose() : Logger.standard();

/// A wrapper around [DartType] mainly to override hashCode and equality
///
/// The [DartType.hashCode] seem to have a lot of collosions even for small libararies
/// making its usage unreliable as a key to Hash Maps or Sets.
// ^ I observed this when generating the mermaid graph as there were many duplicate hash codes.
class DartTypeWrapped {
  final DartType type;
  final String name;

  DartTypeWrapped({required this.type}) : name = type.getDisplayString(withNullability: false);

  @override
  int get hashCode => type.hashCode; // use the display name String as hashCode

  @override
  bool operator ==(Object other) {
    if (other is! DartTypeWrapped) return false;
    // return name == other.name && other.type == type;
    return other.type == type;
  }

  @override
  String toString() {
    return name;
  }
}
