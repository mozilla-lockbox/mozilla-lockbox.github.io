---
layout: page
title: ReactiveX Usage
---

This document summarizes lessons we've learned over the course of relying heavily on RxSwift and RxKotlin in the Lockwise mobile apps, and key differences to note when reading Rx code and translating between the two Swift and Kotlin native applications.

### Outside Documentation

* [ReactiveX Website](http://www.reactivex.io): This website has a wealth of information on the concepts behind Rx, as well as cross-platform function-by-function documentation. The implementations in RxSwift and RxKotlin can differ subtly from the RxJS-based docs, but they are frequently still conceptually useful.
* [RxMarbles](https://rxmarbles.com/): This website has highly useful interactive diagrams for most major Rx operators and combining operations.
* [RxKotlin Repo](https://github.com/ReactiveX/RxKotlin): There is some documentation available in the RxKotlin repository.
* [RxAndroid Repo](https://github.com/ReactiveX/RxAndroid): RxAndroid implements reactive bindings to Android-specific components.
* [RxSwift Repo](https://github.com/ReactiveX/RxSwift): There is some documentation available in the RxSwift repository.
* [RxCocoa Repo](https://github.com/ReactiveX/RxSwift/tree/master/RxCocoa): While contained in the `RxSwift` repository, it can be useful to look at the reactive bindings to UIKit-specific components directly.

### Common Operators

The basic set of operators is covered in more & better detail in the ReactiveX documentation and many map nicely to their respective Swift & Kotlin operators (filter, map, and the like). This space is used to highlight a few less-obvious operators that are used widely (or have been widely removed!) in the Lockwise apps, and some notes on functionality that may not be obvious on first glance.

###### RxKotlin + RxSwift
* `take(1)`: Useful for an atomic read from an observable; however, do not use this in places where you would expect subsequent events to trigger values. This has caused subtle bugs in flows like this:
```
someObservable
    .filter { someQuality }
    .switchMap { anotherObservable }
    .take(1)
    .subscribe { doSomething }
```
It's easy to imagine that subsequent emissions from `someObservable` that match the filter for `someQuality` will continue checking the value of `anotherObservable` and emitting events to the `doSomething` block. However, `take(1)` will terminate the whole sequence after it has read its single event, and no further events will be emitted. The example is a good use case for the `withLatestFrom` operator:
```
someObservable
    .filter { someQuality }
    .withLatestFrom { anotherObservable }
    .subscribe { doSomething }
```
* `combineLatest`: For each event emitted by one of the combined observables, there will be an emission into the following stream. For example, two combined observables, in which one emits `[1, 2, 3]` and the other emits `[1]`, the final set of events will be `[(1, 1), (2, 1), (3, 1)]`. This can result in more emissions than the implementer might expect, and use of `combineLatest` should be examined carefully to make sure that another operator isn't better suited for the job.

###### RxKotlin only
* `CompositeDisposable.clear()` vs. `CompositeDisposable.dispose()`: The initial functionality of these two functions is the same; the difference lies in the follow-up behavior. `.clear()` voids all current disposables in the `CompositeDisposable` and allows for subsequent disposable addition; calling `.dispose()` will both void all current disposables and any future ones added to the `CompositeDisposable`. If you're planning to use the `CompositeDisposable` again, it's best to use `.clear()`.
* `switchMap`: Useful when you would like to switch your observable thread completely to another one.

### Subject & Relay Usage

It may be helpful to read up on the [`Subject` documentation](http://reactivex.io/documentation/subject.html) in addition to the below notes.

* `PublishSubject`: This `Subject` implementation simply passes any events it receives through to subscribers. This can cause bugs in which an event is sent before the subscription occurs, but makes sense for instances in which subscribers only care about events that are received in their respective lifecycles.
* `ReplaySubject`: A `ReplaySubject` behaves like a `PublishSubject` except that an event buffer (typically of size 1) can be specified. Even if events are received before subscription, subscribers will receive all of the events in the buffer immediately on subscribing, as well as any follow-up ones.
* `BehaviorRelay`: The most obvious difference between a `Relay` and a `Subject` is that a `Relay` never terminates or errors. This can make them ideal for UI programming, cases where you don't want errors to propagate to other classes, or streams central to application architecture that should never terminate. However, `BehaviorRelay`s must be initialized with a value and in some situations it's preferable to use a `ReplayRelay` or `ReplaySubject` so that the app can do other work to determine initial state.

### Translating

| iOS         | Android        |
|-----------------|-----------------|
| `.flatMap`      | `.switchMap`     |
| `DisposeBag`    | `CompositeDisposable` |
| (native support)| [`Optional` class](https://github.com/mozilla-lockwise/lockwise-android/blob/master/app/src/main/java/mozilla/lockbox/support/Optional.kt) |
| [`RxDataSources`](https://github.com/RxSwiftCommunity/RxDataSources) | Android Adapters + RecyclerViews|
| [`Driver.drive()`](https://github.com/ReactiveX/RxSwift/blob/master/Documentation/Traits.md#driver) | `observeOn(AndroidSchedulers.mainThread())` |
| `.subscribe(onNext: {})` | `.subscribe(target::function)` |
