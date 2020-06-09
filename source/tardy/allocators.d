module tardy.allocators;


import tardy.from;


template SBOAllocator(size_t N) {
    import std.experimental.allocator.building_blocks.fallback_allocator: FallbackAllocator;
    import std.experimental.allocator.mallocator: Mallocator;

    alias SBOAllocator = FallbackAllocator!(
        InSitu!N,
        Mallocator,
    );
}


struct InSitu(size_t N) {

    import std.experimental.allocator: platformAlignment;

    enum alignment = platformAlignment;

    private ubyte[N] _buffer;

    void[] allocate(size_t n) return scope {
        return _buffer[0 .. n];
    }

    bool deallocate(scope void[] buf) const {
        import std.typecons: Ternary;
        import std.traits: functionAttributes, FA = FunctionAttribute;

        static impl() {
            throw new Exception("Not my buffer");
        }

        if(owns(buf) == Ternary.no) {
            static if(functionAttributes!impl & FA.nogc)
                impl;
            else
                assert(false, "Not my buffer");
        }

        return true;
    }

    auto owns(scope void[] buf) const {
        import std.typecons: Ternary;
        return buf.ptr is _buffer.ptr
            ? Ternary.yes
            : Ternary.no;
    }
}
