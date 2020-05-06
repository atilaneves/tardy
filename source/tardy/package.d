module tardy;


/**
   A wrapper that acts like a subclass of Interface, dispatching
   at runtime to different instance instances.
 */
struct Polymorphic(Interface) if(is(Interface == interface)){

    private void* _instance;
    private immutable VirtualTable!Interface _vtable;

    this(Instance)(auto ref Instance instance) {
        this(constructInstance!Instance(instance), vtable!(Interface, Instance));
    }

    this(ref scope const(Polymorphic) other) {
        _vtable = other._vtable;
        _instance = other._vtable.copyConstructor(other._instance);
    }

    /**
       This factory function makes it possible to pass in modules
       to look for UFCS functions for the instance
     */
    template create(Modules...) {
        static create(Instance)(Instance instance) {
            return Polymorphic!Interface(constructInstance!Instance(instance),
                                         vtable!(Interface, Instance, Modules));
        }
    }

    private this(void* instance, immutable VirtualTable!Interface vtable) {
        _instance = instance;
        _vtable = vtable;
    }

    auto opDispatch(string identifier, this This, A...)(A args) {
        enum vtableEntry = `_vtable.` ~ identifier;
        // each vtable entry is a function pointer, here we get the type of
        // the function this pointer points to
        alias F = typeof(mixin(`*`, vtableEntry, `.init`));

        static if(is(F parameters == __parameters)) {

            enum notMutable = is(This == const) || is(This == immutable);

            static if(notMutable && is(parameters[0] == void*)) {
                // we use a pragma(msg) here instead of in the static assert
                // because when opDispatch doesn't compile the compiler
                // doesn't really tell the user why, and the message in the
                // static assert is never seen
                pragma(msg, "ERROR: Cannot call mutable method " ~ identifier ~ " on " ~ This.stringof);
                static assert(false);
            } else {
                mixin(`assert(`, vtableEntry, ` !is null, "null vtable entry for '`, identifier, `'");`);
                mixin(`return `, vtableEntry, `(_instance, args);`);
            }
        } else
            static assert(false);
    }
}


/**
   A virtual table for Interface.

   Has one function pointer slot for every function declared
   in the interface type.
 */
struct VirtualTable(Interface) if(is(Interface == interface)) {
    // FIXME:
    // * argument defaults e.g. int i = 42
    // * overloads
    import tardy.refraction: methodRecipe;
    static import std.traits;  // used by methodRecipe

    private enum fullName(string name) = `Interface.` ~ name;

    // Here we declare one function pointer per declaration in Interface.
    // Each function pointer has the same return type and one extra parameter
    // in the first position which is the instance or context.
    static foreach(name; __traits(allMembers, Interface)) {
        mixin(methodRecipe!(mixin(fullName!name))(fullName!name), ` `, name, `;`);
    }

    // The copy constructor has to be in the virtual table since only
    // Polymorphic's constructor knows what the static type is.
    void* function(scope const(void)* otherInstancePtr) @safe copyConstructor;
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

    VirtualTable!Interface ret;

    // 0 -> arg0, 1 -> arg1, ...
    static string argName(size_t i) { return `arg` ~ i.text; }
    // func -> arg0, arg1, ...
    static string argsList(string name)() {
        alias method = mixin(`Interface.`, name);
        return Parameters!method
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

    static foreach(name; __traits(allMembers, Interface)) {{

        // copy type qualifiers from self to what we cast void* to
        alias P0 = PointerTarget!(Parameters!(mixin(`ret.`, name))[0]);
        alias InstancePtr = Ptr!(CopyTypeQualifiers!(P0, Instance));

        // FIXME: check that the Instance implements Interface

        // import any modules where we have to look for UFCS implementations
        static foreach(module_; Modules) {
            static if(__traits(hasMember, moduleSymbol!module_, name))
                mixin(importMixin!(module_, name));
        }

        // e.g. ret.foo = (self, arg0, arg1) => (cast (Instance*) self).foo(arg0, arg1);
        // the cast is @trusted because here we know the static type
        mixin(`ret.`, name, ` = (self, `, argsList!name, `) => (() @trusted { return cast(InstancePtr) self; }()).`, name, `(`, argsList!name, `);`);
    }}

    ret.copyConstructor = (otherPtr) {
        // Like above, casting is @trusted because we know the static type
        auto otherInstancePtr = () @trusted { return cast(const(Instance)*) otherPtr; }();
        return constructInstance!Instance(*otherInstancePtr);
    };

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
