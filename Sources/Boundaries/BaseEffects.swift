import Foundation

public enum Effect<E: EffectProtocol>: EffectProtocol {
  public typealias Action = E.Action

  case urlSession(URLRequest, (Data?, URLResponse?, Error?) -> Action?)
  case print(String)
  case randomInt(min: Int, max: Int, (Int) -> Action?)
  case other(E)
}

public func wrap<E>(interpreter interpret: @escaping (E) -> E.Action?) -> (Effect<E>) -> E.Action? {
  return { effect in
    switch effect {
    case let .urlSession(request, actionCreator):
      var action: E.Action?
      let sema = DispatchSemaphore(value: 0)
      URLSession.shared.dataTask(with: request) { data, response, error in
        action = actionCreator(data, response, error)
        sema.signal()
        }
        .resume()
      sema.wait()
      return action

    case let .print(message):
      print(message)
      return nil

    case let .randomInt(min, max, actionCreator):
      return actionCreator(Int(arc4random()) % (max - min + 1) + min)

    case let .other(effect):
      return interpret(effect)
    }
  }
}
