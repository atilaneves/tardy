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


struct VirtualTable(T) {
    int function(const void* self, int i) transform;
}


auto vtable(Interface, Instance)() {
    return VirtualTable!Interface(
        (self, i) => (cast(Instance*) self).transform(i),
    );
}
