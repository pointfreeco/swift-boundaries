import Optics
import Prelude

public struct Prism<A, B> {
  public let preview: (A) -> B?
  public let review: (B) -> A

  public init(preview: @escaping (A) -> B?, review: @escaping (B) -> A) {
    self.preview = preview
    self.review = review
  }
}

public struct Reducer<S, A> {
  public let reduce: (A, S) -> (S, Effect<A>)

  public init(_ reduce: @escaping (A, S) -> (S, Effect<A>)) {
    self.reduce = reduce
  }

  public func lift<B>(action prism: Prism<B, A>) -> Reducer<S, B> {
    return .init { actionB, state in
      prism
        .preview(actionB)
        .map { self.reduce($0, state) |> second(map(prism.review)) }
        ?? (state, .noop)
    }
  }

  public func lift<T>(state lens: Lens<T, S>) -> Reducer<T, A> {
    return Reducer<T, A> { action, stateT in
      let stateS = lens.get(stateT)
      let (newStateS, effect) = self.reduce(action, stateS)
      return (lens.set(stateT, newStateS), effect)
    }
  }

  public func lift<T, B>(action prism: Prism<B, A>, state lens: Lens<T, S>) -> Reducer<T, B> {
    return self.lift(action: prism).lift(state: lens)
  }
}

extension Reducer: Monoid {
  public static var empty: Reducer<S, A> {
    return .init { _, state in (state, .noop) }
  }

  public static func <>(lhs: Reducer, rhs: Reducer) -> Reducer {
    return .init { action, state in
      let (state1, effect1) = lhs.reduce(action, state)
      let (state2, effect2) = rhs.reduce(action, state1)
      return (state2, .sequence([effect1, effect2]))
    }
  }
}
