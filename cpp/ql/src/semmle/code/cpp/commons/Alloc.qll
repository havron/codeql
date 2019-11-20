import cpp

private predicate allocationFunctionWithSize(Function f, int sizeArg) {
  exists(string name |
    f.hasGlobalOrStdName(name) and
    (
      (name = "malloc" and sizeArg = 0) // malloc(size)
    )
    or
    f.hasGlobalName(name) and
    (
      (name = "ExAllocatePool" and sizeArg = 1) or // ExAllocatePool(type, size)
      (name = "ExAllocatePoolWithTag" and sizeArg = 1) or // ExAllocatePool(type, size, tag)
      (name = "ExAllocatePoolWithTagPriority" and sizeArg = 1) or // ExAllocatePoolWithTagPriority(type, size, tag, priority)
      (name = "ExAllocatePoolWithQuota" and sizeArg = 1) or // ExAllocatePoolWithQuota(type, size)
      (name = "ExAllocatePoolWithQuotaTag" and sizeArg = 1) or // ExAllocatePoolWithQuotaTag(type, size, tag)
      (name = "IoAllocateMdl" and sizeArg = 1) or // IoAllocateMdl(address, size, flag, flag, irp)
      (name = "IoAllocateErrorLogEntry" and sizeArg = 1) or // IoAllocateErrorLogEntry(object, size)
      (name = "MmAllocateContiguousMemory" and sizeArg = 0) or // MmAllocateContiguousMemory(size, maxaddress)
      (name = "MmAllocateContiguousNodeMemory" and sizeArg = 0) or // MmAllocateContiguousNodeMemory(size, minaddress, maxaddress, bound, flag, prefer)
      (name = "MmAllocateContiguousMemorySpecifyCache" and sizeArg = 0) or // MmAllocateContiguousMemorySpecifyCache(size, minaddress, maxaddress, bound, type)
      (name = "MmAllocateContiguousMemorySpecifyCacheNode" and sizeArg = 0) or // MmAllocateContiguousMemorySpecifyCacheNode(size, minaddress, maxaddress, bound, type, prefer)
      (name = "MmAllocateNonCachedMemory" and sizeArg = 0) or // MmAllocateNonCachedMemory(size)
      (name = "MmAllocateMappingAddress" and sizeArg = 0) or // MmAllocateMappingAddress(size, tag)
      (name = "MmAllocatePagesForMdl" and sizeArg = 3) or // MmAllocatePagesForMdl(minaddress, maxaddress, skip, size)
      (name = "MmAllocatePagesForMdlEx" and sizeArg = 3) or // MmAllocatePagesForMdlEx(minaddress, maxaddress, skip, size, type, flags)
      (name = "MmAllocateNodePagesForMdlEx" and sizeArg = 3) or // MmAllocateNodePagesForMdlEx(minaddress, maxaddress, skip, size, type, prefer, flags)
      (name = "LocalAlloc" and sizeArg = 1) or // LocalAlloc(flags, size)
      (name = "GlobalAlloc" and sizeArg = 1) or // GlobalAlloc(flags, size)
      (name = "HeapAlloc" and sizeArg = 2) or // HeapAlloc(heap, flags, size)
      (name = "VirtualAlloc" and sizeArg = 1) or // VirtualAlloc(address, size, type, flag)
      (name = "CoTaskMemAlloc" and sizeArg = 0) // CoTaskMemAlloc(size)
    )
  )
}

private predicate allocationFunctionWithSizeAndMult(Function f, int sizeArg, int multArg) {
  exists(string name |
    f.hasGlobalOrStdName(name) and
    (name = "calloc" and sizeArg = 1 and multArg = 0) // calloc(num, size)
  )
}

private predicate allocationFunctionWithSizeRealloc(Function f, int sizeArg, int reallocArg) {
  exists(string name |
    f.hasGlobalOrStdName(name) and
    (
      (name = "realloc" and sizeArg = 1 and reallocArg = 0) // realloc(ptr, size)
    )
    or
    f.hasGlobalName(name) and
    (
      (name = "LocalReAlloc" and sizeArg = 1 and reallocArg = 0) or // LocalReAlloc(ptr, size, flags)
      (name = "GlobalReAlloc" and sizeArg = 1 and reallocArg = 0) or // GlobalReAlloc(ptr, size, flags)
      (name = "HeapReAlloc" and sizeArg = 3 and reallocArg = 2) or // HeapReAlloc(heap, flags, ptr, size)
      (name = "CoTaskMemRealloc" and sizeArg = 1 and reallocArg = 0) // CoTaskMemRealloc(ptr, size)
    )
  )
}

private predicate allocationFunctionNoSize(Function f) {
  exists(string name |
    f.hasGlobalOrStdName(name) and
    (
      name = "strdup" or // strdup(str)
      name = "wcsdup" // wcsdup(str)
    )
    or
    f.hasGlobalName(name) and
    (
      name = "_strdup" or // _strdup(str)
      name = "_wcsdup" or // _wcsdup(str)
      name = "_mbsdup" or // _mbsdup(str)
      name = "ExAllocateFromLookasideListEx" or // ExAllocateFromLookasideListEx(list)
      name = "ExAllocateFromPagedLookasideList" or // ExAllocateFromPagedLookasideList(list)
      name = "ExAllocateFromNPagedLookasideList" or // ExAllocateFromNPagedLookasideList(list)
      name = "ExAllocateTimer" or // ExAllocateTimer(callback, context, attributes)
      name = "IoAllocateWorkItem" or // IoAllocateWorkItem(object)
      name = "MmMapLockedPagesWithReservedMapping" or // MmMapLockedPagesWithReservedMapping(address, tag, list, type)
      name = "MmMapLockedPages" or // MmMapLockedPages(list, mode)
      name = "MmMapLockedPagesSpecifyCache" // MmMapLockedPagesSpecifyCache(list, mode, type, address, flag, flag)
    )
  )
}

/**
 * An allocation function such as `malloc`.
 */
abstract class MallocFunction extends Function {
  MallocFunction() {
  	allocationFunctionWithSize(this, _) or
  	allocationFunctionWithSizeAndMult(this, _, _) or
  	allocationFunctionWithSizeRealloc(this, _, _) or
  	allocationFunctionNoSize(this)
  }

  /**
   * Gets the index of an argument that controls the allocation size, if any.
   * The actual allocation size is the product of all size arguments *
   * `getSizeMult()`. If there is no result, the size cannot be determined.
   */
  int getASizeArg() {
  	allocationFunctionWithSize(this, result) or
  	allocationFunctionWithSizeAndMult(this, result, _) or
  	allocationFunctionWithSizeRealloc(this, result, _)
  }

  /**
   * Gets a constant multiplier for the allocation size, in bytes (usually 1).
   */
  int getSizeMult() {
  	result = 1
  }

  /**
   * Gets the index of the input pointer argument to be reallocated, if this
   * is a `realloc` function. 
   */
  int getReallocPtrArg() {
    allocationFunctionWithSizeRealloc(this, _, result)
  }
}

private bindingset[f] int round(float f) {
  result = (f + 0.5).floor()
}

/**
 * An allocation expression such as call to `malloc` or a `new` expression.
 */
abstract class AllocationExpr extends Expr {
  AllocationExpr() {
  	exists(MallocFunction malloc |
  	  // alloc call
  	  this.(FunctionCall).getTarget() = malloc and
  	  // realloc(ptr, 0) only frees the pointer
  	  not (
  	    exists(malloc.getReallocPtrArg()) and
  	    this.(FunctionCall).getArgument(malloc.getASizeArg()).getValue().toInt() = 0
  	  )
  	) or
  	this instanceof NewExpr or
  	this instanceof NewArrayExpr
  }

  /**
   * Gets an expression that controls the allocation size, if any. The actual
   * allocation size is the product of all size expressions * `getSizeMult()`.
   * If there is no result, the size cannot be determined.
   */
  Expr getASizeExpr() {
  	exists(FunctionCall fc | fc = this |
  	  result = fc.getArgument(fc.getTarget().(MallocFunction).getASizeArg())
  	) or
  	// new array expr with variable size
  	result = this.(NewArrayExpr).getExtent()
  }


  /**
   * Gets a constant multiplier for the allocation size, in bytes (usually 1).
   */
  int getSizeMult() {
  	exists(FunctionCall fc | fc = this |
  	  result = fc.getTarget().(MallocFunction).getSizeMult()
  	) or
  	(
  	  // new array expr with variable size
  	  exists(this.(NewArrayExpr).getExtent()) and
  	  result = this.(NewArrayExpr).getAllocatedElementType().getSize()
  	)
  }

  /**
   * Gets the size of this allocation in bytes, if it is a fixed size and that
   * size can be determined.
   */
  int getSizeBytes() {
  	(
  	  // exp(sum(log(x))) = product(x)
  	  result = round(sum(Expr e | e = getASizeExpr() | e.getValue().toInt().log()).exp()) * getSizeMult()
  	) or
    result = this.(NewExpr).getAllocatedType().getSize()
    or
    result = this.(NewArrayExpr).getAllocatedType().getSize()
  }

  /**
   * Gets the expression for the input pointer argument to be reallocated, if
   * this is a `realloc` function. 
   */
  Expr getReallocPtr() {
  	exists(FunctionCall fc | fc = this |
  	  result = fc.getArgument(fc.getTarget().(MallocFunction).getReallocPtrArg())
  	)
  }
}

/**
 * A library routine that allocates memory.
 * 
 * DEPRECATED: Use the `MallocFunction` class instead of this predicate.
 */
deprecated predicate allocationFunction(Function f) {
  f instanceof MallocFunction
}

/**
 * A call to a library routine that allocates memory.
 *
 * DEPRECATED: Use `AllocationExpr` instead (this also includes `new` expressions).
 */
deprecated predicate allocationCall(FunctionCall fc) {
  fc instanceof AllocationExpr
}

/**
 * A library routine that frees memory.
 */
predicate freeFunction(Function f, int argNum) {
  exists(string name |
    f.hasGlobalName(name) and
    (
      name = "free" and argNum = 0
      or
      name = "realloc" and argNum = 0
    )
    or
    f.hasGlobalOrStdName(name) and
    (
      name = "ExFreePoolWithTag" and argNum = 0
      or
      name = "ExFreeToLookasideListEx" and argNum = 1
      or
      name = "ExFreeToPagedLookasideList" and argNum = 1
      or
      name = "ExFreeToNPagedLookasideList" and argNum = 1
      or
      name = "ExDeleteTimer" and argNum = 0
      or
      name = "IoFreeMdl" and argNum = 0
      or
      name = "IoFreeWorkItem" and argNum = 0
      or
      name = "IoFreeErrorLogEntry" and argNum = 0
      or
      name = "MmFreeContiguousMemory" and argNum = 0
      or
      name = "MmFreeContiguousMemorySpecifyCache" and argNum = 0
      or
      name = "MmFreeNonCachedMemory" and argNum = 0
      or
      name = "MmFreeMappingAddress" and argNum = 0
      or
      name = "MmFreePagesFromMdl" and argNum = 0
      or
      name = "MmUnmapReservedMapping" and argNum = 0
      or
      name = "MmUnmapLockedPages" and argNum = 0
      or
      name = "LocalFree" and argNum = 0
      or
      name = "GlobalFree" and argNum = 0
      or
      name = "HeapFree" and argNum = 2
      or
      name = "VirtualFree" and argNum = 0
      or
      name = "CoTaskMemFree" and argNum = 0
      or
      name = "SysFreeString" and argNum = 0
      or
      name = "LocalReAlloc" and argNum = 0
      or
      name = "GlobalReAlloc" and argNum = 0
      or
      name = "HeapReAlloc" and argNum = 2
      or
      name = "CoTaskMemRealloc" and argNum = 0
    )
  )
}

/**
 * A call to a library routine that frees memory.
 */
predicate freeCall(FunctionCall fc, Expr arg) {
  exists(int argNum |
    freeFunction(fc.getTarget(), argNum) and
    arg = fc.getArgument(argNum)
  )
}

/**
 * Is e some kind of allocation or deallocation (`new`, `alloc`, `realloc`, `delete`, `free` etc)?
 */
predicate isMemoryManagementExpr(Expr e) { isAllocationExpr(e) or isDeallocationExpr(e) }

/**
 * Is e an allocation from stdlib.h (`malloc`, `realloc` etc)?
 *
 * DEPRECATED: Use `AllocationExpr` instead (this also includes `new` expressions).
 */
deprecated predicate isStdLibAllocationExpr(Expr e) { allocationCall(e) }

/**
 * Is e some kind of allocation (`new`, `alloc`, `realloc` etc)?
 */
predicate isAllocationExpr(Expr e) {
  e.(FunctionCall) instanceof AllocationExpr
  or
  e = any(NewOrNewArrayExpr new | not exists(new.getPlacementPointer()))
}

/**
 * Is e some kind of allocation (`new`, `alloc`, `realloc` etc) with a fixed size?
 *
 * DEPRECATED: Use `AllocationExpr.getSizeBytes()` instead.
 */
deprecated predicate isFixedSizeAllocationExpr(Expr allocExpr, int size) {
  size = allocExpr.(AllocationExpr).getSizeBytes()
}

/**
 * Is e some kind of deallocation (`delete`, `free`, `realloc` etc)?
 */
predicate isDeallocationExpr(Expr e) {
  freeCall(e, _) or
  e instanceof DeleteExpr or
  e instanceof DeleteArrayExpr
}
