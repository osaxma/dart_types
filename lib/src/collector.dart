// The following don't seem to be available on the public API so this is the only option for now
// ignore_for_file: implementation_imports
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:collection/collection.dart';
import 'package:dart_types/src/util.dart';

import 'search.dart';

/// A Helper class for collecting all types related to different dart types.
///
/// See:
/// - [TypesCollector.collectTypeInfoForInterfaceTypes] to collect types for interfaces.
/// - [TypesCollector.collectTypeInfoForFunctionTypes] to build lattice for FunctionType.
class TypesCollector {
  /// If given,
  final List<DartType> selectedTypes;

  /// All the types that were collected/generated for the given [selectedTypes] or libraries.
  final List<DartType> allTypes;

  /// Cached [typeSystem] that can be used for obtaining core types or determining if one type
  /// is a subtype of another.
  // NOTE: The element model of the analyzer package have a separate `TypeSystem` per`LibraryElement`.
  //       Though, for our usage of getting coretypes or determining subtypes, any `typeSystem`
  //       seem to work (within the same project).
  final TypeSystem typeSystem;

  TypesCollector._({
    required this.allTypes,
    required this.selectedTypes,
    required this.typeSystem,
  });

  static Future<TypesCollector> collectTypeInfoForInterfaceTypes({
    required String path,
    List<String> filters = const [],
    List<String> selectedTypes = const [],
    bool sortedBySubTypes = true,
  }) async {
    final engine = await SimpleSearchEngine.create(path);
    final elements = <InterfaceElement>[];

    final typeDefiningElements = await engine.getAllTypeDefiningElements();

    for (var t in typeDefiningElements) {
      if (t is InterfaceElement) {
        elements.add(t);
      } else if (t is TypeAliasElement) {
        if (t.aliasedElement is InterfaceElement) {
          elements.add(t.aliasedElement as InterfaceElement);
        }
      }
    }

    final typesToHighlight = <DartType>[];
    if (selectedTypes.isNotEmpty) {
      elements.removeWhere((element) => !selectedTypes.contains(element.displayName));

      typesToHighlight.addAll(elements.map((e) {
        return e.thisType;
      }));
    }

    if (typesToHighlight.length != selectedTypes.length) {
      final buff = StringBuffer();
      buff.writeln('could not find the following selected type(s):');
      for (var selectedType in selectedTypes) {
        if (!typesToHighlight
            .any((t) => t.getDisplayString(withNullability: false) == selectedType)) {
          buff.writeln('- $selectedType');
        }
      }
      buff.writeln('To view available types, run the following command:');
      buff.writeln('     dart_types list -p $path');

      throw TypeNotFoundException(buff.toString());
    }

    if (elements.isEmpty) {
      throw TypeNotFoundException('No types were found at the given path: $path');
    }

    // hacky though works.
    final typeSystem = elements.first.library.typeSystem;

    elements.addAll(await engine.findSubtypesForAll(elements, recursive: true));

    final allTypes = <DartType>[
      ...elements.map((e) => e.allSupertypes).flattened,
      ...elements.map((e) => e.thisType),
    ];

    _filterTypes(allTypes, filters);

    await engine.dispose();

    if (sortedBySubTypes) {
      sortTypes(allTypes, typeSystem);
    }

    return TypesCollector._(
      allTypes: allTypes.toSet().toList(),
      selectedTypes: typesToHighlight,
      typeSystem: typeSystem,
    );
  }

  static Future<TypesCollector> collectTypeInfoForFunctionTypes({
    required String path,
    required String functionName,
    List<String> filters = const [],
    bool sortedBySubTypes = true,
  }) async {
    final engine = await SimpleSearchEngine.create(path);

    final typeDefiningElements = await engine.getAllTypeDefiningElements();

    late TypeAliasElement element;
    FunctionType? functionType;
    for (var t in typeDefiningElements) {
      if (t is TypeAliasElement) {
        final aliasedType = t.aliasedType;
        if (aliasedType is FunctionType) {
          if (aliasedType.getDisplayString(withNullability: true) == functionName ||
              t.name == functionName) {
            functionType = aliasedType;
            element = t;
            break;
          }
        }
      }
    }

    if (functionType == null) {
      final buff = StringBuffer();
      buff.writeln('could not find the FunctionType with name: $functionName');
      buff.writeln('To view available types, run the following command:');
      buff.writeln('     dart_types list -p $path');
      throw TypeNotFoundException(buff.toString());
    }

    final allTypes = collectTypesFromFunctionType(functionType, element.library.typeProvider);

    if (sortedBySubTypes) {
      sortTypes(allTypes, element.library.typeSystem);
    }

    return TypesCollector._(
      allTypes: allTypes,
      selectedTypes: [functionType],
      typeSystem: element.library.typeSystem,
    );
  }

  static void _filterTypes(List<DartType> types, List<String> filters) {
    final patterns = filters.map((e) => RegExp(e));
    types.removeWhere((t) =>
        patterns.any((regexp) => regexp.hasMatch(t.getDisplayString(withNullability: true))));
  }

  static void sortTypes(List<DartType> types, TypeSystem typeSystem) {
    types.sort((a, b) {
      if (a == b) return 0;

      if (typeSystem.isSubtypeOf(a, b)) {
        return 1;
      }

      if (typeSystem.isSubtypeOf(b, a)) {
        return -1;
      }
      // sort unrelated alphabetically if equal
      return a
          .getDisplayString(withNullability: true)
          .compareTo(b.getDisplayString(withNullability: true));
    });
  }

  static List<DartType> collectTypesFromFunctionType(FunctionType type, TypeProvider typeProvider) {
    // final paras = type.parameters;
    final returnType = type.returnType;
    final returnTypes = [
      ...getSubTypes(returnType, typeProvider),
      returnType,
      ...getSuperTypes(returnType, typeProvider)
    ];

    final parametersTypes = type.parameters
        .map((p) => [
              // p.type.element is ClassElement, not ParameterElement, so we need to get the element back
              ...getSubTypes(p.type, typeProvider).map((t) => p.copyWith(type: t)),
              p,
              // p.type.element is ClassElement, not ParameterElement, so we need to get the element back
              ...getSuperTypes(p.type, typeProvider).map((t) => p.copyWith(type: t)),
            ])
        .toList();

    final combination = allCombinations(parametersTypes);

    var allTypes = <DartType>[
      // typeProvider.objectQuestionType,
      typeProvider.objectType,
      typeProvider.functionType,
      typeProvider.neverType,
    ];
    for (var r in returnTypes) {
      for (var p in combination) {
        for (var i = 0; i < p.length; i++) {
          final t = FunctionTypeImpl(
            typeFormals: [], // TODO: handle type parameters
            parameters: p,
            returnType: r,
            nullabilitySuffix: type.nullabilitySuffix,
          );
          allTypes.add(t);
        }
      }
    }

    return allTypes;
  }

  static List<DartType> getSubTypes(DartType type, TypeProvider typeProvider) {
    final e = type.element;
    final types = <DartType>[];
    if (e is ClassElementImpl) {
      types.addAll(e.allSubtypes ?? []);
    }

    types.add(typeProvider.neverType);

    return types;
  }

  static List<DartType> getSuperTypes(DartType type, TypeProvider typeProvider) {
    final e = type.element;

    if (e is TypeAliasElement) {
      // note: if `type` is FunctionType then element is `null` so it's safe to do this.
      //       in most cases, we will just get an InterfaceElement
      return getSuperTypes(e.aliasedType, typeProvider);
    }

    final types = <DartType>[];
    if (e is InterfaceElement) {
      types.addAll(e.allSupertypes);
    }

    types.add(typeProvider.objectQuestionType);

    return types;
  }
}

class TypeNotFoundException implements Exception {
  final String msg;
  const TypeNotFoundException(this.msg);
  @override
  String toString() => 'TypeNotFoundException: $msg';
}
