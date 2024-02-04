import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:args/command_runner.dart';
import 'package:collection/collection.dart';
import 'package:dart_types/dart_types.dart';
import 'package:dart_types/src/mermaid.dart';
import 'package:dart_types/src/search.dart';

class Runner extends CommandRunner {
  Runner()
      : super(
          'dart_types',
          'Utility for basic analysis of Dart types',
        ) {
    addCommand(ListCommand());
    addCommand(MermaidCommand());

    argParser.addMultiOption('filter');
  }
}

abstract class BaseCommand extends Command {
  BaseCommand() {
    argParser.addOption(
      'path',
      abbr: 'p',
      help: 'Specify the path of the file/project where the type(s) are (can be multiple)',
    );

    argParser.addMultiOption(
      'filter',
      abbr: 'f',
      help: 'filter types using a pattern (can be multiple)',
    );
    argParser.addSeparator('');
  }

  String get path => argResults!['path'];

  List<RegExp> get filters =>
      (argResults!['filter'] as List<String>).map((e) => RegExp(e)).toList();

  void filterTypes(List<InterfaceElement> types) {
    types.removeWhere((t) => filters.any((regexp) => regexp.hasMatch(t.displayName)));
  }

  bool isValidPath(String path) => throw UnimplementedError('TODO');
}

class ListCommand extends BaseCommand {
  ListCommand();

  @override
  String get name => 'list';

  @override
  List<String> get aliases => ['l'];

  @override
  String get description => 'List the available types in the given `path`';

  @override
  FutureOr<void> run() async {
    final engine = await SimpleSearchEngine.create(path);
    final types = await engine.getAllTypes();
    filterTypes(types);
    for (var t in types) {
      print('- ${t.displayName}');
    }

    await engine.dispose();
  }
}

class MermaidCommand extends BaseCommand {
  MermaidCommand() {
    argParser.addMultiOption(
      'type',
      abbr: 't',
      help: 'scope the type hierarchy to specific type(s) (can be multiple)',
    );

    argParser.addFlag(
      'code',
      abbr: 'c',
      help: 'print the mermaid graph code',
      negatable: false,
    );
    argParser.addFlag(
      'url',
      abbr: 'v',
      help: 'generate a url to mermaid.live graph viewer',
      negatable: false,
    );
    argParser.addFlag(
      'url-edit',
      abbr: 'e',
      help: 'generate a url to mermaid.live graph editor',
      negatable: false,
    );

    argParser.addFlag(
      'url-image',
      abbr: 'i',
      help: 'generate a url to mermaid.ink graph image',
      negatable: false,
    );
  }

  @override
  String get name => 'mermaid';

  @override
  List<String> get aliases => ['m'];

  @override
  String get description => 'Generate a mermaid graph';

  List<String> get selectedTypes => argResults!['type'];

  bool get printGraph => argResults!['code'];
  bool get printViewUrl => argResults!['url'];
  bool get printEditUrl => argResults!['url-edit'];
  bool get printImageUrl => argResults!['url-image'];
  bool get anyOutputOption => printGraph || printViewUrl || printEditUrl || printImageUrl;

  @override
  FutureOr<void> run() async {
    if (!anyOutputOption) {
      print('no output option was selected, pass one of the following flags to `mermaid` command:');
      print("""
--code      or -c   to print the mermaid graph code.
--url       or -u   to generate a url to mermaid.live graph viewer.
--url-edit  or -e   to generate a url to mermaid.live graph editor',
--url-image or -i   to generate a url to mermaid.ink graph image',
""");
    }

    final engine = await SimpleSearchEngine.create(path);
    final types = await engine.getAllTypes();

    final typesToHighlight = <DartType>[];
    if (selectedTypes.isNotEmpty) {
      types.removeWhere((element) => !selectedTypes.contains(element.displayName));
      typesToHighlight.addAll(types.map((e) => e.thisType));
    }

    if (types.isEmpty) {
      print('could not find any of the selected types ${selectedTypes}');
      print('To view available types, run the following command:');
      print('     dart_types list -p $path');
      exit(1);
    }

    // hacky though works.
    final typeSystem = types.first.library.typeSystem;

    types.addAll(await engine.findSubtypesForAll(types));

    filterTypes(types);

    final allTypes = <DartType>[
      ...types.map((e) => e.allSupertypes).flattened,
      ...types.map((e) => e.thisType),
    ];

    final typeGraph = TypeGraph.fromTypes(allTypes, typeSystem);
    final mermaidGraph = MermaidGraph(typeGraph.graph, typesToHighLight: typesToHighlight);

    if (printGraph) {
      print(mermaidGraph.code);
      print('');
    }
    if (printViewUrl) {
      print('');
      print(mermaidGraph.viewUrl);
      print('');
    }
    if (printEditUrl) {
      print('');
      print(mermaidGraph.editUrl);
      print('');
    }
    if (printImageUrl) {
      print('');
      print(mermaidGraph.imageUrl);
      print('');
    }

    await engine.dispose();
  }
}
