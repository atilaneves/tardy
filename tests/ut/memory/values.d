module ut.memory.values;


import ut;
import std.experimental.allocator.mallocator: Mallocator;


private interface ITransformer {
    import std.traits: FA = FunctionAttribute;

    enum CopyConstructorAttrs = FA.safe | FA.pure_ | FA.nogc;
    enum DestructorAttrs = FA.safe | FA.pure_ | FA.nogc;

    int transform(int) @safe @nogc pure const;
}

private alias Transformer = Polymorphic!(ITransformer, Mallocator);

private int xform(in Transformer t, int i) @safe @nogc pure {
    return t.transform(i);
}

@("mallocator.copy")
@safe pure unittest {
    const multiplier = Transformer.create!"modules.ufcs.value.transform"([1, 2, 3]);
    xform(multiplier, 2).should == 5;
    xform(multiplier, 3).should == 6;
}
