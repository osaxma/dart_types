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

// Note: This is slow and should only be used to search an entire project/workspace
//       It's slow because we need to resolve the entire project
//       Also, to use `Search.subTypes`, `AnalysisDriver`  needs to be indexed
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
  // `AnalysisDriver.addFile` does some implicit async operations. So if this wasn't async
  // and all the code leading to a method (e.g. `findElement`) was synchronous, it's an issue.
  // That is, the drivers wouldn't have completed all their asynchronous events.
  // And the methods would not return any result even if they should.
  //
  // So we add a delay at the end so all the drivers code in the event loop are processed first.
  // (dear reader, trust me, that wasn't easy to uncover)
  static Future<SimpleSearchEngine> create(String path) async {
    path = p.normalize(p.absolute(path));
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

    // artificial delay (see comment above) so this code is added at the end of the event queue
    // to allow drivers events to be executed first.
    // TODO: find out if the drivers has a method that we can await for.
    await Future.delayed(Duration(microseconds: 1));
    return SimpleSearchEngine._(collection, path);
  }

  Future<InterfaceElement?> findType(String pattern) async {
    for (var driver in drivers) {
      var elements = await driver.search.topLevelElements(RegExp('^$pattern\$'));
      // TODO: do a better job here especially if two types happened to have the same name
      if (elements.isNotEmpty && elements.first is InterfaceElement) {
        return elements.first as InterfaceElement;
      }
    }
    return null;
  }

  Future<Element?> findType2(String pattern) async {
    for (var driver in drivers) {
      var elements = await driver.search.topLevelElements(RegExp('^$pattern\$'));
      // TODO: do a better job here especially if two types happened to have the same name
      if (elements.isNotEmpty) {
        return elements.first;
      }
    }
    return null;
  }

  Future<List<InterfaceElement>> findSubtypes(InterfaceElement element,
      {bool recursive = false, int depth = 10}) async {
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

  Future<List<InterfaceElement>> getAllTypes() async {
    final types = <InterfaceElement>[];
    logger.trace('getAllTypes: start');
    for (var driver in drivers) {
      final res = await driver.search.topLevelElements(RegExp('.*'));
      types.addAll(
        res
            .whereType<InterfaceElement>()
            // remove core libraries
            // Note: if path was `Project/lib/A/`, then all other folders in lib except A are ignored
            .where((element) => p.isWithin(path, element.source.fullName)),
      );
    }
    logger.trace('getAllTypes: end (types length: ${types.length})');
    return types;
  }

  Future<List<TypeDefiningElement>> getAllTypeDefiningElements() async {
    final types = <TypeDefiningElement>[];
    logger.trace('getAllTypeDefiningElements: start');
    for (var driver in drivers) {
      final res = await driver.search.topLevelElements(RegExp('.*'));
      types.addAll(
        res
            .whereType<TypeDefiningElement>()

            // remove core libraries
            // Note: if path was `Project/lib/A/`, then all other folders in lib except A are ignored
            .where((element) =>
                !element.isSynthetic &&
                (path == element.source!.fullName || p.isWithin(path, element.source!.fullName))),
      );
    }
    logger.trace('getAllTypeDefiningElements: end (types length: ${types.length})');
    return types;
  }

  Future<List<InterfaceElement>> findSubtypesForAll(
    List<InterfaceElement> types, {
    bool recursive = false,
    int depth = 10,
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
