//
// ObservableThreadSafeClass.swift
// Copyright (c) 2022, Flowduino
// Authored by Simon J. Stuart on 8th July 2022
//
// Subject to terms, restrictions, and liability waiver of the MIT License
//

import Foundation
import ThreadSafeSwift

/**
 Provides custom Observer subscription and notification behaviour for Classes that will be interacting with Multiple Threads
 - Author: Simon J. Stuart
 - Version: 1.0.5
 - Note: The Observers are behind a Semaphore Lock
 - Note: A "Revolving Door" solution has been implemented to ensure that Observer Callbacks can modify the Observers (add/remove) without causing a Deadlock.
 */
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
open class ObservableThreadSafeClass: Observable, ObservableObject {
    /**
     Contains a Weak Reference to an Observer.
     - Author: Simon J. Stuart
     - Version: 1.0
     - Note: This is why all of our Protocols must enforce a constraint of `AnyObject`
     */
    public struct ObserverContainer {
        /**
         Reference to the Observer Object
         - Author: Simon J. Stuart
         - Version: 1.0
         - Note: This Reference **must** be `weak` to prevent Reference Counting from retaining unwanted Objects.
         */
        weak var observer: AnyObject?
        /**
         The `DispatchQueue` from which the Observer registered
         - Author: Simon J. Stuart
         - Version: 1.0
         - Note: This is used to ensure that the Observer's Callbacks are invoked on the Observer's own `DispatchQueue`
         */
        var dispatchQueue: DispatchQueue?
    }
    
    /**
     Dictionary mapping an `ObjectIdentifer` (reference to an Observer Instance) against its `ObserverContainer`
     - Author: Simon J. Stuart
     - Version: 1.0.5
     */
    @ThreadSafeSemaphore private var observers = [ObjectIdentifier : ObserverContainer]()
    
    /**
     Dictionary mapping an `ObjectIdentifer` (reference to an Observer Instance) against its `ObserverContainer`
     - Author: Simon J. Stuart
     - Version: 1.0.5
     - Note: This is used as a temporary "Holding Queue" when the `observers` Dictionary has its Lock retained by another Thread.
     */
    @ThreadSafeSemaphore private var observersAddQueue = [ObjectIdentifier : ObserverContainer]()
        
    /**
     Dictionary mapping an `ObjectIdentifer` (reference to an Observer Instance) against its `ObserverContainer`
     - Author: Simon J. Stuart
     - Version: 1.0.5
     - Note: This is used as a temporary "Holding Queue" when the `observers` Dictionary has its Lock retained by another Thread.
     */
    @ThreadSafeSemaphore private var observersRemoveQueue = [ObjectIdentifier : ObserverContainer]()
        
    public func addObserver<TObservationProtocol: AnyObject>(_ observer: TObservationProtocol) {
        let observation = ObserverContainer(observer: observer, dispatchQueue: OperationQueue.current?.underlyingQueue)
        
        _observers.withTryLock { value in
            value[ObjectIdentifier(observer)] = observation
        } _: {
            self._observersAddQueue.withLock { value in
                value[ObjectIdentifier(observer)] = observation
            }
        }
    }
    
    public func removeObserver<TObservationProtocol: AnyObject>(_ observer: TObservationProtocol) {
        _observers.withTryLock { value in
            value.removeValue(forKey: ObjectIdentifier(observer))
        } _: {
            self._observersRemoveQueue.withLock { value in
                value[ObjectIdentifier(observer)] = ObserverContainer(observer: observer, dispatchQueue: nil) // the Dispatch Queue doesn't matter here!]
            }
        }
    }
    
    /**
     Iterates all Observers and invokes your Closure if they conform to the expected Protocol
     - Author: Simon J. Stuart
     - Version: 1.0.5
     */
    public func withObservers<TObservationProtocol>(_ code: @escaping (_ observer: TObservationProtocol) -> ()) {
        _observers.withLock { observers in
            for (id, observation) in observers {
                guard let observer = observation.observer else { // Check if the Observer still exists
                    observers.removeValue(forKey: id) // If it doesn't, remove the Observer from the collection...
                    continue // ...then continue to the next one
                }
                
                if let typedObserver = observer as? TObservationProtocol {
                    let dispatchQueue = observation.dispatchQueue ?? DispatchQueue.main
                    dispatchQueue.async {
                        code(typedObserver)
                    }
                }
            }
            var addPending = [ObjectIdentifier : ObserverContainer]()
            var removePending = [ObjectIdentifier : ObserverContainer]()

            // Add all pending from the Add Queue
            self._observersAddQueue.withLock { value in
                addPending = value
                value.removeAll()
            }
            for (key, value) in addPending {
                observers[key] = value
            }
            
            // Remove all pending from the Remove Queue
            self._observersRemoveQueue.withLock { value in
                removePending = value
                value.removeAll()
            }
            for (id) in removePending.keys {
                observers.removeValue(forKey: id)
            }
        }
    }
    
    open func notifyChange() {
        Task {
            await notifyChange()
        }
    }
    
    open func notifyChange() async {
        await MainActor.run {
            objectWillChange.send()
        }
    }
    
    public init() {
    
    }
}
