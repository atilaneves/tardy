module ut.polymorphic;


import ut;


private interface ITransformer {
    int transform(int) const;
}

private alias Transformer = Polymorphic!ITransformer;

private int xform(in Transformer t, int i) {
    return t.transform(i);
}


@("Polymorphic.struct.stateless.Twice")
unittest {

    static struct Twice {
        int transform(int i) const { return i * 2; }
    }

    const twice = Transformer(Twice());
    xform(twice, 1).should == 2;
    xform(twice, 2).should == 4;
    xform(twice, 3).should == 6;
}


@("Polymorphic.struct.stateless.Thrice")
unittest {

    static struct Thrice {
        int transform(int i) const { return i * 3; }
    }

    const thrice = Transformer(Thrice());
    xform(thrice, 1).should == 3;
    xform(thrice, 2).should == 6;
    xform(thrice, 3).should == 9;
}


@("Polymorphic.struct.stateless.lib")
unittest {
    import modules.types: Negative;
    const negative = Transformer(Negative());
    xform(negative, 1).should == -1;
    xform(negative, 2).should == -2;
    xform(negative, 3).should == -3;
}


@("Polymorphic.struct.stateful.Multiplier")
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


@("Polymorphic.int")
unittest {
    static import modules.ufcs.transform;
    auto three = Transformer.construct!(modules.ufcs.transform)(3);
    xform(three, 2).should == 6;
}


@("Polymorphic.double")
unittest {
    static import modules.ufcs.transform;
    auto double_ = Transformer.construct!(modules.ufcs.transform)(3.3);
    xform(double_, 2).should == 5;
    xform(double_, 3).should == 6;
    xform(double_, 4).should == 7;
}
