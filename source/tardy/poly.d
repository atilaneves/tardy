module tardy.poly;


import tardy.from;


alias DefaultAllocator = from!"tardy.allocators".GC;

/**
   A wrapper that acts like a subclass of Interface, dispatching
   at runtime to different instances of different types.
 */
struct Polymorphic(Interface, InstanceAllocator = DefaultAllocator)
    if(is(Interface == interface))
{
    import std.traits: Unqual;
    import std.experimental.allocator: stateSize, theAllocator;

    enum instanceAllocatorHasState = stateSize!InstanceAllocator != 0;

    private alias VTable = VirtualTable!(Interface, InstanceAllocator);

    private immutable(VTable)* _vtable;
    private void* _instance;

    static if(instanceAllocatorHasState) {
        static if(is(Unqual!InstanceAllocator == typeof(theAllocator())))
            private alias _allocator = theAllocator;
        else
            private InstanceAllocator _allocator;
    } else
        private alias _allocator = InstanceAllocator.instance;

    this(this This, Instance)(auto ref Instance instance) {
        this(
            constructInstance!Instance(_allocator, instance),
            vtable!(Interface, Instance, InstanceAllocator),
        );
    }

    this(ref scope const(Polymorphic) other) {
        _vtable = other._vtable;
        _instance = other._vtable.copyConstructor(other, _allocator);
    }

    /**
       This factory function makes it possible to pass in modules
       to look for UFCS functions for the instance.
     */
    template create(Modules...) {
        static create(Instance)(Instance instance) {
            return Polymorphic(
                constructInstance!Instance(_allocator, instance),
                vtable!(Interface, Instance, InstanceAllocator, Modules),
            );
        }
    }

    /**
       This factory function makes it possible to forward arguments to
       the T's constructor instead of taking one by value and to pass
       in modules to look for UFCS functions for the instance.
     */
    template create(T, Modules...) {
        static create(A...)(auto ref A args) {
            return Polymorphic(
                constructInstance!T(_allocator, args),
                vtable!(Interface, T, InstanceAllocator, Modules),
            );
        }
    }

    private this(this This)(void* instance, immutable(VTable)* vtable) {
        // the cast is because of type qualifiers, and is safe because this constructor
        // is private
        _instance = () @trusted { return cast(typeof(_instance)) instance; }();
        _vtable = vtable;
    }

    ~this()
        in(_vtable !is null)
        do
    {
        _vtable.destructor(this);
    }

    // From here we declare one member function per declaration in Interface, with
    // the same signature
    import tardy.refraction: methodRecipe;
    import std.format: format;
    static import std.traits;

    private alias overload(string name, size_t i) = __traits(getOverloads, Interface, name)[i];
    private enum numParams(string name, size_t i) = std.traits.Parameters!(overload!(name, i)).length;

    static string memberFunctionMixin(string memberName, size_t i)() {
        import std.conv: text;

        enum name = text(`__traits(getOverloads, Interface, "`, memberName, `")[`, i, `]`);

        return
            methodRecipe!(overload!(memberName, i))
                         (name)
            ~
            q{{

                assert(_vtable.%s%d !is null);
                return _vtable.%s%d(_instance, %s);

            }}.format(
                memberName, i,
                memberName, i, argsCall(numParams!(memberName, i)),
            );
    }

    static foreach(memberName; __traits(allMembers, Interface)) {
        static if(is(typeof(__traits(getMember, Interface, memberName)) == function)) {
            static foreach(i, overload; __traits(getOverloads, Interface, memberName)) {
                mixin(memberFunctionMixin!(memberName, i));
            }
        }
    }
}


private string argsCall(size_t length)
    in(__ctfe)
    do
{
    import std.range: iota;
    import std.algorithm: map;
    import std.array: join;
    import std.conv: text;
    return length.iota.map!(i => text("arg", i)).join(", ");
}

/**
   A virtual table for Interface.

   Has one function pointer slot for every function declared
   in the interface type.
 */
struct VirtualTable(Interface, InstanceAllocator) if(is(Interface == interface)) {
    import tardy.refraction: vtableEntryRecipe;
    import std.traits: FA = FunctionAttribute;
    import std.conv: text;
    static import std.traits;  // used by vtableEntryRecipe

    private enum fullName(string name, size_t i) = text(`__traits(getOverloads, Interface, "`, name, `")[`, i, `]`);

    // Here we declare one function pointer per declaration in Interface.
    // Each function pointer has the same return type and one extra parameter
    // in the first position which is the instance or context.
    static foreach(name; __traits(allMembers, Interface)) {
        static if(is(typeof(__traits(getMember, Interface, name)) == function)) {
            static foreach(i, overload; __traits(getOverloads, Interface, name)) {
                // e.g. ReturnType!(I.foo) function(void*, Parameters!(I.foo)) foo;
                mixin(vtableEntryRecipe!(__traits(getOverloads, Interface, name)[i])
                                        (fullName!(name, i)),
                      ` `, name, i.text, `;`);
            }
        }
    }

    // The destructor and copy constructor have to be in the virtual table
    // since the only point we know the static type is when constructing.
    alias CopyConstructorBase = void* function(
        scope ref const Polymorphic!(Interface, InstanceAllocator) other,
        ref AllocatorType!InstanceAllocator allocator,
    );
    alias DestructorBase = void function(ref Polymorphic!(Interface, InstanceAllocator) self);

    alias CopyConstructor = std.traits.SetFunctionAttributes!(
        CopyConstructorBase,
        "D",
        functionAttributesFromInterface!(Interface, "CopyConstructorAttrs"),
    );
    alias Destructor = std.traits.SetFunctionAttributes!(
        DestructorBase,
        "D",
        functionAttributesFromInterface!(Interface, "DestructorAttrs"),
    );

    // The copy constructor has to be in the virtual table since only
    // Polymorphic's constructor knows what the static type is.
    CopyConstructor copyConstructor;

    // The destructor has to be in the virtual table since only
    // Polymorphic's constructor knows what the static type is.
    Destructor destructor;
}


private from!"std.traits".FunctionAttribute functionAttributesFromInterface
    (Interface, string name)()
{
    import std.traits: FA = FunctionAttribute;
    static if(__traits(hasMember, Interface, name)) {
        static assert(is(typeof(__traits(getMember, Interface, name)) == FA));
        return __traits(getMember, Interface, name);
    } else
        return FA.safe;
}

// 0 -> arg0, 1 -> arg1, ...
private string argName(size_t i) { import std.conv: text; return `arg` ~ i.text; }

/**
   Creates a virtual table for the given Instance that implements
   the given Interface.

   This function assigns every slot in VirtualTable!Interface with
   a function pointer that delegates to the Instance type.
 */
template vtable(Interface, Instance, InstanceAllocator, Modules...) {

    private static immutable VirtualTable!(Interface, InstanceAllocator) _tab;

    shared static this() {
        _tab = vtableImpl!(Interface, Instance, InstanceAllocator, Modules);
    }

    auto vtable() {
        return &_tab;
    }
}

private auto vtableImpl(Interface, Instance, InstanceAllocator, Modules...)() {

    import std.conv: text;
    import std.string: join;
    import std.traits: Parameters, fullyQualifiedName, PointerTarget, CopyTypeQualifiers;
    import std.format: format;

    VirtualTable!(Interface, InstanceAllocator) ret;

    // func -> arg0, arg1, ...
    static string argsList(string name, size_t i)() {
        import std.algorithm.iteration: map;
        import std.range: iota;
        import std.array: join;

        alias vtableEntry = __traits(getOverloads, Interface, name)[i];
        return Parameters!vtableEntry
            .length
            .iota
            .map!argName
            .join(`, `);
    }

    template moduleName(alias module_) {
        static if(is(typeof(module_) == string))
            enum moduleName = module_;
        else
            enum moduleName = fullyQualifiedName!(module_);
    }

    template moduleSymbol(alias module_) {
        static if(is(typeof(module_) == string)) {
            mixin(`import the_module = `, module_, `;`);
            alias moduleSymbol = the_module;
        }
        else
            alias moduleSymbol = module_;
    }

    enum importMixin(alias module_, string name) = `import ` ~ moduleName!module_ ~ `:` ~ name ~ `;`;

    template Ptr(T) {
        static if(is(T == class))
            alias Ptr = T;
        else
            alias Ptr = T*;
    }

    static string assignRecipe(string function_, string vtableEntry, size_t i)() {
        enum args = argsList!(vtableEntry, i);
        return q{
            ret.%s%d = (self, %s) => %s(self).%s(%s);
        }.format(vtableEntry, i, args, function_, vtableEntry, args);
    }

    template alwaysByPointer(InstancePtr) {
        static impl(T)(T self) @trusted {
            return cast(InstancePtr) self;
        }
    }

    static foreach(name; __traits(allMembers, Interface)) {
        static if(is(typeof(__traits(getMember, Interface, name)) == function)) {
            static foreach(i, overload; __traits(getOverloads, Interface, name)) {{

                // P0 is the first parameter which is the context pointer or self
                alias P0 = PointerTarget!(Parameters!(mixin(`typeof(ret.`, name, i.text, `)`))[0]);
                // copy type qualifiers (const, ...) from self to what we cast void* to
                alias InstancePtr = Ptr!(CopyTypeQualifiers!(P0, Instance));

                // FIXME: better error messages when Instance doesn't implement Interface?

                // import any modules where we have to look for UFCS implementations
                static foreach(module_; Modules) {
                    static if(__traits(hasMember, moduleSymbol!module_, name))
                        mixin(importMixin!(module_, name));
                }

                static if(is(Instance == class)) {
                    alias instanceByRef = alwaysByPointer!InstancePtr.impl;
                    alias instanceByPtr = alwaysByPointer!InstancePtr.impl;
                } else {
                    static ref instanceByRef(T)(T self) {
                        return *alwaysByPointer!InstancePtr.impl(self);
                    }

                    alias instanceByPtr = alwaysByPointer!InstancePtr.impl;
                }

                // Both of these are essentially:
                // e.g. ret.foo = (self, arg0, arg1) => (cast (Instance*) self).foo(arg0, arg1);
                enum byRefRecipe = assignRecipe!(`instanceByRef`, name, i);
                enum byPtrRecipe = assignRecipe!(`instanceByPtr`, name, i);
                // pragma(msg, byRefRecipe);
                // pragma(msg, byPtrRecipe);

                void implByRef()() { mixin(byRefRecipe); }
                void implByPtr()() { mixin(byPtrRecipe); }

                static if(is(typeof(&implByPtr!()))) {
                    mixin(byPtrRecipe);
                } else static if(is(typeof(&implByRef!()))) {
                    mixin(byRefRecipe);
                } else {
                    // mixin(byPtrRecipe);
                    // mixin(byRefRecipe);
                    static assert(false, "Neither of these compiled:" ~ byRefRecipe ~ byPtrRecipe);
                }
            }}
        }
    }


    ret.copyConstructor = (ref const other, ref allocator) {
        import std.traits: isCopyable;

        static if(isCopyable!Instance) {

            static if(is(Instance == class))
                alias InstancePtr = Instance;
            else
                alias InstancePtr = Instance*;

            // Like above, casting is @trusted because we know the static type
            auto otherInstancePtr = () @trusted { return cast(InstancePtr) other._instance; }();

            static if(is(Instance == class))
                auto otherLvalue = otherInstancePtr;
            else
                auto otherLvalue = *otherInstancePtr;

            return constructInstance!Instance(allocator, otherLvalue);
        } else {
            import std.traits: fullyQualifiedName;
            throw new Exception("Cannot copy an instance of " ~ fullyQualifiedName!Instance);
        }
    };

    ret.destructor = (ref self) {
        import std.experimental.allocator: dispose;
        import std.traits: isArray, Unqual;
        import std.range.primitives: ElementEncodingType;

        auto instance = () @trusted { return cast(Instance*) self._instance; }();

        void disp() {
            self._allocator.dispose(instance);
        }

        static if(canSafelyFree!(typeof(self._allocator)))
            () @trusted { disp; }();
        else
            disp;
    };

    return ret;
}


template canSafelyFree(InstanceAllocator) {
    import tardy.allocators: GC;
    import std.traits: Unqual;
    enum canSafelyFree = is(Unqual!InstanceAllocator == Unqual!GC);
}

private void* constructInstance(Instance, InstanceAllocator, A...)
                               (ref InstanceAllocator allocator, auto ref A args)
{
    import std.traits: Unqual, isCopyable, isArray, isSafe;
    import std.range.primitives: ElementEncodingType;
    import std.experimental.allocator: make, makeArray;

    static if(is(typeof(allocator.isNull)))
        assert(!allocator.isNull,
               "Cannot construct instance with null allocator of type " ~ InstanceAllocator.stringof);

    static if(is(Instance == class)) {
        import tardy.allocators: GC;

        static if(A.length == 1 && is(A[0]: Instance) && is(InstanceAllocator == GC)) {

            return () @trusted { return cast(void*) args[0]; }();

        } else static if(__traits(compiles, () @trusted { allocator.make!Instance(args); } )) {

            auto make_() {
                return allocator.make!Instance(args);
            }

            static if(isSafe!({ new Instance(args); }) && isSafe!({ cast(void) allocator.allocate(1); }))
                auto instance = () @trusted { return make_; }();
            else
                auto instance = make_;
            return () @trusted { return cast(void*) instance; }();
        } else {

            auto make_() {
                return allocator.make!Instance;
            }

            static if(__traits(compiles, () @trusted { allocator.make!Instance; } )) {
                static if(isSafe!({ new Instance; }) && isSafe!({ cast(void) allocator.allocate(1); }))
                    auto instance = () @trusted { return make_; }();
                else
                    auto instance = make_;
            }

            return () @trusted { return cast(void*) instance; }();
        }

    } else {

        enum canCopy =
            (isArray!Instance && is(typeof(allocator.makeArray!(ElementEncodingType!Instance)(args[0]))))
            || (!isArray!Instance && is(Unqual!Instance == Unqual!(A[0])));

        static if(__traits(compiles, new Unqual!Instance(args))) {
            return allocator.make!Instance(args);
        } else static if(__traits(compiles, allocator.make!Instance(args))) {
            return allocator.make!Instance(args);
        } else static if(isCopyable!Instance && args.length == 1 && canCopy) {

            static if(isArray!Instance) {
                return allocator.make!(Instance)(args[0]);
            } else {
                auto instance = allocator.make!Instance;
                *instance = args[0];
                return instance;
            }
        } else {
            import std.traits: fullyQualifiedName;
            static assert(false,
                          "Cannot build `" ~ fullyQualifiedName!Instance ~ " from " ~ A.stringof);
        }
    }
}


private template AllocatorType(T) {
    static if(__traits(hasMember, T, "instance"))
        alias AllocatorType = typeof(T.instance);
    else
        alias AllocatorType = T;
}
