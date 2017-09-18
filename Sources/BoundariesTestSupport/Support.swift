import Boundaries
import NonEmpty
import SnapshotTesting

public final class TestStore<S, E: Effect> {
  public typealias A = E.Action

  public let reducer: Reducer<S, A, E>
  public var subscribers: [(S) -> Void] = []
  public let execute: (E) -> A?

  public private(set) var history: NonEmptyArray<(message: String, action: Any, state: S, effect: Cmd<E>)>

  public var currentState: S {
    didSet {
      self.subscribers.forEach { $0(self.currentState) }
    }
  }

  public init(reducer: Reducer<S, A, E>, initialState: S, execute: @escaping (E) -> A?) {
    self.reducer = reducer
    self.history = ("TestStore.init", "init", initialState, .parallel([])) >| []
    self.currentState = initialState
    self.execute = execute
  }

  public func subscribe(_ subscriber: @escaping (S) -> Void) {
    self.subscribers.append(subscriber)
    subscriber(self.currentState)
  }

  public func dispatch(_ action: A, _ message: String = "") {
    let (state, effect) = self.reducer.reduce(action, self.history.last.state)
    self.currentState = state
    self.history.append((message, action, state, effect))
    self.interpret(effect)
  }

  public func dispatch<B>(_ action: B, _ prism: Prism<A, B>, message: String = "") {
    self.dispatch(prism.review(action), message)
  }

  private func interpret(_ effect: Cmd<E>) {
    switch effect {
    case let .execute(e):
      if let action = self.execute(e) {
        self.dispatch(action)
      }

    case let .parallel(effects):
      effects.forEach(self.interpret)

    case let .dispatch(action):
      self.dispatch(action)

    case let .sequence(effects):
      effects.forEach(self.interpret)
    }
  }
}

extension TestStore: Snapshot {
  public typealias Format = String

  public var snapshotFormat: String {
    var format = ""
    dump([self.history.head] + self.history.tail, to: &format)
    return format
  }
}
