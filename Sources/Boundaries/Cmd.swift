import Prelude

/// A protocol that describes an effect to be performed. `Self` is the description of the effect (typically
/// an enum with a case for each type of effect supported), and `A` is the resulting action that should
/// be dispatched back to the store.
public protocol EffectProtocol {
  associatedtype A
}

/// Provides a way of combining effects.
public enum Cmd<E: EffectProtocol> {
  public typealias A = E.A

  /// Dispatches an action back to the store.
  case dispatch(A)

  /// Executes an effect synchronously and dispatches it’s resulting action immediately.
  case execute(E)

  // TODO: add DispatchQueue to `parallel` with a `static func parallel` helper that defaults to the
  //       default global queue.
  /// Executes a sequence of effects asynchronously and dispatches the resulting actions in the order
  /// of the source sequence.
  case parallel([Cmd<E>])

  /// Executes a sequence of effects in
  case sequence([Cmd<E>])

  /// An effect that does nothing.
  public static var noop: Cmd { return .parallel([]) }
}

extension Cmd: Monoid {
  public static var empty: Cmd { return .noop }

  public static func <> (lhs: Cmd, rhs: Cmd) -> Cmd {
    return .sequence([lhs, rhs])
  }
}
