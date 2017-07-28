import Prelude

public enum Effect<A> {
  case batch([Effect<A>])
  case dispatch(A)
  case sequence([Effect<A>])
  case _execute(tag: String, f: (Any) -> A?, arg: Any)

  static var noop: Effect { return .batch([]) }

  public static func execute<B>(tag: String, f: @escaping (B) -> A?, arg: B) -> Effect {
    return ._execute(tag: tag, f: { any in f(any as! B) }, arg: arg)
  }

  public func map<B>(_ f: @escaping (A) -> B) -> Effect<B> {
    switch self {
    case let .batch(effects):
      return .batch(effects.map { $0.map(f) })
    case let .dispatch(action):
      return .dispatch(f(action))
    case let ._execute(tag: tag, f: effect, arg: arg):
      return ._execute(tag: tag, f: { arg in effect(arg).map(f) }, arg: arg)
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
