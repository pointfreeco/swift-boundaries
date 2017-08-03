import Prelude

public enum Effect<A> {
  case batch([Effect<A>])
  case dispatch(A)
  case sequence([Effect<A>])
  case _execute(String, Any, (Any, @escaping (A) -> ()) -> ())

  public static var noop: Effect { return .batch([]) }

  public static func execute<B>(_ tag: String, _ arg: B, _ f: @escaping (B, (A) -> ()) -> ()) -> Effect {
    return ._execute(tag, arg, { arg, dispatch in f(arg as! B, dispatch) })
  }

  public func map<B>(_ f: @escaping (A) -> B) -> Effect<B> {
    switch self {
    case let .batch(effects):
      return .batch(effects.map { $0.map(f) })
    case let .dispatch(action):
      return .dispatch(f(action))
    case let ._execute(tag, arg, effect):
      return ._execute(tag, arg, { arg, dispatch in effect(arg, dispatch <<< f) })
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
