# Dart Types

A package to construct and present the type lattice of a given dart type.

### Features:
- Produce a mermaid graph of the type lattice 

> Note: generics are not supported at the moment

<!-- TODO: - add example and instruct how they can take it to `https://mermaid.live/` -->

### Example

- Running the following snippet:
    ```dart
    import 'package:dartypes/dartypes.dart';

    Future<void> main() async {
        final typeAnalyzer = await TypeAnalyzer.fromCode('typedef Func = int Function(int);');
        final type = typeAnalyzer.getFunctionTypes().first;
        final lattice = Lattice(type: type, typeAnalyzer: typeAnalyzer);
        print(lattice.toMermaidGraphCode());
    }
    ```
- Produces the following mermaid graph<sup>1</sup>:

    ```mermaid
    graph TD
        931422573("Object") --> 545029063("Function")
        545029063 --> 347766447("Object? Function(Never)")
        347766447 --> 99784076("Object Function(Never)")
        347766447 --> 822356007("Object? Function(int)")
        99784076 --> 558030879("num Function(Never)")
        99784076 --> 494603172("Object Function(int)")
        558030879 --> 355469451("int Function(Never)")
        558030879 --> 447189149("num Function(int)")
        355469451 --> 987323756("Never Function(Never)")
        355469451 --> 904175125("int Function(int)")
        987323756 --> 236799857("Never Function(int)")
        822356007 --> 494603172
        822356007 --> 979002104("Object? Function(num)")
        494603172 --> 447189149
        494603172 --> 655152334("Object Function(num)")
        447189149 --> 904175125
        447189149 --> 434395023("num Function(num)")
        904175125 --> 236799857
        904175125 --> 1073456545("int Function(num)")
        236799857 --> 751074829("Never Function(num)")
        979002104 --> 655152334
        979002104 --> 872118137("Object? Function(Object)")
        655152334 --> 434395023
        655152334 --> 562034873("Object Function(Object)")
        434395023 --> 1073456545
        434395023 --> 1066591392("num Function(Object)")
        1073456545 --> 751074829
        1073456545 --> 486934897("int Function(Object)")
        751074829 --> 314729469("Never Function(Object)")
        872118137 --> 562034873
        872118137 --> 796081945("Object? Function(Object?)")
        562034873 --> 1066591392
        562034873 --> 961619332("Object Function(Object?)")
        1066591392 --> 486934897
        1066591392 --> 1011595491("num Function(Object?)")
        486934897 --> 314729469
        486934897 --> 352616210("int Function(Object?)")
        314729469 --> 374033440("Never Function(Object?)")
        796081945 --> 961619332
        961619332 --> 1011595491
        1011595491 --> 352616210
        352616210 --> 374033440
        374033440 --> 791979707("Never")


    style 904175125 color:#7FFF7F
    ```

    > <sup>1</sup> _`Comparable` type was removed from the graph above to simplify it_

    See [example](/examples/) folder for more. 