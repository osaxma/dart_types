// --- the following are not public APIs but only way to do what we want
// ignore_for_file: implementation_imports
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
// -----
import 'package:collection/collection.dart';
import 'package:dart_types/src/util.dart';
import 'package:path/path.dart' as p;
import 'package:analyzer/dart/element/element.dart';

class SimpleSearchEngine {
  // We need to use the implementation so we can access drivers, search and
  // enable indexing (so we can search subtypes)
  final AnalysisContextCollectionImpl collection;

  final String path;

  List<AnalysisDriver> get drivers =>
      collection.contexts.map((e) => e).map((e) => e.driver).toList();

  SimpleSearchEngine._(this.collection, this.path);

  // Even though there's no real asynchronous work here, this is intentionally async.
  //
  // `AnalysisDriver.addFile` does some implicit async operations. So if this method wasn't async,
  // and all the code leading to a search method (e.g. `getAllTypeDefiningElements`) was synchronous,
  // we won't get any results from the methods.
  //
  // To overcome this issue, we add an asynchronous event at the end of this method and wait for it
  // to be completed. This way, we make sure all the other events in the event queue are processsed
  // first (i.e. the drivers events of adding files).
  static Future<SimpleSearchEngine> create(String path) async {
    path = p.normalize(p.absolute(path));
    throwIfPathIsNotValid(path);
    final collection = AnalysisContextCollectionImpl(
      includedPaths: [path],
      enableIndex: true,
    );
    // print(collection.contexts[0].contextRoot.packagesFile);
    for (var analysisContext in collection.contexts) {
      for (var path in analysisContext.contextRoot.analyzedFiles()) {
        analysisContext.driver.addFile(path);
      }
    }

    // Artificial delay (see comment above) so this code is added at the end of the event queue
    // to allow drivers events to be executed first.
    // TODO: find out if the drivers has a method that we can await for.
    // (dear reader, trust me, that wasn't easy to uncover)
    await Future.delayed(Duration(microseconds: 1));
    return SimpleSearchEngine._(collection, path);
  }

  /* -------------------------------------------------------------------------- */
  /*                                   QUERIES                                  */
  /* -------------------------------------------------------------------------- */

  Future<List<TypeDefiningElement>> getAllTypeDefiningElements() async {
    final types = <TypeDefiningElement>[];
    logger.trace('getAllTypeDefiningElements: start');
    for (var driver in drivers) {
      final res = await driver.search.topLevelElements(RegExp('.*'));
      types.addAll(
        res
            .whereType<TypeDefiningElement>()
            // Filter types specific to the given path
            // Note: if the path was `pkg/lib/A/`, then all folders in `pkg/lib/` are ignored
            //       except folder `A`.
            .where((element) =>
                !element.isSynthetic &&
                (path == element.source!.fullName || p.isWithin(path, element.source!.fullName))),
      );
    }
    logger.trace('getAllTypeDefiningElements: end (types length: ${types.length})');
    return types;
  }

  Future<List<InterfaceElement>> findSubtypes(
    InterfaceElement element, {
    bool recursive = false,
    // just a safeguard
    int depth = 50,
  }) async {
    final subtypes = <InterfaceElement>[];
    for (var driver in drivers) {
      final res = await driver.search.subTypes(element, SearchedFiles());
      subtypes.addAll(res.map((e) => e.enclosingElement).whereType<InterfaceElement>());
    }
    if (recursive && subtypes.isNotEmpty && depth > 0) {
      final futures = <Future<List<InterfaceElement>>>[];
      for (var subtype in subtypes) {
        futures.add(findSubtypes(subtype, recursive: recursive, depth: depth - 1));
      }
      await Future.wait(futures).then((value) => subtypes.addAll(value.flattened));
    }
    return subtypes;
  }

  Future<List<InterfaceElement>> findSubtypesForAll(
    List<InterfaceElement> types, {
    bool recursive = false,
    // just a safeguard
    int depth = 50,
  }) async {
    final subTypesFutures = <Future<List<InterfaceElement>>>[];
    logger.trace('findSubtypesForAll: start (types length: ${types.length})');
    for (var type in types) {
      subTypesFutures.add(findSubtypes(type, recursive: recursive, depth: depth));
    }

    final allSubtypes =
        await Future.wait(subTypesFutures).then((value) => value.flattened.toList());

    logger.trace('findSubtypesForAll: end (all subtypes length: ${allSubtypes.length})');
    return allSubtypes;
  }

  Future<void> dispose() async {
    await collection.dispose();
  }
}
