module tardy;

public import tardy.poly;
public import tardy.allocators;


version(TardyTest):

import tardy;

interface ITransformer {
    int transform(int) @safe pure const;
}
alias Transformer = Polymorphic!ITransformer;

int xform(Transformer t) {
    return t.transform(3);
}

struct Adder {
    int i;
    int transform(int j) @safe pure const { return i + j; }
}

struct Plus1 {
    int transform(int i) @safe pure const{ return i + 1; }
}

unittest {
    assert(xform(Transformer(Adder(2))) == 5);
    assert(xform(Transformer(Adder(3))) == 6);

    assert(xform(Transformer(Plus1())) == 4);
}
