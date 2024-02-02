import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:collection/collection.dart';
import 'type_analyzer.dart';

import 'util.dart';

class Lattice {
  late final Map<DartType, Set<DartType> /* subtypes */ > graph;

  Lattice({
    required DartType type,
    required TypeAnalyzer typeAnalyzer,
    List<String> filter = const [],
  }) {
    final types = _collectTypes(type, typeAnalyzer, filter);
    final matrix = _createTypeMatrix(types, typeAnalyzer.typeSystem);
    graph = transitiveReduction(matrix);
  }

  Lattice.merged({
    required List<DartType> selectedTypes,
    required TypeAnalyzer typeAnalyzer,
    List<String> filter = const [],
  }) {
    selectedTypes = selectedTypes.map((t) => _collectTypes(t, typeAnalyzer, filter)).flattened.toList();
    TypeAnalyzer.sortTypes(selectedTypes, typeAnalyzer.typeSystem);
    final matrix = _createTypeMatrix(selectedTypes, typeAnalyzer.typeSystem);
    graph = transitiveReduction(matrix);
  }

  Lattice.fromTypes(List<DartType> types, TypeSystem typeSystem) {
    TypeAnalyzer.sortTypes(types, typeSystem);
    final matrix = _createTypeMatrix(types, typeSystem);
    graph = transitiveReduction(matrix);
  }

  static List<DartType> _collectTypes(DartType type, TypeAnalyzer typeAnalyzer, List<String> filter,
      [bool sorted = true]) {
    final List<DartType> types;
    if (type is FunctionType) {
      types = typeAnalyzer.collectTypesFromFunctionType(type);
    } else if (type is InterfaceType) {
      types = typeAnalyzer.collectTypesFromInterfaceType(type);
    } else {
      throw UnimplementedError('Only InterfaceType or FunctionType are supported but type: $type was given');
    }
    if (filter.isNotEmpty) {
      types.removeWhere((t) {
        var typeName = t.getDisplayString(withNullability: false);
        // TODO: maybe we need to make the interpolated value as raw if it contains `$` or something else
        return filter.map((e) => RegExp('(?![^a-zA-Z0-9_])$e(?=[^a-zA-Z0-9_])')).any((f) => typeName.contains(f));
      });
    }
    if (sorted) {
      TypeAnalyzer.sortTypes(types, typeAnalyzer.typeSystem);
    }
    return types;
  }

  static Map<DartType, List<DartType>> _createTypeMatrix(List<DartType> types, TypeSystem typeSystem) {
    final matrix = <DartType, List<DartType> /* subtypes */ >{};
    for (var t in types) {
      final edges = types.where((element) => element != t && typeSystem.isSubtypeOf(element, t)).toList();
      matrix[t] = edges;
    }

    return matrix;
  }
}

extension MermaidGraph on Lattice {
  String toMermaidGraph({List<DartType>? highlight}) {
    final buff = StringBuffer();

    final tags = <int>{};

    // Keep this on the top
    // so no need to scroll back to the bottom of the terminal after selecting the code from bottom to top.
    buff.writeln('%% To view the graph, copy the code below to:');
    buff.writeln('%%  https://mermaid.live/');

    buff.writeln('graph TD');
    for (var entry in graph.entries) {
      final from = entry.key.getDisplayString(withNullability: true);
      // note: do not use `DartType.hashCode` -- a lot of collisons there.
      //       so we use the display string hashcode instead
      final fromTag = from.hashCode;
      for (var type in entry.value) {
        final to = type.getDisplayString(withNullability: true);
        final toTag = to.hashCode;

        buff.write('  ${fromTag}');
        if (tags.add(fromTag)) {
          buff.write('("$from")');
        }
        buff.write(' --> $toTag');
        if (tags.add(toTag)) {
          buff.write('("$to")');
        }
        buff.writeln();
      }
    }

    buff.write('\n\n');
    if (highlight != null) {
      for (var type in highlight) {
        final tag = type.getDisplayString(withNullability: true).hashCode;
        buff.writeln('style $tag color:#7FFF7F');
      }
    }

    return buff.toString();
  }

  static String generateMermaidUrl(String graph) {
    return 'https://mermaid.live/view#pako:' + _encodeMermaidGraph(graph);
  }

  // see: https://mermaid.ink
  static String generateMermaidImageUrl(String graph) {
    final bgColor = '?bgColor=2A303C'; // mermaid.live background color
    return 'https://mermaid.ink/img/pako:' + _encodeMermaidGraph(graph) + bgColor;
  }

  static String _encodeMermaidGraph(String code) {
    final data = {
      "code": code,
      // mermaid.ink (image) doesn't need it, but mermaid.live does
      "mermaid": {
        "theme": "dark",
      },
    };

    final dataAsJson = json.encode(data);
    final dataAsBytes = ascii.encode(dataAsJson);

    // Note: mermaid uses `pako`, which is a zlib implementation, to encode and compress the graph.
    // See: https://github.com/mermaid-js/mermaid-live-editor/blob/b5978e6faf7635e39452855fb4d062d1452ab71b/src/lib/util/serde.ts#L2
    final codec = ZLibCodec(
      // by mermaid
      level: 9,
    );

    final compressedData = codec.encode(dataAsBytes);

    final dataAsBase64 = base64Url.encode(compressedData);

    return dataAsBase64;
  }
}
