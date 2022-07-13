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
 - Version: 1.0.4
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
     - Version: 1.0.4
     */
    private var observers = [ObjectIdentifier : ObserverContainer]()
    private var observerLock = DispatchSemaphore(value: 1)
    
    /**
     Dictionary mapping an `ObjectIdentifer` (reference to an Observer Instance) against its `ObserverContainer`
     - Author: Simon J. Stuart
     - Version: 1.0.4
     - Note: This is used as a temporary "Holding Queue" when the `observers` Dictionary has its Lock retained by another Thread.
     */
    private var observersAddQueue = [ObjectIdentifier : ObserverContainer]()
    private var observerAddLock = DispatchSemaphore(value: 1)
    
    /**
     Dictionary mapping an `ObjectIdentifer` (reference to an Observer Instance) against its `ObserverContainer`
     - Author: Simon J. Stuart
     - Version: 1.0.4
     - Note: This is used as a temporary "Holding Queue" when the `observers` Dictionary has its Lock retained by another Thread.
     */
    private var observersRemoveQueue = [ObjectIdentifier : ObserverContainer]()
    private var observerRemoveLock = DispatchSemaphore(value: 1)
    
    public func addObserver<TObservationProtocol: AnyObject>(_ observer: TObservationProtocol) {
        let observation = ObserverContainer(observer: observer, dispatchQueue: OperationQueue.current?.underlyingQueue)
        
        if observerLock.wait(timeout: DispatchTime.now().advanced(by: DispatchTimeInterval.milliseconds(10))) == .success {
            observers[ObjectIdentifier(observer)] = observation
            observerLock.signal()
        }
        else {
            observerAddLock.wait()
            observersAddQueue[ObjectIdentifier(observer)] = observation
            observerAddLock.signal()
        }
    }
    
    public func removeObserver<TObservationProtocol: AnyObject>(_ observer: TObservationProtocol) {
        let lockResult = observerLock.wait(timeout: DispatchTime.now().advanced(by: DispatchTimeInterval.milliseconds(10)))
        
        if lockResult == .success { // If we can obtain the lock for the Main Observer Collection...
            observers.removeValue(forKey: ObjectIdentifier(observer)) // Simply remove it from the Collection
            observerLock.signal() // Release the Lock
        }
        else { // If we CAN'T get the Main Observer Collection's Lock...
            observerRemoveLock.wait() // Get the Remove Queue Lock
            observersRemoveQueue[ObjectIdentifier(observer)] = ObserverContainer(observer: observer, dispatchQueue: nil) // the Dispatch Queue doesn't matter here!
            observerRemoveLock.signal() // Release the Remove Queue Lock
        }
    }
    
    public func withObservers<TObservationProtocol>(_ code: @escaping (_ observer: TObservationProtocol) -> ()) {
        self.observerLock.wait()
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
        
        self.observerAddLock.wait() // Lock the Add Queue
        let observersToAdd = self.observersAddQueue
        observersAddQueue.removeAll()
        self.observerAddLock.signal() // Release the Add Queue Lock
               
        self.observerRemoveLock.wait() // Lock the Remove Queue
        let observersToRemove = self.observersRemoveQueue
        observersRemoveQueue.removeAll()
        self.observerRemoveLock.signal() // Release the Remove Queue Lock
        
        // Add all of the Queued Observers
        for (id, observation) in observersToAdd {
            observers[id] = observation
        }
        // Remove all of the Queued Observers
        for (id) in observersToRemove.keys {
            observers.removeValue(forKey: id)
        }
        self.observerLock.signal()
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
