import 'dart:io';

import 'package:analyzer/dart/element/type.dart';
import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:dart_types/dart_types.dart';

void main(List<String> args) async {
  final parser = ArgParser();

  parser.addSeparator('Generate type lattice for a give dart type (only mermaid is supported atm)');
  // TODO: split into commands: list, print, compare
  // TODO: add ability to filter certain types out of the lattice (e.g. Comparable)
  parser.addOption(
    'path',
    abbr: 'p',
    help: 'Specify the path of the file where the type(s) are (must provide this or `string`)',
  );
  parser.addOption(
    'string',
    abbr: 's',
    help: 'Provide a string containing the type(s) (must provide this or `path`)',
  );
  parser.addMultiOption(
    'type',
    abbr: 't',
    help: 'Specify the type to be selected from the given <string> or <path> (can be used multiple times)',
  );
  parser.addMultiOption(
    'filter',
    abbr: 'f',
    help: 'Filter out types from the type lattice (can be used multiple times)',
  );
  parser.addFlag(
    'list',
    abbr: 'l',
    help: 'list all the types from the given <string> or <path>',
    negatable: false,
  );

  parser.addFlag(
    'help',
    abbr: 'h',
    help: 'prints this usage information',
    negatable: false,
  );

  final result = parser.parse(args);

  if (result['help']) {
    printUsage(parser);
    exit(0);
  }

  final path = result['path'];
  final code = result['string'];

  if (path == null && code == null) {
    print('Error: either a `path` path or a `string` of dart code must be provided');
    print('');
    printUsage(parser);
    print('');
    exit(1);
  }
  final types = result['type'] as List<String>;
  final list = result['list'];

  if (types.isEmpty && !list) {
    print(
        'Error: either provide type to be analyzed or use `--list` to see the types in the provided `path` or `string`');
    print('');
    printUsage(parser);
    print('');
    exit(1);
  }

  final filter = result['filter'] as List<String>;

  try {
    await process(code: code, path: path, selectedTypes: types, filter: filter);
  } catch (e, st) {
    print('something went wrong:');
    print(e);
    print(st);
    exit(1);
  }

  return;
}

void printUsage(ArgParser parser) {
  final usage = parser.usage.split('\n');
  print(usage.first);
  print('');
  print('Example (from string): dart_types -s "class A{} class B extends A{} class C extends B{}" -t "C"');
  print('Example   (from path): dart_types -p path/to/file.dart -c "MyClass"');
  print('Example  (list types): dart_types -p path/to/file.dart --list');
  print('');
  print('Usage: dart_types [options]');
  usage.skip(1).map((e) => '  $e').forEach(print);
}

Future<void> process({
  required List<String> selectedTypes,
  String? path,
  String? code,
  List<String> filter = const [],
}) async {
  assert(path != null && code != null);

  final TypeAnalyzer typeAnalyzer;
  if (path != null) {
    typeAnalyzer = await TypeAnalyzer.fromPath(path);
  } else {
    typeAnalyzer = await TypeAnalyzer.fromCode(code!);
  }

  final allTypes = typeAnalyzer.getAllTypes();

  if (selectedTypes.isNotEmpty) {
    final types = <DartType>[];
    for (var selectedType in selectedTypes) {
      // first, check a type alias was selected
      var type =
          typeAnalyzer.getTypeAliasElements().firstWhereOrNull((e) => e.displayName == selectedType)?.aliasedType;

      type ??= allTypes.firstWhereOrNull((t) => t.getDisplayString(withNullability: true) == selectedType);

      if (type == null) {
        print('Error: selected type "$type" does not exists.');
        _printAvailableTypes(typeAnalyzer);
        return;
      }
      types.add(type);
    }

    final lattice = Lattice.merged(selectedTypes: types, typeAnalyzer: typeAnalyzer, filter: filter);
    print(lattice.toMermaidGraph(highlight: types));
    return;
  } else {
    _printAvailableTypes(typeAnalyzer);
  }
}

void _printAvailableTypes(TypeAnalyzer typeAnalyzer) {
  // list all types
  print('The following are the available types:');
  print(typeAnalyzer.getAllTypesAsPrettyString(true));
}
