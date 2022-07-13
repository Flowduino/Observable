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
 Provides custom Observer subscription and notification behaviour for Threads
 - Author: Simon J. Stuart
 - Version: 1.0
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
     - Version: 1.0
     */
    @ThreadSafeSemaphore private var observers = [ObjectIdentifier : ObserverContainer]()
    
    
    /**
     Dictionary mapping an `ObjectIdentifer` (reference to an Observer Instance) against its `ObserverContainer`
     - Author: Simon J. Stuart
     - Version: 1.0
     - Note: This is used as a temporary "Holding Queue" when the `observers` Dictionary has its Lock retained by another Thread.
     */
    @ThreadSafeSemaphore private var observersAddQueue = [ObjectIdentifier : ObserverContainer]()
    /**
     Dictionary mapping an `ObjectIdentifer` (reference to an Observer Instance) against its `ObserverContainer`
     - Author: Simon J. Stuart
     - Version: 1.0
     - Note: This is used as a temporary "Holding Queue" when the `observers` Dictionary has its Lock retained by another Thread.
     */
    @ThreadSafeSemaphore private var observersRemoveQueue = [ObjectIdentifier : ObserverContainer]()
    
    public func addObserver<TObservationProtocol: AnyObject>(_ observer: TObservationProtocol) {
        var collection = _observers.lock.wait(timeout: DispatchTime.now()) == .success ? _observers : _observersAddQueue
        collection.wrappedValue[ObjectIdentifier(observer)] = ObserverContainer(observer: observer, dispatchQueue: OperationQueue.current?.underlyingQueue)
        collection.lock.signal()
    }
    
    public func removeObserver<TObservationProtocol: AnyObject>(_ observer: TObservationProtocol) {
        let lockResult = _observers.lock.wait(timeout: DispatchTime.now())
        if lockResult == .success { // If we can obtain the lock for the Main Observer Collection...
            observers.removeValue(forKey: ObjectIdentifier(observer)) // Simply remove it from the Collection
            _observers.lock.signal() // Release the Lock
        }
        else { // If we CAN'T get the Main Observer Collection's Lock...
            _observersRemoveQueue.lock.wait() // Get the Remove Queue Lock
            observersRemoveQueue[ObjectIdentifier(observer)] = ObserverContainer(observer: observer, dispatchQueue: nil) // the Dispatch Queue doesn't matter here!
            _observersRemoveQueue.lock.signal() // Release the Remove Queue Lock
        }
    }
    
    public func withObservers<TObservationProtocol>(_ code: @escaping (_ observer: TObservationProtocol) -> ()) {
        self._observers.lock.wait()
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
        
        self._observersAddQueue.lock.wait() // Lock the Add Queue
        self._observersRemoveQueue.lock.wait() // Lock the Remove Queue
        for (id, observation) in observersAddQueue { // Add all of the Queued Observers
            observers[id] = observation
        }
        for (id) in observersRemoveQueue.keys { // Remove all of the Queued Observers
            observers.removeValue(forKey: id)
        }
        self._observersAddQueue.lock.signal() // Release the Add Queue Lock
        self._observersRemoveQueue.lock.signal() // Release the Remove Queue Lock
        self._observers.lock.signal()
    }
    
    internal func notifyChange() {
        Task {
            await notifyChange()
        }
    }
    
    internal func notifyChange() async {
        await MainActor.run {
            objectWillChange.send()
        }
    }
}
