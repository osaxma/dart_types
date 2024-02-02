// --- the following are not public APIs but only way to do what we want
// ignore_for_file: implementation_imports
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
// -----
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:analyzer/dart/element/element.dart';

// Note: This is slow and should only be used to search an entire project/workspace
//       It's slow because we need to resolve the entire project
//       Also, to use `Search.subTypes`, `AnalysisDriver`  needs to be indexed
class SimpleSearchEngine {
  late final String path;

  // we need to use the implementation so we can access drivers, search and enable indexing (so we can search subtypes)
  late final collection = AnalysisContextCollectionImpl(includedPaths: [path], enableIndex: true);
  List<AnalysisDriver> get drivers => collection.contexts.map((e) => e).map((e) => e.driver).toList();

  SimpleSearchEngine(String path) {
    this.path = p.normalize(p.absolute(path));

    // this step is necessary
    for (var analysisContext in collection.contexts) {
      for (var path in analysisContext.contextRoot.analyzedFiles()) {
        analysisContext.driver.addFile(path);
      }
    }
  }

  Future<Element?> findElement<T extends Element>(String pattern) async {
    // if all the code leading to here was synchronous, we can have an issue where the drivers haven't completed
    // all their asynchronous code and we may not get a result even if there should be one.
    // so we add a delay here to the execution so all the drivers events in the event loop are processed first.
    // (not sure if there is something in the drivers that we can await for (eg `await driver.isReady`))
    await Future.delayed(Duration(microseconds: 1)); // remove this, and you will get nothing....
    for (var driver in drivers) {
      var elements = await driver.search.topLevelElements(RegExp('^$pattern\$'));
      if (elements.isNotEmpty && elements.first is T) {
        return elements.first;
      }
    }
    return null;
  }

  Future<List<InterfaceElement>> findSubtypes(InterfaceElement element, {bool recursive = false}) async {
    final subtypes = <InterfaceElement>[];
    for (var driver in drivers) {
      final res = await driver.search.subTypes(element, SearchedFiles());
      subtypes.addAll(res.map((e) => e.enclosingElement).whereType<InterfaceElement>());
    }
    if (recursive && subtypes.isNotEmpty) {
      final futures = <Future<List<InterfaceElement>>>[];
      for (var subtype in subtypes) {
        futures.add(findSubtypes(subtype, recursive: recursive));
      }
      await Future.wait(futures).then((value) => subtypes.addAll(value.flattened));
    }
    return subtypes;
  }

  Future<void> dispose() async {
    await collection.dispose();
  }
}
