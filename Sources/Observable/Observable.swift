//
// Observable.swift
// Copyright (c) 2022, Flowduino
// Authored by Simon J. Stuart on 8th July 2022
//
// Subject to terms, restrictions, and liability waiver of the MIT License
//

/**
 Describes any Type (Class or Thread) to which Observers can Subscribe.
 - Author: Simon J. Stuart
 - Version: 1.0.0
 - Important: This Protocol can only be applied to Class and Thread types.
  
 See the Base Implementations `ObservableClass` and `ObservableThread`
 */
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol Observable: AnyObject {
    /**
     Registers an Observer against this Observable Type
     - Author: Simon J. Stuart
     - Version: 1.0.0
     - Parameters:
        - observer: A reference to a Class (or Thread) conforming to the desired Observer Protocol, inferred from Generics as `TObservationProtocol`
     
      Call this every time you need to register an Observer with your Observable.
    */
    func addObserver<TObservationProtocol: AnyObject>(_ observer: TObservationProtocol)
    
    /**
     Registers all given Observers against this Observable Type
     - Author: Simon J. Stuart
     - Version: 1.1.0
     - Parameters:
        - observers: A reference to a Classes (or Threads) conforming to the desired Observer Protocol, inferred from Generics as `TObservationProtocol`
     
      Call this every time you need to register an Observer with your Observable.
    */
    func addObserver<TObservationProtocol: AnyObject>(_ observers: [TObservationProtocol])
    
    /**
     Removes an Observer from this Observable Type
     - Author: Simon J. Stuart
     - Version: 1.0.0
     - Parameters:
        - observer: A reference to a Class (or Thread) conforming to the desired Observer Protocol, inferred from Generics as `TObservationProtocol`
     
      Call this if you need to explicitly unregister an Observer from your Observable.
    */
    func removeObserver<TObservationProtocol: AnyObject>(_ observer: TObservationProtocol)
    
    /**
     Removes all given Observers from this Observable Type
     - Author: Simon J. Stuart
     - Version: 1.0.0
     - Parameters:
        - observers: A reference to a Classes (or Threads) conforming to the desired Observer Protocol, inferred from Generics as `TObservationProtocol`
     
      Call this if you need to explicitly unregister an Observer from your Observable.
    */
    func removeObserver<TObservationProtocol: AnyObject>(_ observers: [TObservationProtocol])
    
    /**
     Iterates all of the registered Observers for this Observable and invokes against them your defined Closure Method.
      - Author: Simon J. Stuart
      - Version: 1.0.0
      - Parameters:
        - code: The Closure you wish to invoke for each Observer
      - Important: You must explicitly define the Observation Protocol to which the Observer must conform. This is inferred from Generics as `TObservationProtocol`
      - Example: Here is a usage example with a hypothetical Observation Protocol named `MyObservationProtocol`
        ````
        withObservers { (observer: MyObservationProtocol) in
            observer.myObservationMethod()
        }
        ````
        Where `MyObservationProtocol` would look something like this:
         ````
         protocol MyObservationProtocol: AnyObject {
            func myObservationMethod()
         }
         ````
     */
    func withObservers<TObservationProtocol>(_ code: @escaping (_ observer: TObservationProtocol) -> ())
}

/**
 This extension just implements the simple Macros universally for any implementation of the `Observable` protocol
 - Author: Simon J. Stuart
 - Version: 1.1.0
 */
extension Observable {
    /**
     Simply iterates multiple observers, and for each, invokes the `addObserver` implementation taking just that one observer.
     - Author: Simon J. Stuart
     - Version: 1.1.0
     */
    public func addObserver<TObservationProtocol: AnyObject>(_ observers: [TObservationProtocol]) {
        for observer in observers {
            addObserver(observer)
        }
    }
    
    /**
     Simply iterates multiple observers, and for each, invokes the `removeObserver` implementation taking just that one observer.
     - Author: Simon J. Stuart
     - Version: 1.1.0
     */
    public func removeObserver<TObservationProtocol: AnyObject>(_ observers: [TObservationProtocol]) {
        for observer in observers {
            removeObserver(observer)
        }
    }
}
