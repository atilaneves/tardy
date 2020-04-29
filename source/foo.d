module foo;


struct Polymorphic(Interface) {

    void* model;
    VirtualTable vtable;

    this(T)(T model) {
        auto thisModel = new T;
        *thisModel = model;
        this.model = thisModel;
        this.vtable = .vtable!T;
    }

    int transform(int i) {
        return vtable.transform(model, i);
    }
}


struct VirtualTable {
    int function(void* self, int i) transform;
}


VirtualTable vtable(T)() {
    return VirtualTable(
        (self, i) => (cast(T*) self).transform(i),
    );
}
