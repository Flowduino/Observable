# Observable

<p>
    <img src="https://img.shields.io/badge/Swift-5.1%2B-yellowgreen.svg?style=flat" />
    <img src="https://img.shields.io/badge/iOS-13.0+-865EFC.svg" />
    <img src="https://img.shields.io/badge/iPadOS-13.0+-F65EFC.svg" />
    <img src="https://img.shields.io/badge/macOS-10.15+-179AC8.svg" />
    <img src="https://img.shields.io/badge/tvOS-13.0+-41465B.svg" />
    <img src="https://img.shields.io/badge/watchOS-6.0+-1FD67A.svg" />
    <img src="https://img.shields.io/badge/License-MIT-blue.svg" />
    <a href="https://github.com/apple/swift-package-manager">
      <img src="https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat" />
    </a>
</p>

Collection of carefully-prepared Classes and Protocols designed to imbue your inheriting Object Types with efficient, protocol-driven Observer Pattern Behaviour.

## Installation
### Xcode Projects
Select `File` -> `Swift Packages` -> `Add Package Dependency` and enter `https://github.com/Flowduino/Observable.git`

### Swift Package Manager Projects
You can use `Observable` as a Package Dependency in your own Packages' `Package.swift` file:
```swift
let package = Package(
    //...
    dependencies: [
        .package(
            url: "https://github.com/Flowduino/Observable.git",
            .upToNextMajor(from: "1.0.4")
        ),
    ],
    //...
)
```

From there, refer to `Observable` as a "target dependency" in any of _your_ package's targets that need it.

```swift
targets: [
    .target(
        name: "YourLibrary",
        dependencies: [
          "Observable",
        ],
        //...
    ),
    //...
]
```
You can then do `import Observable` in any code that requires it.

## Usage

Here are some quick and easy usage examples for the features provided by `Observable`:

### ObservableClass
You can inherit from `ObservableClass` in your *own* Class Types to provide out-of-the-box Observer Pattern support.
This not only works for `@ObservedObject` decorated Variables in a SwiftUI `View`, but also between your Classes (e.g. between Services, or Repositories etc.)

First, you would define a Protocol describing the Methods implemented in your *Observer* Class Type that your *Observable* Class can invoke:
```swift
/// Protocol defining what Methods the Obverable Class can invoke on any Observer
protocol DummyObserver: AnyObject { // It's extremely important that this Protocol be constrained to AnyObject
    func onFooChanged(oldValue: String, newValue: String)
    func onBarChanged(oldValue: String, newValue: String)
}
```
**Note** - It is important that our Protocol define the `AnyObject` conformity-constraint as shown above.

Now, we can define our *Observable*, inheriting from `ObservableClass`:
```swift
/// Class that can be Observed 
class Dummy: ObservableClass {
    private var _foo: String = "Hello"
    public var foo: String {
        get {
            return _foo
        }
        set {
            // Invoke onFooChanged for all current Observers
            withObservers { (observer: DummyObserver) in
                observer.onFooChanged(oldValue: _foo, newValue: newValue)
            }
            _foo = newValue
            objectWillChange.send() // This is for the standard ObservableObject behaviour (both are supported together)
        }
    }

    private var _bar: String = "World"
    public var bar: String {
        get {
            return _bar
        }
        set {
            // Invoke onBarChanged for all current Observers
            withObservers { (observer: DummyObserver) in
                observer.onBarChanged(oldValue: _bar, newValue: newValue)
            }
            _bar = newValue
            objectWillChange.send() // This is for the standard ObservableObject behaviour (both are supported together)
        }
    }
}
```

We can now define an *Observer* to register with the *Observable*, ensuring that we specify that it implements our `DummyObserver` protocol: 
```swift
class DummyObserver: DummyObserver {
    /* Implementations for DummyObserver */
    func onFooChanged(oldValue: String, newValue: String) {
        print("Foo Changed from \(oldValue) to \(newValue)")
    }

    func onBarChanged(oldValue: String, newValue: String) {
        print("Bar Changed from \(oldValue) to \(newValue)")
    }
}
```

We can now produce some simple code (such as in a Playground) to put it all together:
```swift
// Playground Code to use the above
var observable = Dummy() // This is the Object that we can Observe
var observer = DummyObserver() // This is an Object that will Observe the Observable

observable.addObserver(observer) // This is what registers the Observer with the Observable!
observable.foo = "Test 1"
observable.bar = "Test 2"
```

### ObservableThreadSafeClass
`ObservableThreadSafeClass` works exactly the same way as `ObservableClass`. The internal implementation simply encapsulates the `Observer` collections behind a `DispatchSemaphore`, and provides a *Revolving Door* mechanism to ensure unobstructed access is available to `addObserver` and `removeObserver`, even when `withObservers` is in execution.

Its usage is exactly as shown above in `ObservableClass`, only you would substitute the inheritence of `ObservableClass` to instead inherit from `ObservableThreadSafeClass`.

### ObservableThread
`ObservableThread` provides you with a Base Type for any Thread Types you would want to Observe.

**Note** - `ObservableThread` does implement the `ObservableObject` protocol, and is *technically* compatible with the `@ObservedObject` property decorator in a SwiftUI `View`. However, to use it in this way, anywhere you would invoke `objectWillUpdate.send()` you must instead use `notifyChange()`. Internally, `ObservableThread` will execute `objectWillChange.send()` **but** enforce that it must execute on the `MainActor` (as required by Swift)

Let's now begin taking a look at how we can use `ObservableThread` in your code.
The example is intentionally simplistic, and simply generates a random number every 60 seconds within an endless loop in the Thread.

Let's begin by defining our Observation Protocol:
```swift
protocol RandomNumberObserver: AnyObject {
    func onRandomNumber(_ randomNumber: Int)
}
```
Any Observer for our Thread will need to conform to the RandomNumberObserver protocol above.

Now, let's define our RandomNumberObservableThread class:
```swift
class RandomNumberObservableThread: ObservableThread {
    init() {
        self.start() // This will start the thread on creation. You aren't required to do it this way, I'm just choosing to!
    }

    public override func main() { // We must override this method
        while self.isExecuting { // This creates a loop that will continue for as long as the Thread is running!
            let randomNumber = Int.random(in: -9000..<9001) // We'll generate a random number between -9000 and +9000
            // Now let's notify all of our Observers!
            withObservers { (observer: RandomNumberObserver) in
                observer.onRandomNumber(randomNumber)
            }
            Self.sleep(forTimeInterval: 60.00) // This will cause our Thread to sleep for 60 seconds
        }
    }
}
```

So, we now have a Thread that can be Observed, and will notify all Observers every minute when it generates a random Integer.

Let's now implement a Class intended to Observe this Thread:
```swift
class RandomNumberObserverClass: RandomNumberObserver {
    public func onRandomNumber(_ randomNumber: Int) {
        print("Random Number is: \(randomNumber)")
}
```
We can now tie this all together in a simple Playground:
```swift
var myThread = RandomNumberObservableThread()
var myObserver = RandomNumberObserverClass()
myThread.addObserver(myObserver)
```

That's it! The Playground program will now simply print out the new Random Number notice message into the console output every 60 seconds.

You can adopt this approach for any Observation-Based Thread Behaviour you require, because `ObservableThread` will always invoke the Observer callback methods in the execution context their own threads! This means that, for example, you can safely instantiate an Observer class on the UI Thread, while the code execution being observed resides in its own threads (one or many, per your requirements).

## Additional Useful Hints
There are a few additional useful things you should know about this Package.
### A single *Observable* can invoke `withObservers` for any number of *Observer Protocols*
This library intentionally performs run-time type checks against each registered *Observer* to ensure that it conforms to the explicitly-defined *Observer Protocol* being requested by your `withObservers` Closure method.

Simple example protocols:
```swift
protocol ObserverProtocolA: AnyObject {
    func doSomethingForProtocolA()
}

protocol ObserverProtocolB: AnyObject {
    func doSomethingForProtocolB()
}
```

Which can then both be used by the same `ObservableClass`, `ObservableThreadSafeClass`, or `ObservableThread` descendant:

```swift
withObservers { (observer: ObserverProtocolA) in
    observer.doSomethingForProtocolA()
}

withObservers { (observer: ObserverProtocolB) in
    observer.doSomethingForProtocolB()
}
```

Any number of *Observer Protocols* can be marshalled by any of our *Observable* types, and only *Observers* conforming to the explicitly-specified *Observer Protocol* will be passed into your `withObservers` Closure method.

## License

`ThreadSafeSwift` is available under the MIT license. See the [LICENSE file](./LICENSE) for more info.
