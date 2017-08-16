import Boundaries
import NonEmpty
import SnapshotTesting

public final class TestStore<S, A> {
  public let reducer: Reducer<S, A>
  public private(set) var history: NonEmptyArray<(message: String, action: A?, state: S, effect: Effect<A>)>

  public init(reducer: Reducer<S, A>, initialState: S) {
    self.reducer = reducer
    self.history = ("TestStore.init", nil, initialState, .batch([])) >| []
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
    dump(Array(self.history), to: &format)
    return format
  }
}
