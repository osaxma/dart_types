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

class TypesCollection {
  final List<DartType> allTypes;
  final List<DartType> selectedTypes;
  final TypeSystem typeSystem;

  TypesCollection._({
    required this.allTypes,
    required this.selectedTypes,
    required this.typeSystem,
  });

  static Future<TypesCollection> collectTypeInfoForInterfaceTypes({
    required String path,
    List<String> filters = const [],
    List<String> selectedTypes = const [],
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

    // hacky though works.
    final typeSystem = elements.first.library.typeSystem;

    elements.addAll(await engine.findSubtypesForAll(elements, recursive: true));

    final allTypes = <DartType>[
      ...elements.map((e) => e.allSupertypes).flattened,
      ...elements.map((e) => e.thisType),
    ];

    _filterTypes(allTypes, filters);

    await engine.dispose();

    return TypesCollection._(
        allTypes: allTypes.toSet().toList(), selectedTypes: typesToHighlight, typeSystem: typeSystem);
  }

  static Future<TypesCollection> collectTypeInfoForFunctionTypes({
    required String path,
    required String functionName,
    List<String> filters = const [],
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
      buff.writeln('could not find the FunctionType with name: $functionType');
      buff.writeln('To view available types, run the following command:');
      buff.writeln('     dart_types list -p $path');
      throw TypeNotFoundException(buff.toString());
    }

    final allTypes = collectTypesFromFunctionType(functionType, element.library.typeProvider);

    return TypesCollection._(
      allTypes: allTypes,
      selectedTypes: [functionType],
      typeSystem: element.library.typeSystem,
    );
  }

  static void _filterElements(List<InterfaceElement> elements, List<String> filters) {
    final patterns = filters.map((e) => RegExp(e));
    elements.removeWhere((t) => patterns.any((regexp) => regexp.hasMatch(t.displayName)));
  }

  static void _filterTypes(List<DartType> types, List<String> filters) {
    final patterns = filters.map((e) => RegExp(e));
    types.removeWhere((t) =>
        patterns.any((regexp) => regexp.hasMatch(t.getDisplayString(withNullability: true))));
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
