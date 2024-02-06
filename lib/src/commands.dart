import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dart_types/dart_types.dart';
import 'package:dart_types/src/mermaid.dart';
import 'package:dart_types/src/search.dart';
import 'package:dart_types/src/util.dart';

class Runner extends CommandRunner {
  Runner()
      : super(
          'dart_types',
          'Utility for basic analysis of Dart types',
        ) {
    addCommand(ListCommand());
    addCommand(MermaidCommand());

    argParser.addFlag(
      'verbose',
      abbr: 'v',
      defaultsTo: false,
      help: 'Verbose output',
    );
  }

  @override
  Future runCommand(ArgResults topLevelResults) {
    if (topLevelResults['verbose']) {
      verbose = true;
    }

    return super.runCommand(topLevelResults);
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

    argParser.addFlag(
      'ignore-privates',
      abbr: 'x',
      help: 'Ignore all private types',
    );

    argParser.addSeparator('');
  }

  String get path => argResults!['path'];

  List<String> get filters {
    return [
      ...argResults!['filter'],
      if (argResults!['ignore-privates']) '^_.*',
    ];
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
    try {
      final types = await engine.getAllTypeDefiningElements();
      final patterns = filters.map((f) => RegExp(f));
      types.removeWhere((t) => patterns.any((p) => p.hasMatch(t.displayName)));
      for (var t in types) {
        print('- ${t.displayName}');
      }
    } catch (e) {
      print('something went wrong');
      print('$e');
    } finally {
      await engine.dispose();
    }
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
      abbr: 'u',
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

// https://jojozhuang.github.io/tutorial/mermaid-cheat-sheet/
    argParser.addOption(
      'graph-type',
      abbr: 'g',
      help: 'Specify the graph type: '
          'Top Bottom, Bottom Up, Right Left, Left Right',
      defaultsTo: 'LR',
      // valueHelp: 'TB|BT|RL|LR',
      allowed: ['TB', 'BT', 'RL', 'LR'],
    );

    argParser.addFlag(
      'function',
      hide: !verbose,
      help: 'Generate type lattice for a function type (typedef) -- only supports one type',
    );
  }

  @override
  String get name => 'mermaid';

  @override
  List<String> get aliases => ['m'];

  @override
  String get description => 'Generate Mermaid Graph (code, editor url, viewer url, or image url)';

  bool get isFunctionType => argResults!['function'];
  List<String> get selectedTypes => argResults!['type'];
  String get graphType => argResults!['graph-type'];

  bool get printGraph => argResults!['code'];
  bool get printViewUrl => argResults!['url'];
  bool get printEditUrl => argResults!['url-edit'];
  bool get printImageUrl => argResults!['url-image'];
  bool get anyOutputOption => printGraph || printViewUrl || printEditUrl || printImageUrl;

  void ensureOutputOptionIsProvidedOrExit() {
    if (!anyOutputOption) {
      print(
          'Exception: No output option was selected, pass one of the following flags to `mermaid` command:');
      print("""
--code      or -c   to print the mermaid graph code.
--url       or -u   to generate a url to mermaid.live graph viewer.
--url-edit  or -e   to generate a url to mermaid.live graph editor',
--url-image or -i   to generate a url to mermaid.ink graph image',
""");

      exit(42);
    }
  }

  void printOutputGraph(MermaidGraph graph) {
    if (printGraph) {
      print('');
      print(graph.code);
      print('');
    }
    if (printViewUrl) {
      print('');
      print(graph.viewUrl);
      print('');
    }
    if (printEditUrl) {
      print('');
      print(graph.editUrl);
      print('');
    }
    if (printImageUrl) {
      print('');
      print(graph.imageUrl);
      print('');
    }
  }

  @override
  FutureOr<void> run() async {
    ensureOutputOptionIsProvidedOrExit();

    final TypeGraph typeGraph;
    try {
      if (!isFunctionType) {
        typeGraph = await TypeGraph.generateForInterfaceTypes(
          path: path,
          selectedTypes: selectedTypes,
          filters: filters,
        );
      } else {
        if (selectedTypes.isEmpty) {
          print('Exception: For function types, one type must be selected');
          exit(42);
        }

        if (selectedTypes.length > 1) {
          print('Warning: More than one type was provided for function types');
          print('         only ${selectedTypes.first} will be analyzed');
        }

        logger.trace(selectedTypes.first);

        typeGraph = await TypeGraph.generateForFunctionType(
          path: path,
          functionName: selectedTypes.first,
          filters: filters,
        );
      }
    } catch (e, st) {
      print(e);
      if (verbose) {
        print(st);
      }
      exit(42);
    }

    final mermaidGraph = typeGraph.toMermaidGraph(graphType: graphType);
    printOutputGraph(mermaidGraph);
  }
}
