import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as p;

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

/// Return the [transitive reduction][] of [graph]
///
/// [transitive reduction]:https://en.wikipedia.org/wiki/Transitive_reduction
// note: this was copied from `package:collection` (transitiveClosure) and one line was modified for reduction
//       i.e. delete edges instead of adding them
Map<T, Set<T>> transitiveReduction<T>(Map<T, Iterable<T>> graph) {
// algorithm TLDR:
// foreach x in graph.vertices
//    foreach y in graph.vertices
//       foreach z in graph.vertices
//          delete edge xz if edges xy and yz exist
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

// TODO: figure out how to use caching because this thing is slow
//       at least cache the sdk
Future<LibraryElement> getLibraryElementFromCodeString(String code) async {
  // this can be anything since we are using an overlay resource provider
  final filePath = '/code.dart';
  final collection = AnalysisContextCollection(
    includedPaths: [filePath],
    resourceProvider: OverlayResourceProvider(
      PhysicalResourceProvider(),
    )..setOverlay(
        filePath,
        content: code,
        modificationStamp: 0,
      ),
  );

  final analysisSession = collection.contextFor(filePath).currentSession;

  final libraryElement = await analysisSession
      .getLibraryByUri('file://$filePath')
      .then((libraryResult) => (libraryResult as LibraryElementResult).element);
  return libraryElement;
}

Future<LibraryElement> getLibraryElementFromFile(String path) async {
  path = p.absolute(path);

  if (!File(path).existsSync()) {
    throw Exception('File does not exists: $path');
  }

  final collection = AnalysisContextCollection(includedPaths: [path]);
  final session = collection.contexts[0].currentSession;
  final resolvedUnit = await session.getResolvedLibrary(path) as ResolvedLibraryResult;

  return resolvedUnit.element;
}
