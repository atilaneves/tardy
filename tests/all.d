module all;


import unit_threaded;
import foo;


unittest {

    import modules.types: Negative;

    static interface ITransformer {
        int transform(int) const;
    }

    alias Transformer = Polymorphic!ITransformer;

    static int xform(Transformer t, int i) {
        return t.transform(i);
    }

    static struct Twice {
        int transform(int i) { return i * 2; }
    }

    auto twice = Transformer(Twice());
    xform(twice, 1).should == 2;
    xform(twice, 2).should == 4;
    xform(twice, 3).should == 6;

    static struct Thrice {
        int transform(int i) { return i * 3; }
    }

    auto thrice = Transformer(Thrice());
    xform(thrice, 1).should == 3;
    xform(thrice, 2).should == 6;
    xform(thrice, 3).should == 9;

    auto negative = Transformer(Negative());
    xform(negative, 1).should == -1;
    xform(negative, 2).should == -2;
    xform(negative, 3).should == -3;
}
