/// Test value semantics
module ut.value;


import unit_threaded;
import tardy;


// verify that copying obeys value semantics
@("copy")
// not pure because the copy constructor isn't (and can't)
@safe unittest {
    import std.algorithm.iteration: map;

    static interface IPrintable {
        void inc() @safe;
        string stringify() @safe const;
    }

    alias Printable = Polymorphic!IPrintable;

    import std.conv: text;
    static struct Foo {
        int i;
        void inc() @safe { ++i; }
        string stringify() @safe const { return text("Foo(", i, ")"); }
    }
    static struct Bar {
        int i;
        void inc() @safe { ++i; }
        string stringify() @safe const { return text("Bar(", i, ")"); }
    }
    static struct Baz {
        int i;
        void inc() @safe { ++i; }
        string stringify() @safe const { return text("Baz(", i, ")"); }
    }

    auto printables = [
        Printable(Foo(0)),
        Printable(Foo(1)),
        Printable(Bar(2)),
        Printable(Baz(3)),
    ];

    string call(Printable p) { return p.stringify; }
    auto strings = printables.map!call;
    () @trusted {
        strings.should == ["Foo(0)", "Foo(1)", "Bar(2)", "Baz(3)"];
    }();

    auto bar = printables[2];
    bar.stringify.should == "Bar(2)";
    bar.inc;
    bar.inc;
    bar.inc;
    bar.stringify.should == "Bar(5)";

    strings = printables.map!call;
    () @trusted {
        strings.should == ["Foo(0)", "Foo(1)", "Bar(2)", "Baz(3)"];
    }();
}


@("uncopiable")
@safe unittest {
    static interface IPrintable {
        void inc() @safe;
        string stringify() @safe const;
    }

    alias Printable = Polymorphic!IPrintable;

    static struct Foo {
        @disable this(this);
        int i;
        void inc() @safe { ++i; }
        string stringify() @safe const { import std.conv: text; return text("Foo(", i, ")"); }
    }

    static assert(!__traits(compiles, Printable(Foo(42))));
    auto p = Printable.create!Foo(42);
    p.stringify.should == "Foo(42)";
    p.inc;
    p.stringify.should == "Foo(43)";
}
