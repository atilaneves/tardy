module all;


import unit_threaded;
import foo;


unittest {

    import modules.types: Negative;

    static interface ITransformer {
        int transform(int) const;
    }

    static struct Twice {
        int transform(int i) { return i * 2; }
    }

    static struct Thrice {
        int transform(int i) { return i * 3; }
    }

    alias Transformer = Polymorphic!ITransformer;

    static int xform(Transformer t, int i) {
        return t.transform(i);
    }

    auto twice = Transformer(Twice());
    xform(twice, 1).should == 2;
    xform(twice, 2).should == 4;
    xform(twice, 3).should == 6;
}
