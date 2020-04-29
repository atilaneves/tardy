module all;


import unit_threaded;
import foo;


unittest {
    static interface ITransformer {
        int transform(int) const;
    }

    alias Transformer = Polymorphic!ITransformer;

    static int xform(in Transformer t, int i) {
        return t.transform(i);
    }

    static struct Twice {
        int transform(int i) const { return i * 2; }
    }

    const twice = Transformer(Twice());
    xform(twice, 1).should == 2;
    xform(twice, 2).should == 4;
    xform(twice, 3).should == 6;

    static struct Thrice {
        int transform(int i) const { return i * 3; }
    }

    const thrice = Transformer(Thrice());
    xform(thrice, 1).should == 3;
    xform(thrice, 2).should == 6;
    xform(thrice, 3).should == 9;

    // library type
    import modules.types: Negative;
    const negative = Transformer(Negative());
    xform(negative, 1).should == -1;
    xform(negative, 2).should == -2;
    xform(negative, 3).should == -3;

    static struct Multiplier {
        int i;
        int transform(int j) const { return i * j; }
    }

    xform(Transformer(Multiplier(2)), 3).should == 6;
    xform(Transformer(Multiplier(2)), 4).should == 8;
    xform(Transformer(Multiplier(3)), 3).should == 9;
    xform(Transformer(Multiplier(3)), 4).should == 12;
}
