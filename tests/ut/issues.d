import ut;


@("14")
@safe pure unittest {

    static interface ITransformer {
        import std.traits: FA = FunctionAttribute;
        enum CopyConstructorAttrs = FA.safe | FA.pure_ | FA.nothrow_;
        enum DestructorAttrs = FA.safe | FA.pure_ |  FA.nothrow_;
        int transform(int) @safe pure const;
    }

    alias Transformer = Polymorphic!ITransformer;

    static class PlusNumber {
        private int number;

        this(int number) {
            this.number = number;
        }

        int transform(int i) pure const {
            return i + number;
        }
    }

    static assert(!__traits(compiles, Transformer(new PlusNumber(42))));
    //auto plus = Transformer(new PlusNumber(42));
}
