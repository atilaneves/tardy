# tardy - runtime polymorphism without inheritance

[![Build Status](https://github.com/atilaneves/tardy/workflows/CI/badge.svg)](https://github.com/atilaneves/tardy/actions)
[![Coverage](https://codecov.io/gh/atilaneves/tardy/branch/master/graph/badge.svg)](https://codecov.io/gh/atilaneves/tardy)

## What?

```d
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
    int transform(int i) @safe pure const { return i + 1; }
}

unittest {
    assert(xform(Transformer(Adder(2))) == 5);
    assert(xform(Transformer(Adder(3))) == 6);

    assert(xform(Transformer(Plus1())) == 4);
}
```

## Why?

Traditional inheritance-based runtime polymorphism has a few drawbacks:

  * Classes must inherit the memory layout of their parent classes.
  * Bakes in reference semantics.
    * Must be careful with "copies" (actually references)
    * All instances are nullable
  * User-defined classes must be written with inheritance in mind so
    using third-party code is sometimes not possible without a
    wrapper. In other words, the set of types that can participate is
    closed.
  * Mandatory heap allocations for the virtual table and the instance...
  * ... which means ownership issues if not using the GC
  * Doesn't work well with algorithms expecting values (consider sorting)

Louis Dionne explained it better and in more detail [in his talk](https://www.youtube.com/watch?v=OtU51Ytfe04&feature=youtu.be).

Tardy makes it so:

* Structs, classes, and other values (ints, arrays, etc. via UFCS) can implement an interface.
* The resulting instances have value semantics.
* An allocator can be specified for storage allocation (defaults to the GC).
* Function attributes can be specified for the generated copy constructor and destructor for instances.


## Creating instances

Instances may be created by passing a value to `Polymorphic`'s constructor or by emplacing them
and having `Polymorphic` call the instance type's contructor itself. The examples above show
how to construct using a value. To explicitly instantiate a particular type:

```d
auto t = Polymorphic!MyInterface.create!MyType(arg0, arg1, arg2, ...);
```

One can also pass modules to `create` where `Polymorphic` should look for UFCS candidates:

```d
// Using the `Transfomer` example above, and assuming there's a
// UFCS function in one of "mymod0" or "mymod1",
// this constructs an `int` "instance"

auto t = Transformer.create!("mymod0", "mymod1")(42);
```

## Specifying function attributes for the copy constructor and destructor

The vtable type is constructed at compile-time by reflecting on the interface passed
as the first template parameter passed to `Polymorphic`. To not overly constrain what users
may do with their types (`@safe`, `pure`, ...), the default is `@safe`, but attributes
can be specified for each of these compiler-generated member functions:

```d
interface MyInterface {
    import std.traits: FA = FunctionAttribute;
    enum CopyConstructorAttrs = FA.safe | FA.pure_;
    enum DestructorAttrs = FA.pure_ | FA.nogc;
}
```
