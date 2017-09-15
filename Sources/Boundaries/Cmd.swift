import Prelude

public protocol EffectProtocol {
  associatedtype A
  func execute() -> A?
}

public enum Cmd<E: EffectProtocol> {
  public typealias A = E.A

  case _execute(Any, E)
  case batch([Cmd<E>])
  case dispatch(A)
  case sequence([Cmd<E>])

  public static func execute(fingerprint: Any, _ effect: E) -> Cmd {
      return ._execute(fingerprint, effect)
  }

  public static var noop: Cmd { return .batch([]) }
}
