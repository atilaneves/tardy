module ut.polymorphic;


import ut;


private interface ITransformer {
    int transform(int) @safe pure const;
}

private alias Transformer = Polymorphic!ITransformer;

private int xform(in Transformer t, int i) @safe pure {
    return t.transform(i);
}


@("struct.stateless.Twice")
@safe unittest {

    static struct Twice {
        int transform(int i) @safe pure const { return i * 2; }
    }

    const twice = Transformer(Twice());
    xform(twice, 1).should == 2;
    xform(twice, 2).should == 4;
    xform(twice, 3).should == 6;
}


@("struct.stateless.Thrice")
@safe unittest {

    static struct Thrice {
        int transform(int i) @safe pure const { return i * 3; }
    }

    const thrice = Transformer(Thrice());
    xform(thrice, 1).should == 3;
    xform(thrice, 2).should == 6;
    xform(thrice, 3).should == 9;
}


@("struct.stateless.lib")
@safe unittest {
    import modules.types: Negative;
    const negative = Transformer(Negative());
    xform(negative, 1).should == -1;
    xform(negative, 2).should == -2;
    xform(negative, 3).should == -3;
}


@("struct.stateful.Multiplier")
@safe unittest {

    static struct Multiplier {
        int i;
        int transform(int j) @safe pure const { return i * j; }
    }

    xform(Transformer(Multiplier(2)), 3).should == 6;
    xform(Transformer(Multiplier(2)), 4).should == 8;
    xform(Transformer(Multiplier(3)), 3).should == 9;
    xform(Transformer(Multiplier(3)), 4).should == 12;
}


@("class.stateless.Thrice")
@safe unittest {

    static class Thrice {
        int transform(int i) @safe pure const { return i * 3; }
    }

    const thrice = Transformer(new Thrice());
    xform(thrice, 1).should == 3;
    xform(thrice, 2).should == 6;
    xform(thrice, 3).should == 9;
}


@("class.stateful.Multiplier")
@safe unittest {

    static class Multiplier {
        int i;
        this(int i) @safe pure { this.i = i; }
        this(const Multiplier other) @safe pure { this.i = other.i; }
        int transform(int j) @safe pure const { return i * j; }
    }

    xform(Transformer(new Multiplier(2)), 3).should == 6;
    xform(Transformer(new Multiplier(2)), 4).should == 8;
    xform(Transformer(new Multiplier(3)), 3).should == 9;
    xform(Transformer(new Multiplier(3)), 4).should == 12;
}


@("scalar.int")
@safe unittest {
    auto three = Transformer.create!"modules.ufcs.transform"(3);
    xform(three, 2).should == 6;
    xform(three, 3).should == 9;
}

@("scalar.modules")
@safe unittest {
    auto four = Transformer.create!(
             "modules.ufcs.transform",
             // pass in a module that has nothing to with anything to test
             // that it still works if there's no function with that
             // name in it
             "modules.types",
        )
        (4);
    xform(four, 2).should == 8;
    xform(four, 3).should == 12;
}


@("scalar.double")
@safe unittest {
    auto double_ = Transformer.create!"modules.ufcs.transform"(3.3);
    xform(double_, 2).should == 5;
    xform(double_, 3).should == 6;
    xform(double_, 4).should == 7;
}


@("array.pure")
@safe pure unittest {
    static import modules.ufcs.stringify;
    import modules.types: Negative, Point, String;
    import std.algorithm.iteration: map;
    import std.array: array;

    static interface IPrintable {
        string stringify() @safe pure const;
    }

    alias Printable = Polymorphic!IPrintable;

    auto printable = Printable.create!(modules.ufcs.stringify)(42);
    printable.stringify.should == "42";
}



@("array.safe")
@safe unittest {
    static import modules.ufcs.stringify;
    import modules.types: Negative, Point, String;
    import std.algorithm.iteration: map;
    import std.array: array;

    static interface IPrintable {
        string stringify() @safe const;
    }

    alias Printable = Polymorphic!IPrintable;

    auto printables = [
        Printable.create!(modules.ufcs.stringify)(42),
        Printable.create!(modules.ufcs.stringify)(3.3),
        // FIXME: can't create `string` with `new`
        // Printable.create!(modules.ufcs.stringify)("foobar"),
        Printable.create!(modules.ufcs.stringify)(String("quux")),
        Printable.create!(modules.ufcs.stringify)(Negative()),
        Printable.create!(modules.ufcs.stringify)(Point(2, 3)),
    ];

    // the conversion to an array is to maintain @safeness
    // (don't ask)
    printables.map!(a => a.stringify).array.should == [
        "42",
        "3.3",
        "quux",
        "Negative",
        "Point(2, 3)",
    ];
}


@("array.system")
@system unittest {
    static import modules.ufcs.stringify;
    import modules.types: Negative, Point, String;
    import std.algorithm.iteration: map;

    static interface IPrintable {
        string stringify() @system const;
    }

    alias Printable = Polymorphic!IPrintable;

    auto printables = [
        Printable.create!(modules.ufcs.stringify)(42),
        Printable.create!(modules.ufcs.stringify)(3.3),
        // FIXME: can't create `string` with `new`
        // Printable.create!(modules.ufcs.stringify)("foobar"),
        Printable.create!(modules.ufcs.stringify)(String("quux")),
        Printable.create!(modules.ufcs.stringify)(Negative()),
        Printable.create!(modules.ufcs.stringify)(Point(2, 3)),
    ];

    printables.map!(a => a.stringify).should == [
        "42",
        "3.3",
        "quux",
        "Negative",
        "Point(2, 3)",
    ];
}


@("array.xform")
// not pure because the copy constructor isn't (and can't be)
@safe unittest {
    static struct Twice {
        int transform(int i) @safe pure const { return i * 2; }
    }
    static struct Multiplier {
        int i;
        int transform(int j) @safe pure const { return i * j; }
    }

    xform(Transformer(Twice()), 1).should == 2;

    auto xformers = [ Transformer(Twice()), Transformer(Multiplier(3)) ];
    xform(xformers[0], 1).should == 2;
    xform(xformers[0], 2).should == 4;
    xform(xformers[1], 1).should == 3;
    xform(xformers[1], 2).should == 6;
}


@("self.immutable")
@safe pure unittest {
    static interface Interface {
        int fun() @safe pure immutable;
    }
    alias Poly = Polymorphic!Interface;

    static struct Mutable {
        int fun() @safe pure { return 0; }
    }

    static struct Const {
        int fun() @safe pure const { return 1; }
    }

    static struct Immutable {
        int fun() @safe pure immutable { return 2; }
    }

    static assert(!__traits(compiles, Poly(Mutable())));

    const c = Poly(Const());
    static assert(!__traits(compiles, c.fun()));

    immutable i = () pure { return Poly(Immutable()); }();
    i.fun.should == 2;
}


@("storageClass")
@safe pure unittest {

    static interface Interface {
        void storageClasses(
            int normal,
            return scope int* returnScope,
            out int out_,
            ref int ref_,
            lazy int lazy_,
        );
    }

    alias Poly = Polymorphic!Interface;

    static assert(is(typeof(Poly.storageClasses) == typeof(Interface.storageClasses)));
}


@ShouldFail
@("dtor")
@safe unittest {

    static interface Interface {
        int value() @safe @nogc pure const;
    }
    alias Poly = Polymorphic!Interface;

    static struct Id {
        static int numIds;
        int i;

        this(int i) {
            this.i = i;
            ++numIds;
        }

        ~this() { --numIds; }

        int value() @safe @nogc pure const { return i; }
    }

    Id.numIds.should == 0;
    {
        const id0 = Poly(Id(42));
        Id.numIds.should == 1;
        id0.value.should == 42;

        const id1 = Poly(Id(33));
        Id.numIds.should == 2;
        id1.value.should == 33;
    }
    Id.numIds.should == 0;
}


@("defaultValues")
@safe pure unittest {

    static interface Interface {
        string fun(int i, int j = 1, int k = 2) @safe pure scope const;
    }
    alias Poly = Polymorphic!Interface;

    static struct Struct {
        string fun(int i, int j, int k) @safe pure scope const {
            import std.conv: text;
            return text("i: ", i, " j: ", j, " k: ", k);
        }
    }

    auto obj = Poly(Struct());
    obj.fun(2, 3, 4).should == "i: 2 j: 3 k: 4";
    obj.fun(4, 3).should == "i: 4 j: 3 k: 2";
    obj.fun(5).should == "i: 5 j: 1 k: 2";
}
