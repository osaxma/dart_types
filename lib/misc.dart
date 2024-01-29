// gracias a lrhn: https://stackoverflow.com/a/68816742/10976714
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

// algorithm:
// foreach x in graph.vertices
//    foreach y in graph.vertices
//       foreach z in graph.vertices
//          delete edge xz if edges xy and yz exist
//
// note: this was copied from `package:collection` (transitiveClosure) and modified it for reduction
//       i.e. instead of `add edge`, we `delete edge`
Map<T, Set<T>> transitiveReduction<T>(Map<T, Iterable<T>> graph) {
  var result = <T, Set<T>>{};
  graph.forEach((vertex, edges) {
    result[vertex] = Set<T>.from(edges);
  });

  var keys = graph.keys.toList();
  for (var vertex1 in keys) {
    for (var vertex2 in keys) {
      for (var vertex3 in keys) {
        if (result[vertex2]!.contains(vertex1) && result[vertex1]!.contains(vertex3)) {
          result[vertex2]!.remove(vertex3); // modified this line only
        }
      }
    }
  }

  return result;
}
