module ut.memory.values;


import ut;
import std.experimental.allocator.mallocator: Mallocator;


private interface ITransformer {
    import std.traits: FA = FunctionAttribute;

    enum CopyConstructorAttrs = FA.pure_ | FA.nogc;
    enum DestructorAttrs = FA.pure_ | FA.nogc;

    int transform(int) @safe @nogc pure const;
}

private alias Transformer = Polymorphic!(ITransformer, Mallocator);

private int xform(in Transformer t, int i) @system @nogc pure {
    return t.transform(i);
}

@("mallocator.copy")
@system pure unittest {
    const multiplier = Transformer.create!"modules.ufcs.value.transform"([1, 2, 3]);
    xform(multiplier, 2).should == 5;
    xform(multiplier, 3).should == 6;
}
