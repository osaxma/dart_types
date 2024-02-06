import 'dart:convert';
import 'dart:io';

/// A helper class for generating Mermaid code, editor url, viewer url or image url.
class MermaidGraph {
  late String code;

  /// Generate a mermaid code from a [graph]
  ///
  /// Note:
  /// - `Object.toString()` is used as node description for both keys and values.
  /// - `Object.hashCode`  is used as node ID.
  MermaidGraph(
    Map<Object /* nodes */, Iterable<Object> /* edges */ > graph, {
    List<Object>? typesToHighLight,
    String? graphType,
  }) : code = generateMermaidCode(
            graph: graph, graphType: graphType ?? 'LR', nodesToHighlight: typesToHighLight);

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

  // Fixes issues with generics
  // e.g. same type, different generic variable -- List<T> vs List<R> is the same here
  static String generateMermaidCode({
    required Map<Object, Iterable<Object>> graph,
    List<Object>? nodesToHighlight,
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
      final from = entry.key;
      final fromTag = from.hashCode;
      for (var type in entry.value) {
        final to = type;
        final toTag = to.hashCode;

        buff.write('  ${fromTag}');
        // do not add description if it was already added
        // it makes the viewer slow
        if (tags.add(fromTag)) {
          buff.write('("$from")');
        }

        // do not add description if it was already added
        // it makes the viewer slow
        buff.write(' --> $toTag');
        if (tags.add(toTag)) {
          buff.write('("$to")');
        }

        buff.writeln();
      }
    }

    buff.write('\n\n');
    if (nodesToHighlight != null) {
      for (var node in nodesToHighlight) {
        final tag = node.hashCode;
        buff.writeln('style $tag color:#7FFF7F');
      }
    }

    return buff.toString();
  }
}
