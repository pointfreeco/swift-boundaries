import Boundaries
import NonEmpty
import SnapshotTesting

public final class TestStore<S, E: EffectProtocol> {
  public typealias A = E.A

  public let reducer: Reducer<S, A, E>
  public private(set) var history: NonEmptyArray<(message: String, action: Any, state: S, effect: Cmd<E>)>

  public init(reducer: Reducer<S, A, E>, initialState: S) {
    self.reducer = reducer
    self.history = ("TestStore.init", "init", initialState, .batch([])) >| []
  }

  public func dispatch(_ action: A, _ message: String = "") {
    let (state, effect) = self.reducer.reduce(action, self.history.last.state)
    self.history.append((message, action, state, effect))
  }

  public func dispatch<B>(_ action: B, _ prism: Prism<A, B>, message: String = "") {
    self.dispatch(prism.review(action), message)
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
