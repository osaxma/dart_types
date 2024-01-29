// The following don't seem to be available on the public API so this is the only option for now
// ignore_for_file: implementation_imports
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

import 'misc.dart';

class TypeAnalyzer {
  // not sure yet what we need so they are kept here in case we need them
  final AnalysisContextCollection analysisContextCollection;
  final AnalysisSession analysisSession;
  // this one is pre-computed to avoid async contagiousness or a separate load method
  final LibraryElement libraryElement;

  TypeProvider get typeProvider => libraryElement.typeProvider;
  TypeSystem get typeSystem => libraryElement.typeSystem;

  TypeAnalyzer._(this.libraryElement, this.analysisContextCollection, this.analysisSession);

  // TODO: figure out how to use cashing because this thing is slow
  static Future<TypeAnalyzer> create(String code) async {
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

    return TypeAnalyzer._(libraryElement, collection, analysisSession);
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

  /// Return `true` if the [a] is a subtype of the [b].
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

  List<DartType> getSubTypes(DartType type) {
    final e = type.element;
    final types = <DartType>[];
    if (e is ClassElementImpl) {
      types.addAll(e.allSubtypes ?? []);
    }

    types.add(typeProvider.neverType);

    return types;
  }

  List<DartType> getSuperTypes(DartType type) {
    final e = type.element;

    if (e is TypeAliasElement) {
      // TODO: haven't tested this btw
      return getSuperTypes(e.aliasedType);
    }

    final types = <DartType>[];
    if (e is InterfaceElement) {
      types.addAll(e.allSupertypes);
    } else if (e is FunctionType) {
      // types.add(typeProvider.functionType);
    }

    types.add(typeProvider.objectQuestionType);

    return types;
  }

  List<DartType> collectTypesFromFunctionType(FunctionType type) {
    // final paras = type.parameters;
    final returnType = type.returnType;
    final returnTypes = [...getSubTypes(returnType), returnType, ...getSuperTypes(returnType)];

    final parametersTypes = type.parameters
        .map((p) => [
              // p.type.element is ClassElement, not ParameterElement, so we need to get the element back
              ...getSubTypes(p.type).map((t) => p.copyWith(type: t)),
              p,
              // p.type.element is ClassElement, not ParameterElement, so we need to get the element back
              ...getSuperTypes(p.type).map((t) => p.copyWith(type: t)),
            ])
        .toList();

    final combination = allCombinations(parametersTypes);

    var allTypes = <DartType>[
      typeProvider.objectQuestionType,
      typeProvider.objectType,
      typeProvider.functionType,
      typeProvider.neverType,
    ];
    for (var r in returnTypes) {
      for (var p in combination) {
        for (var i = 0; i < p.length; i++) {
          final t = FunctionTypeImpl(
            typeFormals: [], // TODO: handle type parameters and stuff -- i think?
            parameters: p,
            returnType: r,
            nullabilitySuffix: type.nullabilitySuffix,
          );
          allTypes.add(t);
        }
      }
    }

    allTypes = allTypes.toSet().toList();
    return allTypes;
  }
}
