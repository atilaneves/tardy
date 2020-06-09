import unit_threaded;

mixin runTestsMain!(
    "ut.polymorphic",
    "ut.value",
    "ut.refraction.vtable",
    "ut.refraction.method",
    "ut.memory.structs",
    "ut.memory.values",
    "ut.memory.classes",
);
