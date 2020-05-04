/// Test value semantics
module ut.value;


import unit_threaded;
import tardy;


// verify that copying obeys value semantics
@("copy")
unittest {
    import std.algorithm.iteration: map;

    static interface IPrintable {
        void inc();
        string stringify() const;
    }

    alias Printable = Polymorphic!IPrintable;

    import std.conv: text;
    static struct Foo {
        int i;
        void inc() { ++i; }
        string stringify() const { return text("Foo(", i, ")"); }
    }
    static struct Bar {
        int i;
        void inc() { ++i; }
        string stringify() const { return text("Bar(", i, ")"); }
    }
    static struct Baz {
        int i;
        void inc() { ++i; }
        string stringify() const { return text("Baz(", i, ")"); }
    }

    auto printables = [
        Printable(Foo(0)),
        Printable(Foo(1)),
        Printable(Bar(2)),
        Printable(Baz(3)),
    ];

    printables.map!(a => a.stringify).should == ["Foo(0)", "Foo(1)", "Bar(2)", "Baz(3)"];

    auto bar = printables[2];
    bar.stringify.should == "Bar(2)";
    bar.inc;
    bar.stringify.should == "Bar(3)";

    printables.map!(a => a.stringify).should == ["Foo(0)", "Foo(1)", "Bar(2)", "Baz(3)"];
}


@("uncopiable")
unittest {
    static interface IPrintable {
        void inc();
        string stringify() const;
    }

    alias Printable = Polymorphic!IPrintable;

    static struct Foo {
        @disable this(this);
        int i;
        void inc() { ++i; }
        string stringify() const { import std.conv: text; return text("Foo(", i, ")"); }
    }

    auto p = Printable(Foo(42));
    p.stringify.should == "Foo(0)";  // T.init
    p.inc;
    p.stringify.should == "Foo(1)";
}
