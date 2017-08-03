import Dispatch
import Optics
import Prelude

public final class Store<S, A> {
  let reducer: Reducer<S, A>

  var subscribers: [(S) -> Void] = []
  var currentState: S {
    didSet {
      subscribers.forEach { $0(self.currentState) }
    }
  }

  public init(reducer: Reducer<S, A>, initialState: S) {
    self.reducer = reducer
    self.currentState = initialState
  }

  public func interpret(_ effect: Effect<A>) {
    switch effect {
    case let .batch(effects):
      // TODO: execute actions in order
      effects.forEach { e in
        DispatchQueue.global(qos: .userInitiated).async {
          self.interpret(e)
        }
      }
    case let .dispatch(action):
      self.dispatch(action)
    case let ._execute(_, arg, f):
      f(arg, self.dispatch)
    case let .sequence(effects):
      effects.forEach(self.interpret)
    }
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
  }

  public func subscribe<T>(state keyPath: KeyPath<S, T>, _ subscriber: @escaping (T) -> Void) {
    self.subscribe(subscriber <<< view(getting(keyPath)))
  }
}
