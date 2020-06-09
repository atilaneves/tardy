module ut.memory.allocators;


import ut;


@("sizeof")
@safe pure unittest {
    InSitu!16 insitu16;
    static assert(insitu16.sizeof == 16);
}
