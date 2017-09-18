import Boundaries
import Dispatch
import Foundation
import Optics
import Prelude
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

enum TestEffect: EffectProtocol {
  typealias Action = CounterAction
}

struct CounterState {
  var count: Int
}

enum CounterAction {
  case decr
  case incr
  case gotRandomInt(Int)
  case isPrimeResult(Data?, URLResponse?, Error?)
}

func apiRequest(_ n: Int) -> URLRequest {
  return URLRequest(
    url: URL(
      string: "https://api.wolframalpha.com/v2/query?input=is%20\(n)%20prime%3F&appid=6H69Q3-828TKQJ4EP&output=json"
      )!
  )
}

let counterReducer = Reducer<CounterState, CounterAction, Effect<TestEffect>> { action, state in
  switch action {
  case .decr:
    return (state |> \.count -~ 1, .execute(.print("decr")))

  case .incr:
    return (
      state |> \.count +~ 1,
      .parallel(
        [
          .execute(.print("incr")),
          .execute(
            .urlSession(apiRequest(state.count + 1), CounterAction.isPrimeResult)
          ),
          .execute(.randomInt(min: 10, max: 20, CounterAction.gotRandomInt)),
        ]
      )
    )

  case let .gotRandomInt(n):
    print("random = \(n)")
    return (state, .noop)

  case let .isPrimeResult(data, _, _):
    print(String(data: data!, encoding: .utf8)!)
    return (state, .noop)
  }
}

let store = Store(
  reducer: counterReducer,
  initialState: .init(count: 0),
  interpreter: { effect in
    return nil
  }
)

store.subscribe { print($0) }

store.dispatch(.incr)
store.dispatch(.incr)
store.dispatch(.incr)
