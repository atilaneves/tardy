import unit_threaded;

mixin runTestsMain!(
    "tardy",
    "ut.polymorphic",
    "ut.value",
    "ut.refraction.vtable",
    "ut.refraction.method",
    "ut.memory.structs",
    "ut.memory.values",
    "ut.memory.classes",
    "ut.memory.allocators",
);


shared static this() @safe nothrow {
    import std.experimental.allocator: theAllocator, allocatorObject;
    import std.experimental.allocator.mallocator: Mallocator;
    () @trusted { theAllocator = allocatorObject(Mallocator.instance); }();
}
