import XCTest
@testable import Observable

protocol TestObservable: AnyObject {
    func onFoo(oldFoo: String, newFoo: String)
}

final class ObservableClassTests: XCTestCase {
   
    class TestObservableClass: ObservableClass {
        private var foo: String = "Bar"
        func setFoo(foo: String) {
            withObservers { (observer: TestObservable) in
                observer.onFoo(oldFoo: self.foo, newFoo: foo)
            }
            self.foo = foo
        }
    }
    
    class TestObserverClass: TestObservable {
        public var oldFoo: String? = nil
        public var newFoo: String? = nil
        
        func onFoo(oldFoo: String, newFoo: String) {
            self.oldFoo = oldFoo
            self.newFoo = newFoo
        }
    }
    
    func testSimpleObservableClass() throws {
        // Expectations
        let oldFoo = "Bar"
        let newFoo = "World"
        // Create an Observable Instance
        let observable = TestObservableClass()
        // Create an Observer Instance
        let observer = TestObserverClass()
        // Register the Observer with the Observable
        observable.addObserver(observer)
        // Test Initial Values (both should be nil)
        XCTAssertNil(observer.oldFoo, "Initial value of oldFoo should be nil!")
        XCTAssertNil(observer.newFoo, "Initial value of newFoo should be nil!")
        // Invoke the method to update the value of 'foo' in the Observable... which in turn will invoke `onFoo` in the Observer to update *it's* values...
        observable.setFoo(foo: newFoo)
        // Test to ensure that `onFoo` was executed (thus set the values according to our expectations)
        XCTAssertEqual(observer.oldFoo, oldFoo, "Value of oldFoo should be '\(oldFoo)' but is '\(observer.oldFoo ?? "nil")'!")
        XCTAssertEqual(observer.newFoo, newFoo, "Value of newFoo should be '\(newFoo)' but is '\(observer.newFoo ?? "nil")'!")
    }
}
