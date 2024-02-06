import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:dart_types/dart_types.dart';

// this thing is slow because it analyzes the entire flutter library
void main() async {
  final path = _getFlutterLibPath();

  final typeGraph = await TypeGraph.generateForInterfaceTypes(
    path: path,
    // selectedTypes: ['StatefulWidget'],
    filters: ['^_.*'], // no privates
  );
  final mermaidGraph = typeGraph.toMermaidGraph();

  // this will be a huge URL .. but it works
  print(mermaidGraph.viewUrl);
}

String _getFlutterLibPath() {
  var flutterLibPath = Process.runSync('which', ['flutter']).stdout;
  if (flutterLibPath is! String || flutterLibPath.isEmpty) {
    print('could not find flutter path to run this example');
    exit(1);
  }
  flutterLibPath = flutterLibPath.trim();
  flutterLibPath = p.dirname(p.dirname(flutterLibPath)); // remove "bin/flutter" from path
  flutterLibPath = p.join(flutterLibPath, 'packages', 'flutter', 'lib');
  flutterLibPath = p.normalize(p.absolute(flutterLibPath));
  return flutterLibPath;
}
