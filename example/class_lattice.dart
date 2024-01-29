import 'package:dart_types/dart_types.dart';

Future<void> main() async {
  final typeAnalyzer = await TypeAnalyzer.fromCode(clazz);
  final type = typeAnalyzer.getClass('UltimateOrganism')!.thisType;
  final lattice = Lattice(type: type, typeAnalyzer: typeAnalyzer);
  print(lattice.toMermaidGraphCode());
}

// gracias a chatgpt
final clazz = '''
// Base class
class Organism {
  void eat() {
    print('Organism is eating.');
  }
}

// Animal hierarchy
class Animal extends Organism {
  void makeSound() {
    print('Animal makes a sound.');
  }
}

class Mammal extends Animal {
  void lactate() {
    print('Mammal is lactating.');
  }
}

class Bird extends Animal {
  void layEggs() {
    print('Bird is laying eggs.');
  }
}

class Reptile extends Animal {
  void bask() {
    print('Reptile is basking.');
  }
}

// Mammal hierarchy
class Whale extends Mammal with Swimming {}

class Bat extends Mammal with Flying {}

class Dog extends Mammal with Running {}

// Bird hierarchy
class Eagle extends Bird with Flying {}

class Penguin extends Bird with Swimming {}

// Reptile hierarchy
class Snake extends Reptile with Crawling {}

class Turtle extends Reptile with Swimming {}

// Amphibian hierarchy
class Frog extends Organism with Swimming, Jumping {}

// Insect hierarchy
class Butterfly extends Organism with Flying, Metamorphosis {}

// Capabilities
abstract class Capabilities {}

class Swimming extends Capabilities {}

class Flying extends Capabilities {}

class Running extends Capabilities {}

class Crawling extends Capabilities {}

class Jumping extends Capabilities {}

class Metamorphosis extends Capabilities {
  void undergoMetamorphosis() {
    print('Undergoing metamorphosis.');
  }
}

class UltimateOrganism extends Organism
    with Swimming, Flying, Running, Crawling, Jumping, Metamorphosis {
  void performUltimateAction() {
    print('The Ultimate Organism is performing the ultimate action!');
  }
}

''';
/* 
result:
graph TD
  677057586("Object?") --> 931422573("Object")
  931422573 --> 260278288("Organism")
  931422573 --> 841896430("Capabilities")
  260278288 --> 1066199599("UltimateOrganism")
  841896430 --> 142967491("Swimming")
  841896430 --> 989004979("Flying")
  841896430 --> 584013485("Running")
  841896430 --> 575345374("Crawling")
  841896430 --> 930058222("Jumping")
  841896430 --> 173060077("Metamorphosis")
  142967491 --> 1066199599
  989004979 --> 1066199599
  584013485 --> 1066199599
  575345374 --> 1066199599
  930058222 --> 1066199599
  173060077 --> 1066199599
  1066199599 --> 791979707("Never")

style 1066199599 color:#7FFF7F
 */