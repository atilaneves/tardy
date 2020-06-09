module tardy.allocators;


struct InSitu(size_t N) {

    private ubyte[N] _buffer;

    void[] allocate(size_t n) {
        return _buffer[0 .. n];
    }

    void deallocate(void[] buf) {
        if(buf.ptr !is _buffer.ptr)
            throw new Exception("Not my buffer");
    }
}
