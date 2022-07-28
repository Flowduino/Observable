//
// KeyedObservable.swift
// Copyright (c) 2022, Flowduino
// Authored by Simon J. Stuart on 28th July 2022
//
// Subject to terms, restrictions, and liability waiver of the MIT License
//

/**
 Describes any Type (Class or Thread) to which Observers can Subscribe.
 - Author: Simon J. Stuart
 - Version: 1.1.0
 - Important: This Protocol can only be applied to Class and Thread types.
  
 See the Base Implementations `ObservableClass` and `ObservableThread`
 */
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol KeyedObservable: Observable {
    /**
     Keyed Observables must declare a `TKey` type which must conform to `Hashable`
     - Author: Simon J. Stuart
     - Version: 1.1.0
     */
    associatedtype TKey: Hashable
    
    /**
     Registers an Observer against this Observable Type for the given Key
     - Author: Simon J. Stuart
     - Version: 1.1.0
     - Parameters:
        - key: The Key for which this Observer is subscribed
        - observer: A reference to a Class (or Thread) conforming to the desired Observer Protocol, inferred from Generics as `TObservationProtocol`
     
      Call this every time you need to register an Observer with your Observable.
    */
    func addKeyedObserver<TObservationProtocol: AnyObject>(for key: TKey, _ observer: TObservationProtocol)
    
    /**
     Registers the Observers against this Observable Type for the given Key
     - Author: Simon J. Stuart
     - Version: 1.1.0
     - Parameters:
        - key: The Key for which this Observer is subscribed
        - observers: A reference to a Classes (or Threads) conforming to the desired Observer Protocol, inferred from Generics as `TObservationProtocol`
     
      Call this every time you need to register an Observer with your Observable.
    */
    func addKeyedObserver<TObservationProtocol: AnyObject>(for key: TKey, _ observers: [TObservationProtocol])
    
    /**
     Registers an Observer against this Observable Type for the given Keys
     - Author: Simon J. Stuart
     - Version: 1.1.0
     - Parameters:
        - keys: The Keys for which this Observer is subscribed
        - observer: A reference to a Class (or Thread) conforming to the desired Observer Protocol, inferred from Generics as `TObservationProtocol`
     
      Call this every time you need to register an Observer with your Observable.
    */
    func addKeyedObserver<TObservationProtocol: AnyObject>(for keys: [TKey], _ observer: TObservationProtocol)
    
    /**
     Registers the given Observers against this Observable Type for the given Keys
     - Author: Simon J. Stuart
     - Version: 1.1.0
     - Parameters:
        - keys: The Keys for which this Observer is subscribed
        - observers: A reference to a Classes (or Threads) conforming to the desired Observer Protocol, inferred from Generics as `TObservationProtocol`
     
      Call this every time you need to register an Observer with your Observable.
    */
    func addKeyedObserver<TObservationProtocol: AnyObject>(for keys: [TKey], _ observers: [TObservationProtocol])
    
    /**
     Removes an Observer from this Observable Type for the given Key
     - Author: Simon J. Stuart
     - Version: 1.1.0
     - Parameters:
        - key: The Key for which this Observer was subscribed
        - observer: A reference to a Class (or Thread) conforming to the desired Observer Protocol, inferred from Generics as `TObservationProtocol`
     
      Call this if you need to explicitly unregister an Observer from your Observable.
    */
    func removeKeyedObserver<TObservationProtocol: AnyObject>(for key: TKey, _ observer: TObservationProtocol)
    
    /**
     Removes all given Observers from this Observable Type for the given Key
     - Author: Simon J. Stuart
     - Version: 1.1.0
     - Parameters:
        - key: The Key for which this Observer was subscribed
        - observers: A reference to a Classes (or Threads) conforming to the desired Observer Protocol, inferred from Generics as `TObservationProtocol`
     
      Call this if you need to explicitly unregister an Observer from your Observable.
    */
    func removeKeyedObserver<TObservationProtocol: AnyObject>(for key: TKey, _ observers: [TObservationProtocol])
    
    /**
     Removes an Observer from this Observable Type for the given Keys
     - Author: Simon J. Stuart
     - Version: 1.1.0
     - Parameters:
        - keys: The Keys for which this Observer was subscribed
        - observer: A reference to a Class (or Thread) conforming to the desired Observer Protocol, inferred from Generics as `TObservationProtocol`
     
      Call this if you need to explicitly unregister an Observer from your Observable.
    */
    func removeKeyedObserver<TObservationProtocol: AnyObject>(for keys: [TKey], _ observer: TObservationProtocol)
    
    /**
     Removes an Observer from this Observable Type for the given Keys
     - Author: Simon J. Stuart
     - Version: 1.1.0
     - Parameters:
        - keys: The Keys for which this Observer was subscribed
        - observers: A reference to a Classes (or Threads) conforming to the desired Observer Protocol, inferred from Generics as `TObservationProtocol`
     
      Call this if you need to explicitly unregister an Observer from your Observable.
    */
    func removeKeyedObserver<TObservationProtocol: AnyObject>(for keys: [TKey], _ observers: [TObservationProtocol])
    
    /**
     Iterates all of the registered Observers for this Observable and invokes against them your defined Closure Method for the given Key.
      - Author: Simon J. Stuart
      - Version: 1.1.0
      - Parameters:
        - key: The Key to which the Observation relates.
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
    func withKeyedObservers<TObservationProtocol>(for key: TKey, _ code: @escaping (_ key: TKey, _ observer: TObservationProtocol) -> ())
      
    /**
     Iterates all of the registered Observers for this Observable and invokes against them your defined Closure Method for the given Keys.
      - Author: Simon J. Stuart
      - Version: 1.1.0
      - Parameters:
        - keys: The Keys to which the Observation relates.
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
    func withKeyedObservers<TObservationProtocol>(for keys: [TKey], _ code: @escaping (_ key: TKey, _ observer: TObservationProtocol) -> ())
}

/**
 This extension just implements the simple Macros universally for any implementation of the `KeyedObserverable` protocol
 - Author: Simon J. Stuart
 - Version: 1.1.0
 */
extension KeyedObservable {
    /**
     Simply iterates multiple observers, and for each, invokes the `addKeyedObserver` implementation taking just that one observer.
     - Author: Simon J. Stuart
     - Version: 1.1.0
     */
    public func addKeyedObserver<TObservationProtocol: AnyObject>(for key: TKey, _ observers: [TObservationProtocol]) {
        for observer in observers {
            addKeyedObserver(for: key, observer)
        }
    }
    
    /**
     Simply iterates multiple keys, and for each, invokes the `addKeyedObserver` implementation taking just that one key.
     - Author: Simon J. Stuart
     - Version: 1.1.0
     */
    public func addKeyedObserver<TObservationProtocol: AnyObject>(for keys: [TKey], _ observer: TObservationProtocol) {
        for key in keys {
            addKeyedObserver(for: key, observer)
        }
    }
    
    /**
     Simply iterates multiple keys and observers, and for each, invokes the `addKeyedObserver` implementation taking just that one key and observer.
     - Author: Simon J. Stuart
     - Version: 1.1.0
     */
    public func addKeyedObserver<TObservationProtocol: AnyObject>(for keys: [TKey], _ observers: [TObservationProtocol]) {
        for key in keys {
            for observer in observers {
                addKeyedObserver(for: key, observer)
            }
        }
    }
    
    /**
     Simply iterates multiple observers, and for each, invokes the `removeKeyedObserver` implementation taking just that one observer.
     - Author: Simon J. Stuart
     - Version: 1.1.0
     */
    public func removeKeyedObserver<TObservationProtocol: AnyObject>(for key: TKey, _ observers: [TObservationProtocol]) {
        for observer in observers {
            removeKeyedObserver(for: key, observer)
        }
    }
    
    /**
     Simply iterates multiple keys, and for each, invokes the `removeKeyedObserver` implementation taking just that one key.
     - Author: Simon J. Stuart
     - Version: 1.1.0
     */
    public func removeKeyedObserver<TObservationProtocol: AnyObject>(for keys: [TKey], _ observer: TObservationProtocol) {
        for key in keys {
            removeKeyedObserver(for: key, observer)
        }
    }
    
    /**
     Simply iterates multiple keys, and for each, invokes the `removeKeyedObserver` implementation taking just that one key and the one observer.
     - Author: Simon J. Stuart
     - Version: 1.1.0
     */
    public func removeKeyedObserver<TObservationProtocol: AnyObject>(for keys: [TKey], _ observers: [TObservationProtocol]) {
        for key in keys {
            for observer in observers {
                removeKeyedObserver(for: key, observer)
            }
        }
    }
    
    /**
     Simply iterates multiple keys, and for each, invokes the `withKeyedObservers` implementation taking just that one key.
     - Author: Simon J. Stuart
     - Version: 1.1.0
     */
    public func withKeyedObservers<TObservationProtocol>(for keys: [TKey], _ code: @escaping (_ key: TKey, _ observer: TObservationProtocol) -> ()) {
        for key in keys {
            withKeyedObservers(for: key, code)
        }
    }
}
