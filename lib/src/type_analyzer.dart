// The following don't seem to be available on the public API so this is the only option for now
// ignore_for_file: implementation_imports
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:collection/collection.dart';

import 'util.dart';

/// An Interface for the analyzer API specific to analyzing and processing types.
class TypeAnalyzer {
  late final List<ClassElement> classes;
  late final List<TypeAliasElement> typeAliasElements;

  // TODO: before, we only used a single library element. Now we have multiple -- would this be an issue?
  //        - typeProvider used for obtaining some core types (should be same wouldn't it?)
  //        - typeSystem used for checking subtypes
  //
  //       Maybe we should obtain both typeProvider and typeProvider through the element we are testing somehow
  //       e.g. `ClassElement` has `ClassElement.library.typeProvider`
  //       ... though but we cannot get there from DartType such as FunctionType where element is Null.
  //        unless we operate on `TypeDefiningElement`s all the way instead of `DartType` as the former has `library`
  //        as a member.
  late final TypeProvider _typeProvider;
  late final TypeSystem typeSystem;

  /// create a [TypeAnalyzer] for a single [LibraryElement]
  TypeAnalyzer(LibraryElement libraryElement) {
    typeSystem = libraryElement.typeSystem;
    _typeProvider = libraryElement.typeProvider;
    classes = _collectClasses(libraryElement);
    typeAliasElements = _collectTypeAliases(libraryElement);
  }

  /// create a [TypeAnalyzer] for a multiple [LibraryElement]s
  TypeAnalyzer.multiple(List<LibraryElement> libraryElements) {
    if (libraryElements.isEmpty) {
      throw Exception('TypeAnalyzer.multiple: No `LibraryElement`s were provided.');
    }

    // TODO: find out how we can merge the `typeSystem` and `typeProvider` for all libraries.
    //       I believe it doesn't make a difference because we only use it for core types and finding if two
    //       types are subtypes.
    typeSystem = libraryElements.first.typeSystem;
    _typeProvider = libraryElements.first.typeProvider;

    for (var libraryElement in libraryElements) {
      classes = _collectClasses(libraryElement);
      typeAliasElements = _collectTypeAliases(libraryElement);
    }
  }

  TypeAnalyzer.fromProject() {
    // maybe in the CLI: check if the provided path is a directory, and if so, check if it's a flutter/dart project
    //                   if so, collect all types from all files.
    throw UnimplementedError('TODO: support collecting types from an entire project');
  }

  static Future<TypeAnalyzer> fromCode(String code) async {
    return TypeAnalyzer(await getLibraryElementFromCodeString(code));
  }

  static Future<TypeAnalyzer> fromPath(String path) async {
    return TypeAnalyzer(await getLibraryElementFromFile(path));
  }

  List<FunctionType> get functionTypes => typeAliases.whereType<FunctionType>().toList();

  List<DartType> get typeAliases => typeAliasElements.map((e) => e.aliasedType).toList();

  ClassElement? getClass(String name) {
    for (final class_ in classes) {
      if (class_.name == name) {
        return class_;
      }
    }
    return null;
  }

  List<DartType> getAllTypes() {
    final allTypes = <DartType>[];
    allTypes.addAll(classes.map((e) => e.thisType));
    allTypes.addAll(typeAliasElements.map((e) => e.aliasedType));
    return allTypes;
  }

  List<DartType> getSubTypes(DartType type) {
    final e = type.element;
    final types = <DartType>[];
    if (e is ClassElementImpl) {
      types.addAll(e.allSubtypes ?? []);
    }

    types.add(_typeProvider.neverType);

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

  List<DartType> collectTypesFromFunctionType(FunctionType type) {
    // final paras = type.parameters;
    final returnType = type.returnType;
    final returnTypes = [...getSubTypes(returnType), returnType, ...getSuperTypes(returnType, _typeProvider)];

    final parametersTypes = type.parameters
        .map((p) => [
              // p.type.element is ClassElement, not ParameterElement, so we need to get the element back
              ...getSubTypes(p.type).map((t) => p.copyWith(type: t)),
              p,
              // p.type.element is ClassElement, not ParameterElement, so we need to get the element back
              ...getSuperTypes(p.type, _typeProvider).map((t) => p.copyWith(type: t)),
            ])
        .toList();

    final combination = allCombinations(parametersTypes);

    var allTypes = <DartType>[
      // typeProvider.objectQuestionType,
      _typeProvider.objectType,
      _typeProvider.functionType,
      _typeProvider.neverType,
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

  List<DartType> collectTypesFromInterfaceType(InterfaceType type) {
    return <DartType>[
      _typeProvider.objectType,
      ...getSuperTypes(type, _typeProvider),
      type,
      ...getSubTypes(type),
      _typeProvider.neverType,
    ];
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
      return a.getDisplayString(withNullability: true).compareTo(b.getDisplayString(withNullability: true));
    });
  }

  static List<ClassElement> _collectClasses(LibraryElement libraryElement) {
    final collectedClasses = <ClassElement>[];
    // collect declared class in the given library
    collectedClasses.addAll(libraryElement.units.first.classes);

    // collect classes from imported libraries
    for (var imports in libraryElement.importedLibraries) {
      collectedClasses.addAll(imports.units.first.classes);
    }

    // collect classes from exported libraries
    for (var exports in libraryElement.exportedLibraries) {
      collectedClasses.addAll(exports.units.first.classes);
    }

    // The goal here is to enrich the Lattice by adding the known subtypes of each class in the given libraries
    // to its superclass (e.g. add `StatelessWidget` to `Widget`). See `_ClassElementExtended` for more details
    //
    // Note:
    //  - This messes up with least upper bound
    //  - The added subtypes are ignored when computing the greatest lower bound
    //    - the algorithm ignores subtypes (i believe it does even for sealed/final classes)
    return collectedClasses.map((clazz) => _ClassElementExtended._addSubtypes(clazz, libraryElement)).toList();
  }

  static List<TypeAliasElement> _collectTypeAliases(LibraryElement libraryElement) {
    final typeAliases = <TypeAliasElement>[];
    // collect from the given library

    typeAliases.addAll(libraryElement.units.first.typeAliases);

    // collect  from imported libraries
    for (var imports in libraryElement.importedLibraries) {
      typeAliases.addAll(imports.units.first.typeAliases);
    }

    // collect from exported libraries
    for (var exports in libraryElement.exportedLibraries) {
      typeAliases.addAll(exports.units.first.typeAliases);
    }

    return typeAliases;
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
    // There was an attempt here to make the greatest lower bound pick something other than Never
    // but it looks like the algorithm ignores subtypes entirely (even for final and sealed)
    //    see: getGreatestLowerBound in analyzer/lib/src/dart/element/greatest_lower_bound.dart
    //
    // Nevertheless, these subtypes can be shown in Lattice between `thisType` and `Never`.
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
