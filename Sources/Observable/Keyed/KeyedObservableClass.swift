//
// KeyedObservableClass.swift
// Copyright (c) 2022, Flowduino
// Authored by Simon J. Stuart on 28th July 2022
//
// Subject to terms, restrictions, and liability waiver of the MIT License
//

import Foundation

/**
 Absolute Base Class for any Class you want to make Observable with support for Keyed Observers
 - Author: Simon J. Stuart
 - Version: 1.1.0
 - Note: You can register any number of Observers, conforming to any number of Obsever Protocols
 - Note: You can register any number of Keyed Observers, conforming to any number of Observer Protocols, and for any number of Keys
 
 Inherit from this Base Class to make your Classes dynamically Observable.
 */
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
open class KeyedObservableClass<TKey: Hashable>: ObservableClass, KeyedObservable {
    
    /**
     Struct for holding information required for Keyed Observers to Register and be Notified of any Changes to the Repository
     - Author: Simon J. Stuart
     - Version: 1.1.0
     - Note: This is why all of our Protocols must enforce a constraint of `AnyObject`
     */
    struct KeyedObservationContainer {
        /**
         The Key being Observed
         - Author: Simon J. Stuart
         - Version: 1.1.0
         */
        var key: TKey
        /**
         The Observer to be notified of changes
         - Author: Simon J. Stuart
         - Version: 1.1.0
         */
        weak var observer: AnyObject?
        
        init(
            key: TKey,
            observer: AnyObject?
        ) {
            self.key = key
            self.observer = observer
        }
    }
    
    /**
     Dictionary of Keys mapping onto a dictionary of `ObjectIdentifiers` with values of  `KeyedObservationContainer`
     - Author: Simon J. Stuart
     - Version: 1.1.0
     */
    private var keyedObservers = [TKey: [ObjectIdentifier : KeyedObservationContainer]]()
    
    public func addKeyedObserver<TObservationProtocol: AnyObject>(for key: TKey, _ observer: TObservationProtocol) {
        let oid = ObjectIdentifier(observer)
        if keyedObservers[key] == nil { keyedObservers[key] = [ObjectIdentifier : KeyedObservationContainer]()} // Ensure there is ALWAYS a Key-based collection for Observers
        keyedObservers[key]![oid] = KeyedObservationContainer(key: key, observer: observer) // Register this Keyed Observer
    }
    
    public func removeKeyedObserver<TObservationProtocol: AnyObject>(for key: TKey, _ observer: TObservationProtocol) {
        let oid = ObjectIdentifier(observer)
        if keyedObservers[key] == nil { return } // Because it can't physically be registered in this case!
        keyedObservers[key]!.removeValue(forKey: oid)
        // Let's remove the outer collection if there are no Observers left within it!
        if keyedObservers[key]!.count == 0 { keyedObservers.removeValue(forKey: key) }
    }
    
    public func withKeyedObservers<TObservationProtocol>(for key: TKey, _ code: @escaping (_ key: TKey, _ observer: TObservationProtocol) -> ()) {
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
    }
}
