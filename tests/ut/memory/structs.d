module ut.memory.structs;


import ut;
import std.experimental.allocator.mallocator: Mallocator;


private interface ITransformer {
    import std.traits: FA = FunctionAttribute;

    enum CopyConstructorAttrs = FA.safe | FA.pure_ | FA.nogc;
    enum DestructorAttrs = FA.safe | FA.pure_ | FA.nogc;

    int transform(int) @safe @nogc pure const;
}


private alias TransformerMalloc = Polymorphic!(ITransformer, Mallocator);

private int xform(in TransformerMalloc t, int i) @safe @nogc pure {
    return t.transform(i);
}

private struct Multiplier {
    int i;
    int transform(int j) @safe @nogc pure nothrow const { return i * j; }
}


@("mallocator.create")
@safe pure unittest {
    const multiplier = TransformerMalloc.create!Multiplier(3);
    xform(multiplier, 2).should == 6;
    xform(multiplier, 3).should == 9;
}


@("mallocator.copy")
@safe pure unittest {
    const multiplier = TransformerMalloc(Multiplier(3));
    xform(multiplier, 2).should == 6;
    xform(multiplier, 3).should == 9;
}


@("mallocator.nogc")
@safe @nogc pure unittest {
    const multiplier = TransformerMalloc(Multiplier(3));
    xform(multiplier, 2);
}


@("sbo.copy")
@safe pure unittest {
    const multiplier = Polymorphic!(ITransformer, SBOAllocator!16)(Multiplier(3));
    multiplier.transform(2).should == 6;
    multiplier.transform(3).should == 9;
}


@("insitu.copy")
@safe pure unittest {
    const multiplier = Polymorphic!(ITransformer, InSitu!16)(Multiplier(3));
    multiplier.transform(2).should == 6;
    multiplier.transform(3).should == 9;
}
