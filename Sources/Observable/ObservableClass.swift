//
// ObservableClass.swift
// Copyright (c) 2022, Flowduino
// Authored by Simon J. Stuart on 8th July 2022
//
// Subject to terms, restrictions, and liability waiver of the MIT License
//

import Foundation

/**
 Absolute Base Class for any Class you want to make Observable
 - Author: Simon J. Stuart
 - Version: 1.0
 - Note: You can register any number of Observers, conforming to any number of Obsever Protocols
 
 Inherit from this Base Class to make your Classes dynamically Observable.
 */
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
open class ObservableClass: Observable, ObservableObject {
    /**
     Contains a Weak Reference to an Observer.
     - Author: Simon J. Stuart
     - Version: 1.0
     - Note: This is why all of our Protocols must enforce a constraint of `AnyObject`
     */
    struct ObserverContainer{
        /**
         Reference to the Observer Object
         - Author: Simon J. Stuart
         - Version: 1.0
         - Note: This Reference **must** be `weak` to prevent Reference Counting from retaining unwanted Objects.
         */
        weak var observer: AnyObject?
    }
    
    /**
     Dictionary mapping an `ObjectIdentifer` (reference to an Observer Instance) against its `ObserverContainer`
     - Author: Simon J. Stuart
     - Version: 1.0
     */
    private var observers = [ObjectIdentifier : ObserverContainer]()

    public func addObserver<TObservationProtocol: AnyObject>(_ observer: TObservationProtocol) {
        observers[ObjectIdentifier(observer)] = ObserverContainer(observer: observer)
    }

    public func removeObserver<TObservationProtocol: AnyObject>(_ observer: TObservationProtocol) {
        observers.removeValue(forKey: ObjectIdentifier(observer))
    }
    
    open func withObservers<TObservationProtocol>(_ code: @escaping (_ observer: TObservationProtocol) -> ()) {
        for (id, observation) in observers {
            guard let observer = observation.observer else { // Check if the Observer still exists
                observers.removeValue(forKey: id) // If it doesn't, remove the Observer from the collection...
                continue // ...then continue to the next one
            }
            if let typedObserver = observer as? TObservationProtocol {
                code(typedObserver)
            }
        }
    }
}
