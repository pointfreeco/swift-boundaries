import Prelude

public protocol EffectProtocol {
  associatedtype A
  func execute() -> A?
}

public enum Cmd<E: EffectProtocol> {
  public typealias A = E.A

  case execute(E)
  case batch([Cmd<E>])
  case dispatch(A)
  case sequence([Cmd<E>])

  public static var noop: Cmd { return .batch([]) }
}
