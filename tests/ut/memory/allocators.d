module ut.memory.allocators;


import ut;


@("insitu.sizeof")
@safe pure unittest {
    static assert(InSitu!16.sizeof == 16);
    static assert(InSitu!32.sizeof == 32);
}


@("insitu.allocate")
@safe pure unittest {
    import core.exception: RangeError;

    InSitu!16 allocator;
    auto buf = allocator.allocate(2);
    buf.length.should == 2;
    allocator.allocate(16);
    allocator.allocate(17).shouldThrow!RangeError;
}


@("insitu.deallocate")
@safe pure unittest {
    InSitu!16 allocator;
    void[] buf;

    version(nodip1008) {
        import core.exception: AssertError;
        alias Class = AssertError;
    } else
          alias Class = Exception;

    allocator.deallocate(buf).shouldThrow!Class;
    allocator.deallocate(allocator.allocate(5));
}


@("sbo.sizeof")
@safe pure unittest {
    static assert(SBOAllocator!16.sizeof == 16);
    static assert(SBOAllocator!32.sizeof == 32);
}
