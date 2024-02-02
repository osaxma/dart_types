// generated by ChatGPT

// Base class
class Organism {}

// Animal hierarchy
class Animal extends Organism {}

class Mammal extends Animal {}

class Bird extends Animal {}

class Reptile extends Animal {}

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

mixin Swimming on Organism implements Capabilities {}

mixin Flying on Organism implements Capabilities {}

mixin Running on Organism implements Capabilities {}

mixin Crawling on Organism implements Capabilities {}

mixin Jumping on Organism implements Capabilities {}

mixin Metamorphosis on Organism implements Capabilities {}

class UltimateOrganism extends Organism
    with Swimming, Flying, Running, Crawling, Jumping, Metamorphosis {}
