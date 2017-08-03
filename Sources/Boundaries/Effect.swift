import Prelude

public enum Effect<A> {
  case _execute(Any, (@escaping (A) -> ()) -> ())
  case batch([Effect<A>])
  case dispatch(A)
  case sequence([Effect<A>])

  public static func execute(
    fingerprint: Any = "\(#file):\(#line):\(#function)",
    _ callback: @escaping ((A) -> ()) -> ())
    -> Effect {

      return ._execute(fingerprint, callback)
  }

  public static var noop: Effect { return .batch([]) }

  public func map<B>(_ f: @escaping (A) -> B) -> Effect<B> {
    switch self {
    case let ._execute(fingerprint, effect):
      return ._execute(fingerprint, { dispatch in effect(dispatch <<< f) })
    case let .batch(effects):
      return .batch(effects.map { $0.map(f) })
    case let .dispatch(action):
      return .dispatch(f(action))
    case let .sequence(effects):
      return .sequence(effects.map { $0.map(f) })
    }
  }

  public static func <¢> <B>(f: @escaping (A) -> B, e: Effect) -> Effect<B> {
    return e.map(f)
  }
}

public func map<A, B>(_ f: @escaping (A) -> B) -> (Effect<A>) -> Effect<B> {
  return { f <¢> $0 }
}

// TODO
//extension Effect: CustomDebugStringConvertible {
//}
