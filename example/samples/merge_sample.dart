// lub(C, D)
class Top {}

class A extends Top {}

class B extends Top {}

class C implements A, B {}

class D implements A, B {}

// glb(C, D)
class Bottom implements C, D {}
