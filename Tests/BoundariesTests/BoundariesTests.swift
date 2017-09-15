import XCTest
import Boundaries
import BoundariesTestSupport
import Optics
import Prelude
import SnapshotTesting

final class BoundariesTests: XCTestCase {
  override func setUp() {
    super.setUp()
    recording = true
  }

  func testBoundaries() {
    let store = TestStore<CounterState, TestEffect<AppAction>>(
      reducer: counterReducer.lift(action: AppAction.prism.counterAction),
      initialState: .init(count: 0)
    )

    store.dispatch(.counterAction(.incr))
    store.dispatch(.counterAction(.incr))
    store.dispatch(.counterAction(.decr))

    assertSnapshot(matching: store)
  }

  func testCombinedBoundaries() {
    let store = TestStore(
      reducer: combinedReducer,
      initialState: AppState(counter: .init(count: 0), loggedIn: true)
    )

    store.dispatch(.counterAction(.incr))
    store.dispatch(.counterAction(.decr))
    store.dispatch(.settingsAction(.logout))

    assertSnapshot(matching: store)
  }
}

struct CounterState {
  var count: Int
}

enum CounterAction {
  case incr
  case decr
}

let counterReducer = Reducer<CounterState, CounterAction, TestEffect<AppAction>> { action, state in
  switch action {
  case .incr:
    return (state |> \.count +~ 1, .execute(fingerprint: "", .print("incr")))

  case .decr:
    return (state |> \.count -~ 1, .execute(fingerprint: "", .print("decr")))
  }
}

struct SettingsState {
  var loggedIn: Bool
}

enum SettingsAction {
  case logout
}

let settingsReducer = Reducer<SettingsState, SettingsAction, TestEffect<AppAction>> { action, state in

  switch action {
  case .logout:
    return (
      .init(loggedIn: false),
      .noop
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

enum TestEffect<A>: EffectProtocol {
  case print(String)

  func execute() -> A? {
    switch self {
    case let .print(message):
      Swift.print(message)
      return nil
    }
  }
}

let combinedReducer: Reducer<AppState, AppAction, TestEffect<AppAction>> =
  settingsReducer.lift(action: AppAction.prism.settingsAction, state: \.settingsState)
    <> counterReducer.lift(action: AppAction.prism.counterAction, state: \.counter)
