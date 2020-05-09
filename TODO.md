Proper refraction
  * Default values for parameters
  * Overloads

ctors/dtors:
  * Destructors
  * @disable this();
  * Construct a const/immutable/shared polymorphic object without casting
  * Forwarding arguments to T's constructor instead of passing a new instance

Copy-on-write: equivalent of `shared_ptr<const Foo>`.

Policies:
   Signature of the copy constructor (@safe? pure?)
   Storage of instance (heap, insitu/heap, insitu)
   Storage of vtable (heap, insitu/heap, insitu)
   Allocation of instance (GC, allocator, ...)
   Allocation of vtable (GC, allocator, ...)
   Order of declaration of instance and vtable (could affect speed and/or alignment)
   value semantics or not (default yes)
   opCmp, maybe other operators?

Plug:
  * Currently instances can have non-pure implementations even if the interface says
    pure. Fix it. Same with scope. const and @safe are correctly handled.
