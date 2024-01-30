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

import 'util.dart';

class TypeAnalyzer {
  final LibraryElement _libraryElement;
  late final List<ClassElement> classes;

  TypeAnalyzer(this._libraryElement) {
    classes = _libraryElement.units.first.classes //
        // it messes up with least upper bound for some reason
        // .map((c) => _ClassElementExtended._addSubtypes(c, _libraryElement))
        // .toList() //
        ;
  }

  static Future<TypeAnalyzer> fromCode(String code) async {
    return TypeAnalyzer(await getLibraryElementFromCodeString(code));
  }

  static Future<TypeAnalyzer> fromPath(String path) async {
    return TypeAnalyzer(await getLibraryElementFromFile(path));
  }

  TypeProvider get typeProvider => _libraryElement.typeProvider;

  TypeSystem get typeSystem => _libraryElement.typeSystem;

  /// returns the least upper bound between [a] and [b]
  DartType lub(DartType a, DartType b) => typeSystem.leastUpperBound(a, b);

  /// returns the greatest lower bound between [a] and [b]
  DartType glb(DartType a, DartType b) => typeSystem.greatestLowerBound(a, b);

  ClassElement? getClass(String name) {
    for (final class_ in classes) {
      if (class_.name == name) {
        return class_;
      }
    }
    return null;
  }

  List<DartType> getTypes() {
    final types = _libraryElement.units.first.typeAliases.map((e) => e.aliasedType).toList();
    return types;
  }

  List<TypeAliasElement> getTypeAliasElements() {
    return _libraryElement.units.first.typeAliases;
  }

  List<FunctionType> getFunctionTypes() {
    final types = getTypes().whereType<FunctionType>().toList();
    return types;
  }

  List<DartType> getAllTypes() {
    final allTypes = <DartType>[];
    allTypes.addAll(classes.map((e) => e.thisType));
    allTypes.addAll(getTypes());
    return allTypes;
  }

  String getAllTypesAsPrettyString([bool grouped = false]) {
    final allTypes = getAllTypes();
    if (!grouped) {
      return getAllTypes().map((e) => '- ${e.getDisplayString(withNullability: true)}\n').fold('', (p, n) => p + n);
    }

    final groups = groupBy(allTypes, (t) => t.runtimeType.toString().replaceAll('Impl', ''));
    final buff = StringBuffer();
    for (var entry in groups.entries) {
      buff.writeln('${entry.key}:');
      for (var t in entry.value) {
        buff.writeln('  - $t');
      }
    }
    return buff.toString();
  }

  /// Return `true` if the [a] is a subtype of the [b].
  bool isSubType(DartType a, DartType b) {
    return _libraryElement.typeSystem.isSubtypeOf(a, b);
  }

  void sortTypes(List<DartType> types) {
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
      // typeProvider.objectQuestionType,
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

  List<DartType> collectTypesFromInterfaceType(InterfaceType type) {
    return <DartType>[
      typeProvider.objectType,
      ...getSubTypes(type),
      type,
      ...getSuperTypes(type),
      typeProvider.neverType,
    ];
  }
}

class _ClassElementExtended extends ClassElementImpl {
  final List<InterfaceType> knownSubtypes;
  _ClassElementExtended(
    super.name,
    super.offset,
    this.knownSubtypes,
  );

  @override
  List<InterfaceType>? get allSubtypes {
    if (isFinal || isSealed) return super.allSubtypes;
    // there was an attempt here to make the greatest lower bound pick something other than Never
    // but it seems that it doesn't loop through the subtypes anyway...
    // see: getGreatestLowerBound in analyzer/lib/src/dart/element/greatest_lower_bound.dart
    // Nevertheless, this type now shows in Lattice
    return [...knownSubtypes];
  }

  // enrich the subtype information by adding known subtypes from this library to its supertype
  static ClassElement _addSubtypes(ClassElement clazz, LibraryElement libraryElement) {
    // for final and sealed classes, dart handles them automatically.
    if (clazz.isFinal || clazz.isSealed) return clazz;
    final newClazz = _ClassElementExtended(
      clazz.name,
      clazz.nameOffset,
      libraryElement.units.first.classes
          .where((c) => c != clazz)
          .map((c) => c.thisType)
          .where((t) => libraryElement.typeSystem.isSubtypeOf(t, clazz.thisType))
          .toList(),
    );
    // copied from `analyzer//lib/src/summary2/element_builder.dart` visitClassDeclaration method
    newClazz.enclosingElement = clazz.enclosingElement; // this is necessary
    newClazz.supertype = clazz.supertype;
    newClazz.constructors = clazz.constructors as dynamic;
    newClazz.fields = clazz.fields as dynamic;
    newClazz.isAbstract = clazz.isAbstract;
    newClazz.isAugmentation = clazz.isAugmentation;
    newClazz.augmentationTarget = clazz.augmentationTarget as dynamic;
    newClazz.isBase = clazz.isBase;
    newClazz.isFinal = clazz.isFinal;
    newClazz.isInterface = clazz.isInterface;
    newClazz.isMixinClass = clazz.isMixinClass;
    newClazz.isAbstract = clazz.isAbstract;
    newClazz.isSealed = clazz.isSealed;
    newClazz.metadata = clazz.metadata;
    newClazz.typeParameters = clazz.typeParameters;

    return newClazz;
  }
}
