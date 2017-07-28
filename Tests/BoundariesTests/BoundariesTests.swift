import XCTest
import Boundaries
import BoundariesTestSupport
import Optics
import Prelude
import SnapshotTesting

final class BoundariesTests: XCTestCase {
  func testBoundaries() {
    let store = TestStore(
      reducer: counterReducer,
      initialState: .init(count: 0)
    )

    store.dispatch(.incr)
    store.dispatch(.incr)
    store.dispatch(.decr)

    assertSnapshot(matching: store.history)
  }

  func testCombinedBoundaries() {
    let store = TestStore(
      reducer: combinedReducer,
      initialState: AppState(counter: .init(count: 0), loggedIn: true)
    )

    store.dispatch(.counterAction(.incr))
    store.dispatch(.counterAction(.decr))
    store.dispatch(.settingsAction(.logout))

    assertSnapshot(matching: store.history)
  }
}

func print<A>(_ string: String) -> Effect<A> {
  return .execute("Print", string) { s in print(s); return nil }
}

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
    return (state |> \.count +~ 1, print("incr"))
  case .decr:
    return (state |> \.count -~ 1, print("decr"))
  }
}

struct SettingsState {
  var loggedIn: Bool
}

enum SettingsAction {
  case logout
}

let settingsReducer = Reducer<SettingsState, SettingsAction> { action, state in
  switch action {
  case .logout:
    return (
      .init(loggedIn: false),
      .execute("Clear Cache", unit, const(nil))
    )
  }
}

struct AppState {
  var counter: CounterState
  var loggedIn: Bool

  var settingsState: SettingsState {
    get { return .init(loggedIn: self.loggedIn) }
    set { self = .init(counter: self.counter, loggedIn: newValue.loggedIn)}
  }
}

enum AppAction {
  case counterAction(CounterAction)
  case settingsAction(SettingsAction)

  enum prism {
    static var counterAction: Prism<AppAction, CounterAction> {
      return .init(
        preview: { action in
          guard case let .counterAction(a) = action else { return nil }
          return a },
        review: AppAction.counterAction
      )
    }

    static var settingsAction: Prism<AppAction, SettingsAction> {
      return .init(
        preview: { action in
          guard case let .settingsAction(a) = action else { return nil }
          return a },
        review: AppAction.settingsAction
      )
    }
  }
}

let combinedReducer: Reducer<AppState, AppAction> =
  settingsReducer.lift(action: AppAction.prism.settingsAction, state: lens(\AppState.settingsState))
    <> counterReducer.lift(action: AppAction.prism.counterAction, state: lens(\AppState.counter))
