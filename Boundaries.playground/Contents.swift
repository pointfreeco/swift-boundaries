import Boundaries
import Optics
import Prelude

struct CounterState {
  var count: Int
}

enum CounterAction {
  case incr
  case decr
}

let counterReducer = Reducer<CounterState, CounterAction> { action, state in
  switch action {
  case .incr:
    return (state |> \.count +~ 1, .noop)
  case .decr:
    return (state |> \.count -~ 1, .noop)
  }
}

let store = Store(reducer: counterReducer, initialState: .init(count: 0))

store.subscribe { print($0) }

store.dispatch(.incr)
store.dispatch(.incr)
store.dispatch(.incr)
