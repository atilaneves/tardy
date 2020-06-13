module ut.memory.classes;


import ut;
import std.experimental.allocator.mallocator: Mallocator;


private interface ITransformer {
    import std.traits: FA = FunctionAttribute;

    enum CopyConstructorAttrs = FA.safe | FA.pure_;
    enum DestructorAttrs = FA.pure_ | FA.nogc;

    int transform(int) @safe @nogc pure const;
}

private alias Transformer = Polymorphic!(ITransformer, Mallocator);

// @system because the copy constructor can't be safe
private int xform(in Transformer t, int i) @system @nogc pure {
    return t.transform(i);
}

private class Multiplier {
    int i;
    this(int i) @safe @nogc pure nothrow inout { this.i = i; }
    this(const Multiplier other) @safe @nogc pure nothrow inout { this.i = other.i; }
    int transform(int j) @safe @nogc pure nothrow const { return i * j; }
    override string toString() @safe pure nothrow const {
        import std.conv: text;
        return text(`Multiplier(`, i, `)`);
    }
}

private class Thrice {
    int transform(int i) @safe @nogc pure const { return i * 3; }
}


@("mallocator.stateful.create")
@system pure unittest {
    const multiplier = Transformer.create!Multiplier(3);
    xform(multiplier, 2).should == 6;
    xform(multiplier, 3).should == 9;
}


@("mallocator.stateful.copy")
@system pure unittest {
    const multiplier = Transformer(new Multiplier(3));
    xform(multiplier, 2).should == 6;
    xform(multiplier, 3).should == 9;
}


@("mallocator.stateless.create")
@system pure unittest {
    const multiplier = Transformer.create!Thrice(3);
    xform(multiplier, 2).should == 6;
    xform(multiplier, 3).should == 9;
}
