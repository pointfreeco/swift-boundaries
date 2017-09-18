import Boundaries
import Optics
import Prelude
import Dispatch
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

enum TestEffect: Effect {
  typealias Action = CounterAction

  case print(String)
}

struct CounterState {
  var count: Int
}

enum CounterAction {
  case incr
  case decr
}

let counterReducer = Reducer<CounterState, CounterAction, TestEffect> { action, state in
  switch action {
  case .incr:
    return (state |> \.count +~ 1, .execute(.print("incr")))
  case .decr:
    return (state |> \.count -~ 1, .execute(.print("decr")))
  }
}

let store = Store(
  reducer: counterReducer,
  initialState: .init(count: 0),
  interpreter: { effect in
    switch effect {
    case let .print(message):
      print(message)
      return nil
    }
  }
)

store.subscribe { print($0) }

store.dispatch(.incr)
store.dispatch(.incr)
store.dispatch(.incr)
