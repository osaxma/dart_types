import 'dart:io';

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

/// Returns the [transitive reduction][] of [graph].
///
/// [transitive reduction]: https://en.wikipedia.org/wiki/Transitive_reduction
///
/// Interprets [graph] as a directed graph with a vertex for each key and edges
/// from each key to the values that the key maps to.
///
/// Assumes that every vertex in the graph has a key to represent it, even if
/// that vertex has no outgoing edges. This isn't checked, but if it's not
/// satisfied, the function may crash or provide unexpected output. For example,
/// `{"a": ["b"]}` is not valid, but `{"a": ["b"], "b": []}` is.
// note: this was copied from `package:collection` (transitiveClosure) and one line was modified for reduction
//       i.e. delete edges instead of adding them
// TODO: this isn't accurate (e.g. ` A -> B -> C -> D; A -> C; A-> D` won't remove A->D)
Map<T, Set<T>> transitiveReduction<T>(Map<T, Iterable<T>> graph) {
  logger.trace('transitiveReduction start (graph length: ${graph.length})');
  var result = <T, Set<T>>{};
  graph.forEach((vertex, edges) {
    result[vertex] = Set<T>.from(edges.where((element) => element != vertex));
  });

  // Lists are faster to iterate than maps, so we create a list since we're
  // iterating repeatedly.
  var keys = graph.keys.toList();
  for (var vertex1 in keys) {
    for (var vertex2 in keys) {
      for (var vertex3 in keys) {
        if (result[vertex1]!.contains(vertex2) && result[vertex2]!.contains(vertex3)) {
          result[vertex1]!.remove(vertex3);
        }
      }
    }
  }
  logger.trace('transitiveReduction end: (result length = ${result.length})');
  return result;
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
