import Dispatch
import Foundation
import Optics
import Prelude

public final class Store<S, E: EffectProtocol> {
  public typealias A = E.Action

  let reducer: Reducer<S, A, Effect<E>>
  let interpret: (Effect<E>) -> A?

  var subscribers: [(S) -> Void] = []
  var currentState: S {
    didSet {
      self.subscribers.forEach { $0(self.currentState) }
    }
  }

  public init(reducer: Reducer<S, A, Effect<E>>, initialState: S, interpreter interpret: @escaping (E) -> A?) {
    self.reducer = reducer
    self.currentState = initialState
    self.interpret = wrap(interpreter: interpret)
  }

  public func dispatch(_ action: A) {
    let (newState, effect) = self.reducer.reduce(action, self.currentState)
    self.currentState = newState
    self.interpret(effect)
  }

  public func dispatch<B>(_ action: B, _ prism: Prism<A, B>) {
    self.dispatch(prism.review(action))
  }

  public func subscribe(_ subscriber: @escaping (S) -> Void) {
    self.subscribers.append(subscriber)
    subscriber(self.currentState)
  }

  public func subscribe<T>(state keyPath: KeyPath<S, T>, _ subscriber: @escaping (T) -> Void) {
    self.subscribe(subscriber <<< view(getting(keyPath)))
  }

  // Runs the effects and dispatches the resulting actions.
  private func interpret(_ effect: Cmd<Effect<E>>) {
    switch effect {
    case let .execute(e):
      if let action = self.interpret(e) {
        self.dispatch(action)
      }

    case .parallel:
      DispatchQueue.global().async {
        catOptionals(self.interpretedActions(effect))
          .forEach { action in
            DispatchQueue.main.async {
              self.dispatch(action)
            }
        }
      }

    case let .dispatch(action):
      self.dispatch(action)

    case let .sequence(effects):
      effects.forEach(self.interpret)
    }
  }

  // Runs the effects and collects all of the resulting actions without dispatching them.
  private func interpretedActions(_ effect: Cmd<Effect<E>>) -> [A?] {
    switch effect {
    case let .execute(e):
      return [self.interpret(e)]

    case let .parallel(effects):
      return effects.pmap(self.interpretedActions).flatMap(id)

    case let .dispatch(action):
      return [action]

    case let .sequence(effects):
      return effects.flatMap(self.interpretedActions)
    }
  }
}

extension Array {
  // TODO: move to prelude

  /// Performs a parallel map of a transformation over an array.
  public func pmap<A>(_ f: @escaping (Iterator.Element) -> A) -> [A] {
    return self.pmap(queue: .global(), f)
  }

  public func pmap<A>(queue: DispatchQueue, _ f: @escaping (Iterator.Element) -> A) -> [A] {
    guard !self.isEmpty else { return [] }

    var result = Array<A?>(repeating: A?.none, count: self.count)

    let group = DispatchGroup()

    self.indices.forEach { idx in
      group.enter()
      queue.async {
        result[idx] = f(self[idx])
        group.leave()
      }
    }

    group.wait()

    return result.flatMap(id)
  }
}

