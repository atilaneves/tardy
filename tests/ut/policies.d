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

private struct MultiplierStruct {
    int i;
    int transform(int j) @safe @nogc pure const { return i * j; }
}

private class MultiplierClass {
    int i;
    this(int i) @safe pure { this.i = i; }
    this(const MultiplierClass other) @safe pure { this.i = other.i; }
    int transform(int j) @safe @nogc pure const { return i * j; }
    override string toString() @safe pure const {
        import std.conv: text;
        return text(`MultiplierClass(`, i, `)`);
    }
}

private class ThriceClass {
    int transform(int i) @safe @nogc pure const { return i * 3; }
}


@("mallocator.struct.create")
@safe pure unittest {
    const multiplier = Transformer.create!MultiplierStruct(3);
    xform(multiplier, 2).should == 6;
    xform(multiplier, 3).should == 9;
}


@("mallocator.struct.copy")
@safe pure unittest {
    const multiplier = Transformer(MultiplierStruct(3));
    xform(multiplier, 2).should == 6;
    xform(multiplier, 3).should == 9;
}


@("mallocator.class.stateful.create")
@safe pure unittest {
    const multiplier = Transformer.create!MultiplierClass(3);
    xform(multiplier, 2).should == 6;
    xform(multiplier, 3).should == 9;
}


@("mallocator.class.stateful.copy")
@safe pure unittest {
    const multiplier = Transformer(new MultiplierClass(3));
    xform(multiplier, 2).should == 6;
    xform(multiplier, 3).should == 9;
}


@("mallocator.class.stateless.create")
@safe pure unittest {
    const multiplier = Transformer.create!ThriceClass(3);
    xform(multiplier, 2).should == 6;
    xform(multiplier, 3).should == 9;
}


@("mallocator.array.copy")
@safe pure unittest {
    const multiplier = Transformer.create!"modules.ufcs.value.transform"([1, 2, 3]);
    xform(multiplier, 2).should == 5;
    xform(multiplier, 3).should == 6;
}
