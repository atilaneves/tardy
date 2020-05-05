module ut.polymorphic;


import ut;


private interface ITransformer {
    int transform(int) const;
}

private alias Transformer = Polymorphic!ITransformer;

private int xform(in Transformer t, int i) {
    return t.transform(i);
}


@("struct.stateless.Twice")
unittest {

    static struct Twice {
        int transform(int i) const { return i * 2; }
    }

    const twice = Transformer(Twice());
    xform(twice, 1).should == 2;
    xform(twice, 2).should == 4;
    xform(twice, 3).should == 6;
}


@("struct.stateless.Thrice")
unittest {

    static struct Thrice {
        int transform(int i) const { return i * 3; }
    }

    const thrice = Transformer(Thrice());
    xform(thrice, 1).should == 3;
    xform(thrice, 2).should == 6;
    xform(thrice, 3).should == 9;
}


@("struct.stateless.lib")
unittest {
    import modules.types: Negative;
    const negative = Transformer(Negative());
    xform(negative, 1).should == -1;
    xform(negative, 2).should == -2;
    xform(negative, 3).should == -3;
}


@("struct.stateful.Multiplier")
unittest {

    static struct Multiplier {
        int i;
        int transform(int j) const { return i * j; }
    }

    xform(Transformer(Multiplier(2)), 3).should == 6;
    xform(Transformer(Multiplier(2)), 4).should == 8;
    xform(Transformer(Multiplier(3)), 3).should == 9;
    xform(Transformer(Multiplier(3)), 4).should == 12;
}


@("class.stateless.Thrice")
unittest {

    static class Thrice {
        int transform(int i) const { return i * 3; }
    }

    const thrice = Transformer(new Thrice());
    xform(thrice, 1).should == 3;
    xform(thrice, 2).should == 6;
    xform(thrice, 3).should == 9;
}


@("class.stateful.Multiplier")
unittest {

    static class Multiplier {
        int i;
        this(int i) { this.i = i; }
        this(const Multiplier other) { this.i = other.i; }
        int transform(int j) const { return i * j; }
    }

    xform(Transformer(new Multiplier(2)), 3).should == 6;
    xform(Transformer(new Multiplier(2)), 4).should == 8;
    xform(Transformer(new Multiplier(3)), 3).should == 9;
    xform(Transformer(new Multiplier(3)), 4).should == 12;
}


@("int")
unittest {
    auto three = Transformer.create!"modules.ufcs.transform"(3);
    xform(three, 2).should == 6;
    xform(three, 3).should == 9;
}

@("scalar.modules")
unittest {
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


@("double")
unittest {
    auto double_ = Transformer.create!"modules.ufcs.transform"(3.3);
    xform(double_, 2).should == 5;
    xform(double_, 3).should == 6;
    xform(double_, 4).should == 7;
}


@("array")
unittest {
    static import modules.ufcs.stringify;
    import modules.types: Negative, Point, String;
    import std.algorithm.iteration: map;

    static interface IPrintable {
        string stringify() const;
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
