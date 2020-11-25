module ut.issues;


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

        this(int number) @safe pure {
            this.number = number;
        }

        int transform(int i) @safe pure const {
            return i + number;
        }
    }

    auto plus = Transformer(new PlusNumber(42));
}
