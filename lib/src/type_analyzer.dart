// The following don't seem to be available on the public API so this is the only option for now
// ignore_for_file: implementation_imports
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';

import 'util.dart';

class TypeAnalyzer {
  TypeAnalyzer(this.libraryElement);

  static Future<TypeAnalyzer> fromCode(String code) async {
    return TypeAnalyzer(await getLibraryElementFromCodeString(code));
  }

  final LibraryElement libraryElement;

  TypeProvider get typeProvider => libraryElement.typeProvider;
  TypeSystem get typeSystem => libraryElement.typeSystem;

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

  /// Return `true` if the [a] is a subtype of the [b].
  bool isSubType(DartType a, DartType b) {
    return libraryElement.typeSystem.isSubtypeOf(a, b);
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

    return allTypes;
  }
}
