module tardy.allocators;

struct InSitu(size_t N) {
    ubyte[N] _;
}
