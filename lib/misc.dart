// The following don't seem to be available on the public API so this is the only option for now
// ignore_for_file: implementation_imports
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';

import 'dart:io';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';

// gracias a lrhn: https://stackoverflow.com/a/68816742/10976714
Iterable<List<T>> allCombinations<T>(List<List<T>> sources) sync* {
  if (sources.isEmpty || sources.any((l) => l.isEmpty)) {
    yield [];
    return;
  }
  var indices = List<int>.filled(sources.length, 0);
  var next = 0;
  while (true) {
    yield [for (var i = 0; i < indices.length; i++) sources[i][indices[i]]];
    while (true) {
      var nextIndex = indices[next] + 1;
      if (nextIndex < sources[next].length) {
        indices[next] = nextIndex;
        break;
      }
      next += 1;
      if (next == sources.length) return;
    }
    indices.fillRange(0, next, 0);
    next = 0;
  }
}

List<DartType> getSubTypes(DartType type, TypeProvider typeProvider) {
  final e = type.element;
  final types = <DartType>[];
  if (e is ClassElementImpl) {
    types.addAll(e.allSubtypes ?? []);
  }

  types.add(typeProvider.neverType);

  return types;
}

List<DartType> getSuperTypes(DartType type, TypeProvider typeProvider) {
  final e = type.element;

  if (e is TypeAliasElement) {
    // TODO: haven't tested this btw
    return getSuperTypes(e.aliasedType, typeProvider);
  }

  final types = <DartType>[];
  if (e is InterfaceElement) {
    types.addAll(e.allSupertypes);
  } else if (e is FunctionType) {
    // types.add(session.libraryElement.typeProvider.functionType);
  }

  types.add(typeProvider.objectQuestionType);

  return types;
}

List<DartType> collectTypesFromFunctionType(FunctionType type, TypeProvider typeProvider) {
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

Future<int> promptClassSelection(List<ClassElement> classes) async {
  final buff = StringBuffer();
  buff.writeln('select a class:');
  for (var i = 0; i < classes.length; i++) {
    final name = classes[i].name;
    buff.writeln('  ${i + 1}-$name');
  }

  stdout.write(buff.toString());

  final selection = int.tryParse(stdin.readLineSync()?.trim() ?? '');

  if (selection == null || selection > classes.length || selection < 1) {
    print('please enter a valid selection');
    return promptClassSelection(classes);
  }

  return selection - 1;
}
