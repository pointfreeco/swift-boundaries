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

public struct Reducer<S, A, E: EffectProtocol> {
  public let reduce: (A, S) -> (S, Cmd<E>)

  public init(_ reduce: @escaping (A, S) -> (S, Cmd<E>)) {
    self.reduce = reduce
  }

  public func lift<B>(action prism: Prism<B, A>) -> Reducer<S, B, E> {
    return .init { actionB, state in
      prism
        .preview(actionB)
        .map { actionA in self.reduce(actionA, state) }
        ?? (state, .noop)
    }
  }

  public func lift<T>(state keyPath: WritableKeyPath<T, S>) -> Reducer<T, A, E> {
    return .init { action, stateT in
      let (newStateS, effect) = self.reduce(action, stateT .^ keyPath)
      return (stateT |> keyPath .~ newStateS, effect)
    }
  }

  public func lift<T, B>(action prism: Prism<B, A>, state keyPath: WritableKeyPath<T, S>) -> Reducer<T, B, E> {
    return self.lift(action: prism).lift(state: keyPath)
  }
}

extension Reducer: Monoid {
  public static var empty: Reducer<S, A, E> {
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
