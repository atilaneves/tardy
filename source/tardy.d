module tardy;


/**
   A wrapper that acts like a subclass of Interface, dispatching
   at runtime to different model instances.
 */
struct Polymorphic(Interface) if(is(Interface == interface)){

    private void* _model;
    private immutable VirtualTable!Interface _vtable;

    this(Model)(Model model) {
        auto thisModel = new Model;
        *thisModel = model;
        _model = thisModel;
        _vtable = vtable!(Interface, Model);
    }

    static construct(Modules...)(int model) {

        Polymorphic!Interface self;

        alias Model = typeof(model);

        auto thisModel = new Model;
        *thisModel = model;
        self._model = thisModel;
        () @trusted { (cast() self._vtable) = vtable!(Interface, Model, Modules); }();

        return self;
    }

    auto opDispatch(string identifier, A...)(A args) inout {
        mixin(`return _vtable.`, identifier, `(_model, args);`);
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
    // * `this` modifiers (const, scope, ...)
    // * @safe pure
    // * overloads
    import std.traits: ReturnType, Parameters;

    private enum member(string name) = __traits(getMember, Interface, name);

    // Here we declare one function pointer per declaration in Interface.
    // Each function pointer has the same return type and one extra parameter
    // in the first position which is the model or context.
    static foreach(name; __traits(allMembers, Interface)) {
        // FIXME: decide when to use void* vs const void*
        mixin(`ReturnType!(Interface.`, name, `) function(const void*, Parameters!(Interface.`, name, `)) `, name, `;`);
    }
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
    import std.traits: Parameters, fullyQualifiedName;
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

    // e.g. ret.foo = (self, arg0, arg1) => (cast (Instance*) self).foo(arg0, arg1);
    static foreach(name; __traits(allMembers, Interface)) {{
        static foreach(module_; Modules) {
            pragma(msg, "module: ", __traits(identifier, module_));
            mixin(`import `, fullyQualifiedName!module_, `;`);
        }
        mixin(`ret.`, name, ` = (self, `, argsList!name, `) => (cast (Instance*) self).`, name, `(`, argsList!name, `);`);
    }}

    return ret;
}
