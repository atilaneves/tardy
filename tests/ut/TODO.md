Proper refraction
@safe pure @nogc?
Policies:
   Storage of instance (heap, insitu/heap, insitu)
   Storage of vtable (heap, insitu/heap, insitu)
   Allocation of instance (GC, allocator, ...)
   Allocation of vtable (GC, allocator, ...)
   Order of declaration of instance and vtable (could affect speed and/or alignment)
   value semantics or not (default yes)
   opCmp, maybe other operators?
