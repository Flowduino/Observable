//
// KeyedObservableThread.swift
// Copyright (c) 2022, Flowduino
// Authored by Simon J. Stuart on 28th July 2022
//
// Subject to terms, restrictions, and liability waiver of the MIT License
//

import Foundation
import ThreadSafeSwift

/**
 Provides custom Observer subscription and notification behaviour for Classes that will be interacting with Multiple Threads (with support for Keyed Observers)
 - Author: Simon J. Stuart
 - Version: 2.0.0
 - Note: The Observers are behind a Semaphore Lock
 - Note: A "Revolving Door" solution has been implemented to ensure that Observer Callbacks can modify the Observers (add/remove) without causing a Deadlock.
 */
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
open class KeyedObservableThreadSafeClass: ObservableThreadSafeClass, KeyedObservable {
    /**
     Struct for holding information required for Keyed Observers to Register and be Notified of any Changes to the Repository
     - Author: Simon J. Stuart
     - Version: 2.0.0
     - Note: This is why all of our Protocols must enforce a constraint of `AnyObject`
     */
    struct KeyedObservationContainer {
        /**
         The Key being Observed
         - Author: Simon J. Stuart
         - Version: 2.0.0
         */
        var key: AnyHashable
        /**
         The Observer to be notified of changes
         - Author: Simon J. Stuart
         - Version: 2.0.0
         */
        weak var observer: AnyObject?
        /**
         The `DispatchQueue` from which the Observer registered
         - Author: Simon J. Stuart
         - Version: 1.0
         - Note: This is used to ensure that the Observer's Callbacks are invoked on the Observer's own `DispatchQueue`
         */
        var dispatchQueue: DispatchQueue?
        
        init(
            key: AnyHashable,
            observer: AnyObject?,
            dispatchQueue: DispatchQueue?
        ) {
            self.key = key
            self.observer = observer
            self.dispatchQueue = dispatchQueue
        }
    }
    
    /**
     Dictionary of Keys mapping onto a dictionary of `ObjectIdentifiers` with values of  `KeyedObservationContainer`
     - Author: Simon J. Stuart
     - Version: 2.0.0
     */
    @ThreadSafeSemaphore private var keyedObservers = [AnyHashable: [ObjectIdentifier : KeyedObservationContainer]]()
    
    /**
     A Queue for newly-added Observers that are requesting registration while the `keyedObservers` Semaphore Lock is engaged by another Thread.
     - Author: Simon J. Stuart
     - Version: 2.0.0
     */
    @ThreadSafeSemaphore private var keyedObserversAddQueue = [AnyHashable: [ObjectIdentifier : KeyedObservationContainer]]()
    
    /**
     A Queue for Observers that are requesting removal while the `keyedObservers` Semaphore Lock is engaged by another Thread.
     - Author: Simon J. Stuart
     - Version: 2.0.0
     */
    @ThreadSafeSemaphore private var keyedObserversRemoveQueue = [AnyHashable: [ObjectIdentifier : KeyedObservationContainer]]()
    
    public func addKeyedObserver<TObservationProtocol: AnyObject, TKey: Hashable>(key: TKey, _ observer: TObservationProtocol) {
        let oid = ObjectIdentifier(observer)
        self._keyedObservers.withTryLock { keyedObservers in
            // We were able to acquire the Lock, so Add the Observer directly...
            if keyedObservers[key] == nil { keyedObservers[key] = [ObjectIdentifier : KeyedObservationContainer]()} // Ensure there is ALWAYS a Key-based collection for Observers
            keyedObservers[key]![oid] = KeyedObservationContainer(key: key, observer: observer, dispatchQueue: OperationQueue.current?.underlyingQueue)
        } _: {
            self._keyedObserversAddQueue.withLock { keyedObserversAddQueue in
                // The Lock was not available to this Thread, so Add the Observer to the Add Queue
                if keyedObserversAddQueue[key] == nil { keyedObserversAddQueue[key] = [ObjectIdentifier : KeyedObservationContainer]() } // Ensure there is ALWAYS a Key-based collection for Observers
                keyedObserversAddQueue[key]![oid] = KeyedObservationContainer(key: key, observer: observer, dispatchQueue: OperationQueue.current?.underlyingQueue)
            }
        }
    }
    
    public func removeKeyedObserver<TObservationProtocol: AnyObject, TKey: Hashable>(key: TKey, _ observer: TObservationProtocol) {
        let oid = ObjectIdentifier(observer)
        self._keyedObservers.withTryLock { keyedObservers in
            // Remove the Observer directly...
            if keyedObservers[key] == nil { return } // Because it can't physically be registered in this case!
            keyedObservers[key]!.removeValue(forKey: oid)
            if keyedObservers[key]!.count == 0 {  keyedObservers.removeValue(forKey: key) } // Let's remove the outer collection if there are no Observers left within it!
        } _: {
            self._keyedObserversRemoveQueue.withLock { keyedObserversRemoveQueue in
                if keyedObserversRemoveQueue[key] == nil { keyedObserversRemoveQueue[key] = [ObjectIdentifier : KeyedObservationContainer]() } // Ensure there is ALWAYS a Key-based collection for Observers
                keyedObserversRemoveQueue[key]![oid] = KeyedObservationContainer(key: key, observer: observer, dispatchQueue: OperationQueue.current?.underlyingQueue)
            }
        }
    }
    
    public func withKeyedObservers<TObservationProtocol, TKey: Hashable>(key: TKey, _ code: @escaping (_ key: TKey, _ observer: TObservationProtocol) -> ()) {
        self._keyedObservers.withLock { keyedObservers in
            var observers = keyedObservers[key]
            if observers == nil { return }
            
            for (id, observation) in observers! {
                guard let observer = observation.observer else { // Check if the Observer still exists
                    observers!.removeValue(forKey: id) // If it doesn't, remove the Observer from the collection...
                    if keyedObservers[key]!.count == 0 { keyedObservers.removeValue(forKey: key) } // Let's remove the outer collection if there are no Observers left within it!
                    continue // ...then continue to the next one
                }
                if let typedObserver = observer as? TObservationProtocol { // If the Observer conforms to the expected Observation Protocol...
                    code(key, typedObserver) // ...Invoke the Closure against the now-Typed Observer.
                }
            }
            
            // Now we need to reconcile the Add and Remove queues with the Keyed Observers collection...
            var addQueue = [AnyHashable: [ObjectIdentifier : KeyedObservationContainer]]()
            var removeQueue = [AnyHashable: [ObjectIdentifier : KeyedObservationContainer]]()
            
            self._keyedObserversAddQueue.withLock { keyedObserversAddQueue in
                addQueue = keyedObserversAddQueue // Take a local copy
                keyedObserversAddQueue.removeAll() // Empty the public Queue
            }
            
            self._keyedObserversRemoveQueue.withLock { keyedObserversRemoveQueue in
                removeQueue = keyedObserversRemoveQueue // Take a local copy
                keyedObserversRemoveQueue.removeAll() // Empty hte public queue
            }
            
            // Now that we have all of the pending, let's process them...
            for (id, observers) in addQueue {
                for keyedObserver in observers.values {
                    if keyedObserver.observer == nil { continue } // Skip if it is nil
                    let oid = ObjectIdentifier(keyedObserver.observer!)
                    if keyedObservers[id] == nil { keyedObservers[id] = [ObjectIdentifier : KeyedObservationContainer]()} // Ensure there is ALWAYS a Key-based collection for Observers
                    keyedObservers[id]![oid] = keyedObserver
                }
            }
            
            // Now we have to remove any pending...
            for (id, observers) in removeQueue {
                for keyedObserver in observers.values {
                    if keyedObservers[id] == nil { continue } // Nothing to do if the ID container doesn't exist
                    if keyedObserver.observer == nil { continue } // Nothing to do if there's no Observer to remove
                    let oid = ObjectIdentifier(keyedObserver.observer!)
                    keyedObservers[id]!.removeValue(forKey: oid)
                    if keyedObservers[id]!.count == 0 { keyedObservers.removeValue(forKey: id) } // Let's remove the outer Key-based collection if there are no Observers left within it!
                }
            }
        }
    }
}
