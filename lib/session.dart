// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

class Session {
  // not sure yet what we need so they are kept here in case we need them
  final AnalysisContextCollection analysisContextCollection;
  final AnalysisSession analysisSession;
  // this one is pre-computed to avoid async contagiousness or a separate load method
  final LibraryElement libraryElement;

  TypeProvider get typeProvider => libraryElement.typeProvider;
  TypeSystem get typeSystem => libraryElement.typeSystem;

  Session._(this.libraryElement, this.analysisContextCollection, this.analysisSession);

  // TODO: figure out how to use cashing because this thing is slow
  static Future<Session> create(String code) async {
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

    return Session._(libraryElement, collection, analysisSession);
  }

  List<ClassElement> getClasses() {
    libraryElement.units.first.classes.toList();
    return libraryElement.units.first.classes;
  }

  List<DartType> getTypes() {
    final types = libraryElement.units.first.typeAliases.map((e) => e.aliasedType).toList();
    return types;
  }

  List<DartType> allTypes() {
    final allTypes = <DartType>[];
    allTypes.addAll(getClasses().map((e) => e.thisType));
    allTypes.addAll(getTypes());
    return allTypes;
  }

  DartType lub(DartType a, DartType b) {
    return libraryElement.typeSystem.leastUpperBound(a, b);
  }

  DartType glb(DartType a, DartType b) {
    return libraryElement.typeSystem.greatestLowerBound(a, b);
  }

  bool isSubType(DartType a, DartType b) {
    return libraryElement.typeSystem.isSubtypeOf(a, b);
  }

  // ignore: unused_element
  void _tmp() {
    libraryElement.typeProvider.doubleType;
  }

  void sortType(List<DartType> types) {
    types.sort((a, b) => a == b
        ? 0
        : isSubType(a, b)
            ? 1
            : -1);
  }
}
