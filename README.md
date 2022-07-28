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
    <a href="https://discord.com/invite/GdZZKFTQ2A">
      <img src="https://img.shields.io/discord/878568176856731688?logo=Discord" />
    </a>
</p>

Collection of carefully-prepared Classes and Protocols designed to imbue your inheriting Object Types with efficient, protocol-driven Observer Pattern Behaviour.
As of version 1.1.0, this includes support for *Keyed Observers* (see usage examples below for details)

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
            .upToNextMajor(from: "1.1.0")
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

### Keyed Observation Pattern
As of version 1.1.0, you can now register and notify *Keyed Observers*.

This functionality is an extension of the standard Observer Pattern, and is implemented in the following classes from which you can extend:
- `KeyedObservableClass<TKey: Hashable>` instead of `ObservableClass`
- `KeyedObservableThread<TKey: Hashable>` instead of `ObservableThread`
- `KeyedObservableThreadSafeClass<TKey: Hashable>` instead of `ObservableThreadSafeClass`

*Remember, Keyed Observation is an **extension** of the basic Observation Pattern, so any Keyed Observable is also inherently able to register and notify non-Keyed Observers*

You would use Keyed Observation whenever your Observers care about a specific context of change. A good example would be for a Model Repository, where an Observer may only care about changes to a specific Model contained in the Repository. In this scenario, you would used Keyed Observation to ensure the Observer is only being notified about changes corresponding to the given Key.

Key Types must always conform to the `Hashable` protocol, just as must any Key Type used for a `Dictionary` collection.

Let's take a look at a basic usage example.

We shall provide a basic usage example to synchronize an Observer's internal Dictionary for specific keys only with the values from the Observable's internal Dictionary.

First, we would begin with an Observation Protocol:
```swift
protocol TestKeyedObservable: AnyObject {
    func onValueChanged(key: String, oldValue: String, newValue: String)
}
```
The above Observation Protocol provides the method `onValueChanged` which takes the `key` (in this case a `String` value) and provides the corresponding `oldValue` and `newValue` values for that `key`.
Our *Observer* will implement `TestKeyedObservable` to provide an implementation for this function.

Now, let's define a simple *Keyed Observable* to house the master Dictionary we will be selectively-synchronizing with one or more *Observers*.
```swift
class TestKeyedObservableClass: KeyedObservableClass<String> {
    private var keyValues: [String:String] = ["A":"Hello", "B":"Foo", "C":"Ping"]
    
    func setValue(key: String, value: String) {
        withKeyedObservers(for: key) { (key, observer: TestKeyedObservable) in
            observer.onValueChanged(key: key, oldValue: self.keyValues[key]!, newValue: value)
        }
        self.keyValues[key] = value
    }
}
```
The above class inherits from `KeyedObservableClass` and specializes the `TKey` generic to be a `String`. In other words, the Keys for this Observable must always be `String` values.
It includes a simple `String:String` dictionary (`String` key with a `String` value)

The `setValue` method will simply notify all observers using `withKeyedObservers` any time a specific `key` the Obsever(s) is(are) observing is updated, passing along the `oldValue` and `newValue` values. It will then update its internal Dictionary (`keyValues`) so that it always contains the latest value.

Note the use of `withKeyedObservers` instead of `withObservers`. You will use this syntax in your own Keyed Observables, changing only the declared Observer Protocol (`TestKeyedObservable` in this example) with the Observer Protocol representing your own observation methods.

Now that we have a Keyed Observable that will notify Observers each time the value of a key changes, let's define an Observer.
```swift
class TestKeyedObserverClass: TestKeyedObservable {
    public var keyValues: [String:String] = ["A":"Hello", "B":"Foo"]
    
    func onValueChanged(key: String, oldValue: String, newValue: String) {
        keyValues[key] = newValue
    }
}
```
So, `TestKeyedObserverClass` is a simple class, implementing our `TestKeyedObservable` Observer Protocol.
For this example, we are going to presume that there are 2 pre-defined Keys with known initial values (there do not have to be... you can have as many keys as you wish)

You will notice that we initialized both the Observable and Observer classes to have identical `keyValues` dictionaries. This is solely for the sake of simplifying this example by ensuring there is always an `oldValue`. You don't need to do this in your own implementations.

So, now that we have the *Observable* and the *Observer* types, let's produce a simple bit of Playground code to tie it together.
```swift
let observable = TestKeyedObservableClass() // Creates our Observable
let observer = TestKeyedObserverClass // Creates a single Observer instance
```
At this point, we need to consider what Key or Keys our `observer` is going to Observe.

For example, we can Observe just one key:
```swift
observable.addKeyedObserver(for: "A", observer)
```
The above means that `observer` would only have its `onValueChanged` method invoked when the value of key *A* is modified in `observable`.

Likewise, if we only care about key *B*, we can do:
```swift
observable.addKeyedObserver(for: "B", observer)
```

If we care about *both* known keys, we can simply register them both:
```swift
observable.addKeyedObserver(for: ["A", "B"], observer)
```

Also, we can do something particularly clever and basically register the Observer for every Key known to its own Dictionary:
```swift
observable.addKeyedObserver(for: Array(observer.keyValues.keys), observer)
```
The above would register `observer` with `observable` for every *key* contained in `observer`'s `keyValues` dictionary.

Ultimately, you can register the `observer` with the `observable` for any keys you want:
```swift
observable.addKeyedObserver(for: "Foo", observer)
```

Let's output the initial values of all of our keys before we invoke any code that would modify their values:
```swift
for (key, value) in observer.keyValues {
    print("Key: '\(key)' has a value of '\(value)'")
}
```
This would output:
> Key: 'A' has a value of 'Hello'
> Key: 'B' has a value of 'Foo'

So, now that we can register the Keyed Observer with the Observer for whatever key or keys we wish, let's trigger the Observer Pattern in the `observer`:
```swift
observable.setValue(key: "A", "World")
```
The above will then update the value if *A* from "Hello" to "World".

If we repeat the following code:
```swift
for (key, value) in observer.keyValues {
    print("Key: '\(key)' has a value of '\(value)'")
}
```
This would output:
> Key: 'A' has a value of 'World'
> Key: 'B' has a value of 'Foo'

Okay, so what if we change the value for key "C"? What will happen?
```swift
observable.setValue(key: "C", "Pong")
```
Now, if we repeat the following code:
```swift
for (key, value) in observer.keyValues {
    print("Key: '\(key)' has a value of '\(value)'")
}
```
This would output:
> Key: 'A' has a value of 'World'
> Key: 'B' has a value of 'Foo'

Note that the `observer` was not notified about the change to the value of key *C*. This is because `observer` is not observing `observable` for changes to key *C*.

This is the value of Keyed Observation Pattern. Put simply: not all Observations are meaningful to all Observers. So, as you have now seen, Keyed Observeration enables our *Observers* to be notified specifically of changes relevant to that *Observer*.

## Overloaded `addObserver`, `removeObserver`, `addKeyedObserver`, and `removeKeyedObserver` methods
As of version 1.1.0, all useful combination overloads for the above-specified methods of `ObservableClass`, `ObservableThread`, `ObservableThreadSafeClass`, `KeyedObservableClass`, `KeyedObservableThread`, and `KeyedObservableThreadSafeClass` have been provided to streamline the adding and removal of *Observers* with/from an *Observable*.

### Adding a single *Observer* to an *Observable*
```swift
observable.addObserver(myObserver)
```

### Adding multiple *Observers* to an *Observable*
```swift
observable.addObserver([myObserver1, myObserver2, myObserver3])
```

### Adding a single *Keyed Observer* to a *Keyed Observable* with a single *Key*
```swift
keyedObservable.addKeyedObserver("MyKey", myKeyedObserver)
```

### Adding a single *Keyed Observer* to a *Keyed Observable* with multiple *Keys*
```swift
keyedObservable.addKeyedObserver(["Key1", "Key2", "Key3"], myKeyedObserver)
```

### Adding multiple *Keyed Observers* to a *Keyed Observable* with a single *Key*
```swift
keyedObservable.addKeyedObserver("MyKey", [myKeyedObserver1, myKeyedObserver2, myKeyedObserver3])
```

### Adding multiple *Keyed Observers* to a *Keyed Observable* with multiple *Keys*
```swift
keyedObservable.addKeyedObserver(["Key1", "Key2", "Key3"], [myKeyedObserver1, myKeyedObserver2, myKeyedObserver3])
```

`removeObserver` and `removeKeyedObserver` also provide the same overloads as shown above.

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

`Observable` is available under the MIT license. See the [LICENSE file](./LICENSE) for more info.

## Join us on Discord

If you require additional support, or would like to discuss `Observable`, Swift, or any other topics related to Flowduino, you can [join us on Discord](https://discord.com/invite/GdZZKFTQ2A).
