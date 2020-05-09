module tardy;


/**
   A wrapper that acts like a subclass of Interface, dispatching
   at runtime to different instance instances.
 */
struct Polymorphic(Interface) if(is(Interface == interface)){

    private immutable(VirtualTable!Interface)* _vtable;
    private void* _instance;

    this(Instance)(auto ref Instance instance) {
        this(constructInstance!Instance(instance), vtable!(Interface, Instance));
    }

    this(ref scope const(Polymorphic) other) {
        _vtable = other._vtable;
        _instance = other._vtable.copyConstructor(other._instance);
    }

    /**
       This factory function makes it possible to pass in modules
       to look for UFCS functions for the instance.
     */
    template create(Modules...) {
        static create(Instance)(Instance instance) {
            return Polymorphic!Interface(
                constructInstance!Instance(instance),
                vtable!(Interface, Instance, Modules)
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
            return Polymorphic!Interface(
                constructInstance!T(args),
                vtable!(Interface, T, Modules)
            );
        }
    }

    private this(void* instance, immutable(VirtualTable!Interface)* vtable) {
        _instance = instance;
        _vtable = vtable;
    }

    ~this() {
        _vtable.destructor(_instance);
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
struct VirtualTable(Interface) if(is(Interface == interface)) {
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
    alias CopyConstructorBase = void* function(scope const(void)* otherInstancePtr);
    alias DestructorBase = void function(scope const(void)* self);

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


private auto functionAttributesFromInterface(Interface, string name)() {
    import std.traits: FA = FunctionAttribute;
    static if(__traits(hasMember, Interface, name)) {
        static assert(is(typeof(__traits(getMember, Interface, name)) == FA));
        return __traits(getMember, Interface, name);
    } else
        return FA.safe;
}


/**
   Creates a virtual table for the given Instance that implements
   the given Interface.

   This function assigns every slot in VirtualTable!Interface with
   a function pointer that delegates to the Instance type.
 */
auto vtable(Interface, Instance, Modules...)() {

    import std.conv: text;
    import std.string: join;
    import std.traits: Parameters, fullyQualifiedName, PointerTarget, CopyTypeQualifiers;
    import std.algorithm: map;
    import std.range: iota;

    auto ret = new VirtualTable!Interface;

    // 0 -> arg0, 1 -> arg1, ...
    static string argName(size_t i) { return `arg` ~ i.text; }
    // func -> arg0, arg1, ...
    static string argsList(string name, size_t i)() {
        import std.conv: text;
        alias vtableEntry = mixin(text(`__traits(getOverloads, Interface, "`, name, `")[`, i, `]`));
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

                // e.g. ret.foo = (self, arg0, arg1) => (cast (Instance*) self).foo(arg0, arg1);
                // the cast is @trusted because here we know the static type
                mixin(`ret.`, name, i.text, ` = `,
                      `(self, `, argsList!(name, i), `) => `,
                      `(() @trusted { return cast(InstancePtr) self; }()).`, name, `(`, argsList!(name, i), `);`);
            }}
        }
    }

    ret.copyConstructor = (otherPtr) {
        // Like above, casting is @trusted because we know the static type
        auto otherInstancePtr = () @trusted { return cast(const(Instance)*) otherPtr; }();
        return constructInstance!Instance(*otherInstancePtr);
    };

    static if(__traits(hasMember, Instance, "__dtor")) {
        ret.destructor = (selfUntyped) {
            import std.traits: isSafe;

            // Like above, casting is @trusted because we know the static type
            auto self = () @trusted { return cast(const(Instance)*) selfUntyped; }();
            static if(isSafe!(__traits(getMember, Instance, "__dtor")))
                destroy(*self);
            else
                static assert(false, "Cannot call unsafe destructor from " ~ T.stringof);
        };
    } else
        ret.destructor = (selfUntyped) {};

    return ret;
}


private void* constructInstance(Instance, A...)(auto ref A args) {
    import std.traits: Unqual, isCopyable;
    import std.conv: emplace;

    static if(is(Instance == class)) {
        static if(__traits(compiles, emplace(cast(Unqual!Instance) null, args))) {
            auto buffer = new void[__traits(classInstanceSize, Instance)];
            auto newInstance = () @trusted { return cast(Unqual!Instance) buffer.ptr; }();
            emplace(newInstance, args);
            return &buffer[0];
        } else {
            auto newInstance = new Unqual!Instance;
            return () @trusted { return cast(void*) newInstance; }();
        }

    } else {
        static if(__traits(compiles, new Unqual!Instance(args)))
            return new Unqual!Instance(args);
        else static if(isCopyable!Instance) {
            auto instance = new Unqual!Instance;
            *instance = args[0];
            return instance;
        } else static if(__traits(compiles, emplace(new Unqual!Instance, args))) {
            auto instance = new Unqual!Instance;
            emplace(instance, args);
            return instance;
        } else {
            auto instance = new Unqual!Instance;
            return instance;
        }
    }
}
