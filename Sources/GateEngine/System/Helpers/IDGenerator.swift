/*
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

#if canImport(Atomics)
import Atomics
#elseif canImport(Foundation.NSLock)
import class Foundation.NSLock
#endif

#if canImport(Atomics)
public final class IDGenerator<T: AtomicInteger> {
    var value: ManagedAtomic<T>

    public init(startValue: T = 0) {
        value = ManagedAtomic<T>(startValue)
    }

    public func generateID() -> T {
        return value.wrappingIncrementThenLoad(ordering: .sequentiallyConsistent)
    }
}
#elseif canImport(Foundation.NSLock)
public final class IDGenerator<T: BinaryInteger> {
    var value: T = 0
    let lock = NSLock()

    public init(startValue: T = 0) {
        self.value = startValue
    }

    public func generateID() -> T {
        lock.lock()
        value += 1
        defer {
            lock.unlock()
        }
        return value
    }
}
#else
public final class IDGenerator<T: BinaryInteger> {
    var value: T = 0

    public init(startValue: T = 0) {
        self.value = startValue
    }

    public func generateID() -> T {
        value += 1
        return value
    }
}
#endif
