import Dispatch
import Foundation
import Optics
import Prelude

public final class Store<S, E: EffectProtocol> {
  public typealias A = E.A

  let reducer: Reducer<S, A, E>

  var subscribers: [(S) -> Void] = []
  var currentState: S {
    didSet {
      subscribers.forEach { $0(self.currentState) }
    }
  }

  public init(reducer: Reducer<S, A, E>, initialState: S) {
    self.reducer = reducer
    self.currentState = initialState
  }

  public func dispatch(_ action: A) {
    let (newState, effect) = self.reducer.reduce(action, self.currentState)
    self.currentState = newState
    self.interpret(effect)
  }

  public func dispatch<B>(_ action: B, _ prism: Prism<A, B>) {
    self.dispatch(prism.review(action))
  }

  public func subscribe(_ subscriber: @escaping (S) -> Void) {
    self.subscribers.append(subscriber)
  }

  public func subscribe<T>(state keyPath: KeyPath<S, T>, _ subscriber: @escaping (T) -> Void) {
    self.subscribe(subscriber <<< view(getting(keyPath)))
  }

  // Executes the effect
  private func interpret(_ effect: Cmd<E>) {
    switch effect {
    case let .execute(e):
      if let action = e.execute() {
        self.dispatch(action)
      }

    case .parallel:
      catOptionals(self.interpretedActions(effect))
        .forEach(self.dispatch)

    case let .dispatch(action):
      self.dispatch(action)

    case let .sequence(effects):
      effects.forEach(self.interpret)
    }
  }

  // Runs the effects and collects all of the resulting actions without dispatching them.
  private func interpretedActions(_ effect: Cmd<E>) -> [A?] {
    switch effect {
    case let .execute(e):
      return [e.execute()]

    case let .parallel(effects):
      return effects.pmap(self.interpretedActions).flatMap(id)

    case let .dispatch(action):
      return [action]

    case let .sequence(effects):
      return effects.flatMap(self.interpretedActions)
    }
  }
}

extension Array {
  // TODO: move to prelude

  /// Performs a parallel map of a transformation over an array. Splits the array into chunks based on the
  /// number of computing cores.
  public func pmap<T>(_ f: @escaping (Iterator.Element) -> T) -> [T] {
    return self.pmap(queue: .global(), f)
  }

  public func pmap<T>(queue: DispatchQueue, _ f: @escaping (Iterator.Element) -> T) -> [T] {
    guard !self.isEmpty else { return [] }

    var result: [Int: [T]] = .init(minimumCapacity: self.count)

    let coreCount = ProcessInfo.processInfo.activeProcessorCount
    let sampleSize = Int(ceil(Double(self.count) / Double(coreCount)))

    let group = DispatchGroup()

    (0..<sampleSize).forEach { idx in

      let startIndex = idx * coreCount
      let endIndex = Swift.min((startIndex + (coreCount - 1)), self.count - 1)
      result[startIndex] = []

      group.enter()
      DispatchQueue.global().async {
        result[startIndex] = (startIndex...endIndex).map { idx in f(self[idx]) }
        group.leave()
      }
    }

    group.wait()

    return result.sorted(by: { $0.0 < $1.0 }).flatMap(second)
  }
}
