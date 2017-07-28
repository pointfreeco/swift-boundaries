import Boundaries
import NonEmpty

public final class TestStore<S, A> {
  public let reducer: Reducer<S, A>
  public private(set) var history: NonEmptyArray<(state: S, effect: Effect<A>)>

  public init(reducer: Reducer<S, A>, initialState: S) {
    self.reducer = reducer
    self.history = (initialState, .batch([])) >| []
  }

  public func dispatch(_ action: A) {
    self.history.append(self.reducer.reduce(action, self.history.last.state))
  }

  public func dispatch<B>(_ action: B, _ prism: Prism<A, B>) {
    self.dispatch(prism.review(action))
  }
}
