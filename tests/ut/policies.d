module ut.policies;


import ut;
import std.experimental.allocator.mallocator: Mallocator;


private interface ITransformer {
    import std.traits: FA = FunctionAttribute;

    enum CopyConstructorAttrs = FA.safe | FA.pure_;
    enum DestructorAttrs = FA.safe | FA.pure_ | FA.nogc;

    int transform(int) @safe @nogc pure const;
}

private alias Transformer = Polymorphic!(ITransformer, Mallocator);

private int xform(in Transformer t, int i) @safe @nogc pure {
    return t.transform(i);
}

private struct Twice {
    int transform(int i) @safe @nogc pure const { return i * 2; }
}

private struct Multiplier {
    int i;
    int transform(int j) @safe @nogc pure const { return i * j; }
}


@("mallocator.create.multiplier")
@safe pure unittest {
    const multiplier = Transformer.create!Multiplier(3);
    xform(multiplier, 2).should == 6;
    xform(multiplier, 3).should == 9;
}


@("mallocator.copy.multiplier")
@safe pure unittest {
    const multiplier = Transformer(Multiplier(3));
    xform(multiplier, 2).should == 6;
    xform(multiplier, 3).should == 9;
}
