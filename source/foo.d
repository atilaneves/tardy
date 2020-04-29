module foo;


struct Polymorphic(Interface) {

    private void* _model;
    private const VirtualTable _vtable;

    this(T)(T model) {
        auto thisModel = new T;
        *thisModel = model;
        _model = thisModel;
        _vtable = vtable!T;
    }

    auto opDispatch(string identifier, A...)(A args) inout {
        mixin(`return _vtable.`, identifier, `(_model, args);`);
    }
}


struct VirtualTable {
    int function(const void* self, int i) transform;
}


VirtualTable vtable(T)() {
    return VirtualTable(
        (self, i) => (cast(T*) self).transform(i),
    );
}
