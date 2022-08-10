//
// KeyedObservableClassTests.swift
// Copyright (c) 2022, Flowduino
// Authored by Simon J. Stuart on 28th July 2022
//
// Subject to terms, restrictions, and liability waiver of the MIT License
//

import XCTest
@testable import Observable

protocol TestKeyedObservable: AnyObject {
    func onValueChanged(key: String, oldValue: String, newValue: String)
}

final class KeyedObservableClassTests: XCTestCase {

    class TestKeyedObservableClass: KeyedObservableClass {
        private var keyValues: [String:String] = ["A":"Hello", "B":"Foo"]
        
        func setValue(key: String, value: String) {
            withKeyedObservers(key: key) { (key, observer: TestKeyedObservable) in
                observer.onValueChanged(key: key, oldValue: self.keyValues[key]!, newValue: value)
            }
            self.keyValues[key] = value
        }
    }
    
    class TestKeyedObserverClass: TestKeyedObservable {
        public var keyValues: [String:String] = ["A":"Hello", "B":"Foo"]
        
        func onValueChanged(key: String, oldValue: String, newValue: String) {
            keyValues[key] = newValue
        }
    }
    
    func testSimpleObservableClass() throws {
        // Expectations
        let keyA = "A"
        let keyB = "B"
        let oldValueA = "Hello"
        let oldValueB = "Foo"
        let newValueA = "World"
        let newValueB = "Bar"
        
        // Create an Observable Instance
        let observable = TestKeyedObservableClass()
        // Create an Observer Instance
        let observer = TestKeyedObserverClass()
        // Register the Observer with the Observable for both keyA and keyB
        observable.addKeyedObserver(keys: [keyA, keyB], observer)
        
        // Test Initial Values (both should be nil)
        XCTAssertEqual(observer.keyValues[keyA], oldValueA, "Initial value of '\(keyA)' should be '\(oldValueA)'!")
        XCTAssertEqual(observer.keyValues[keyB], oldValueB, "Initial value of '\(keyB)' should be '\(oldValueB)'!")
        // Set the value for keyA to newValueA
        observable.setValue(key: keyA, value: newValueA)
        XCTAssertEqual(observer.keyValues[keyA], newValueA, "Current value of '\(keyA)' should be '\(newValueA)'!")
        XCTAssertEqual(observer.keyValues[keyB], oldValueB, "Current value of '\(keyB)' should be '\(oldValueB)'!")
        // Set the value for keyB to newValueB
        observable.setValue(key: keyB, value: newValueB)
        XCTAssertEqual(observer.keyValues[keyA], newValueA, "Current value of '\(keyA)' should be '\(newValueA)'!")
        XCTAssertEqual(observer.keyValues[keyB], newValueB, "Current value of '\(keyB)' should be '\(newValueB)'!")
    }

}
