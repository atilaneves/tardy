module foo;


struct Polymorphic(Interface) {

    private void* _model;
    private const VirtualTable!Interface _vtable;

    this(Model)(Model model) {
        auto thisModel = new Model;
        *thisModel = model;
        _model = thisModel;
        _vtable = vtable!(Interface, Model);
    }

    auto opDispatch(string identifier, A...)(A args) inout {
        mixin(`return _vtable.`, identifier, `(_model, args);`);
    }
}


struct VirtualTable(Interface) if(is(Interface == interface)) {
    // FIXME:
    // * argument defaults e.g. int i = 42
    // * `this` modifiers (const, scope, ...)
    // * @safe pure
    // * overloads
    import std.traits: ReturnType, Parameters;

    private enum member(string name) = __traits(getMember, Interface, name);

    static foreach(name; __traits(allMembers, Interface)) {
        // FIXME: decide when to use void* vs const void*
        mixin(`ReturnType!(Interface.`, name, `) function(const void*, Parameters!(Interface.`, name, `)) `, name, `;`);
    }
}


auto vtable(Interface, Instance)() {

    import std.conv: text;
    import std.string: join;
    import std.traits: Parameters;
    import std.algorithm: map;
    import std.range: iota;

    VirtualTable!Interface ret;

    static string argName(size_t i) { return `arg` ~ i.text; }
    static string argsList(string name)() {
        alias method = mixin(`Interface.`, name);
        return Parameters!method
            .length
            .iota
            .map!argName
            .join(`, `);
    }

    static foreach(name; __traits(allMembers, Interface)) {
        mixin(`ret.`, name, ` = (self, `, argsList!name, `) => (cast (Instance*) self).`, name, `(`, argsList!name, `);`);
    }

    return ret;
}
