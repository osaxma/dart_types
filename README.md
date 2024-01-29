# Dart Types

A package that is able to construct and present the type lattice of a given dart type

### Features:
- Produce a mermaid graph of the type lattice 

<!-- TODO: - Generate an HTML page with the mermaid graph  -->

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
- Produces the following mermaid graph:

    ```mermaid
    graph TD
        931422573("Object") --> 545029063("Function")
        545029063 --> 347766447("Object? Function(Never)")
        347766447 --> 99784076("Object Function(Never)")
        347766447 --> 822356007("Object? Function(int)")
        979002104("Object? Function(num)") --> 216434382("Object? Function(Comparable<num>)")
        979002104 --> 655152334("Object Function(num)")
        216434382 --> 107765467("Object Function(Comparable<num>)")
        216434382 --> 872118137("Object? Function(Object)")
        987323756("Never Function(Never)") --> 236799857("Never Function(int)")
        236799857 --> 751074829("Never Function(num)")
        751074829 --> 714956365("Never Function(Comparable<num>)")
        107765467 --> 562034873("Object Function(Object)")
        107765467 --> 961322779("Comparable<num> Function(Comparable<num>)")
        872118137 --> 562034873
        872118137 --> 796081945("Object? Function(Object?)")
        99784076 --> 494603172("Object Function(int)")
        99784076 --> 1004448274("Comparable<num> Function(Never)")
        558030879("num Function(Never)") --> 355469451("int Function(Never)")
        558030879 --> 447189149("num Function(int)")
        355469451 --> 987323756
        355469451 --> 904175125("int Function(int)")
        494603172 --> 655152334
        494603172 --> 725470274("Comparable<num> Function(int)")
        447189149 --> 904175125
        447189149 --> 434395023("num Function(num)")
        904175125 --> 236799857
        904175125 --> 1073456545("int Function(num)")
        655152334 --> 107765467
        655152334 --> 780091802("Comparable<num> Function(num)")
        434395023 --> 1073456545
        434395023 --> 573765227("num Function(Comparable<num>)")
        1073456545 --> 751074829
        1073456545 --> 169931172("int Function(Comparable<num>)")
        562034873 --> 961619332("Object Function(Object?)")
        562034873 --> 692115739("Comparable<num> Function(Object)")
        796081945 --> 961619332
        961619332 --> 263932222("Comparable<num> Function(Object?)")
        1004448274 --> 558030879
        1004448274 --> 725470274
        822356007 --> 979002104
        822356007 --> 494603172
        725470274 --> 447189149
        725470274 --> 780091802
        780091802 --> 434395023
        780091802 --> 961322779
        961322779 --> 692115739
        961322779 --> 573765227
        692115739 --> 263932222
        692115739 --> 1066591392("num Function(Object)")
        263932222 --> 1011595491("num Function(Object?)")
        573765227 --> 1066591392
        573765227 --> 169931172
        1066591392 --> 1011595491
        1066591392 --> 486934897("int Function(Object)")
        169931172 --> 486934897
        169931172 --> 714956365
        1011595491 --> 352616210("int Function(Object?)")
        486934897 --> 352616210
        486934897 --> 314729469("Never Function(Object)")
        714956365 --> 314729469
        352616210 --> 374033440("Never Function(Object?)")
        314729469 --> 374033440
        374033440 --> 791979707("Never")



    style 904175125 color:#7FFF7F

    ```