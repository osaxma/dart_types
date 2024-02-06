import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/type.dart';

class MermaidGraph {
  late String code;

  MermaidGraph(
    Map<DartType /* nodes */, Set<DartType> /* edges | subtypes */ > graph, {
    List<DartType>? typesToHighLight,
    String? graphType,
  }) : code = generateMermaidCode2(graph: graph, graphType: graphType ?? 'LR');

  late final String encodedGraph = _encodeMermaidGraph(code);

  String get viewUrl => 'https://mermaid.live/view#pako:$encodedGraph';

  String get editUrl {
    return 'https://mermaid.live/edit#pako:$encodedGraph';
  }

  // Note: the background color is the same as mermaid.live
  // More info at: https://mermaid.ink
  String get imageUrl => 'https://mermaid.ink/img/pako:$encodedGraph?bgColor=2A303C';

  String _encodeMermaidGraph(String code) {
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

  @override
  String toString() => code;

  /* -------------------------------------------------------------------------- */
  /*                              GRAPH GENERATORS                              */
  /* -------------------------------------------------------------------------- */

  // this has some issues with Generics
  @Deprecated('use MermaidGraph.generateMermaidGraph2')
  static String generateMermaidCode({
    required Map<DartType, Set<DartType>> graph,
    List<DartType>? typesToHighLight,
    String graphType = 'LR',
  }) {
    final buff = StringBuffer();

    final tags = <int>{};

    // Keep this on the top
    // so no need to scroll back to the bottom of the terminal after selecting the code from bottom to top.
    buff.writeln('%% To view the graph, copy the code below to:');
    buff.writeln('%%  https://mermaid.live/');

    buff.writeln('graph $graphType');
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
    if (typesToHighLight != null) {
      for (var type in typesToHighLight) {
        final tag = type.getDisplayString(withNullability: true).hashCode;
        buff.writeln('style $tag color:#7FFF7F');
      }
    }

    return buff.toString();
  }

  // Fixes issues with generics
  // e.g. same type, different generic variable -- List<T> vs List<R> is the same here
  static String generateMermaidCode2({
    required Map<DartType, Set<DartType>> graph,
    List<DartType>? typesToHighLight,
    String graphType = 'LR',
  }) {
    final buff = StringBuffer();

    final tags = <int>{};

    final pattern = RegExp('<.*>');

    final newGraph = <String, Set<String>>{};
    for (var entry in graph.entries) {
      final newKey = entry.key.getDisplayString(withNullability: true).replaceAll(pattern, '');
      final value = entry.value
          .map((e) => e.getDisplayString(withNullability: true).replaceAll(pattern, ''))
          .toSet();
      newGraph.update(newKey, (v) => v..addAll(value), ifAbsent: () => value);

      // TODO: figure out why some node self reference themselves even though they should not
      //       I believe it has to do with how we add subtypes which can contain the same type
      //       maybe List<A> would be subtype of List<B> but have to confirm.
      newGraph[newKey]!.remove(newKey);
    }

    // Keep this on the top
    // so no need to scroll back to the bottom of the terminal after selecting the code from bottom to top.
    buff.writeln('%% To view the graph, copy the code below to:');
    buff.writeln('%%  https://mermaid.live/');

    buff.writeln('graph $graphType');
    for (var entry in newGraph.entries) {
      final from = entry.key;
      // note: do not use `DartType.hashCode` -- a lot of collisons there.
      //       so we use the display string hashcode instead
      final fromTag = from.hashCode;
      for (var type in entry.value) {
        final to = type;
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
    if (typesToHighLight != null) {
      for (var type in typesToHighLight) {
        final tag = type.getDisplayString(withNullability: true).replaceAll(pattern, '').hashCode;
        buff.writeln('style $tag color:#7FFF7F');
      }
    }

    return buff.toString();
  }
}
