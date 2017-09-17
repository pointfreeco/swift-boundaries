import Boundaries
import Dispatch
import Optics
import Prelude

struct CounterState {
  var count: Int
}

enum CounterAction {
  case incr
  case decr
}

let counterReducer = Reducer<CounterState, CounterAction, MyEffect> { action, state in
  switch action {
  case .incr:
    return (
      state |> \.count +~ 1,
      .parallel(
        [
          .execute(.print("incr")),
          .execute(.trackAnalytics(eventName: "Incremented", properties: ["count": state.count + 1]))
        ]
      )
    )

  case .decr:
    return (state |> \.count -~ 1, .execute(.print("decr")))
  }
}

struct SettingsState {
  var loggedIn: Bool
}

enum SettingsAction {
  case logout
}

let settingsReducer = Reducer<SettingsState, SettingsAction, MyEffect> { action, state in

  switch action {
  case .logout:
    return (
      .init(loggedIn: false),
      .execute(.request("http://www.google.com"))
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
  case requestResult(String)

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

enum MyEffect: EffectProtocol {
  typealias A = AppAction
  case print(String)
  case request(String)
  case trackAnalytics(eventName: String, properties: [String: Any])
}

func testExecute(_ effect: MyEffect) -> AppAction? {
  switch effect {
  case .print:
    return nil

  case let .request(urlRequestString):
    return AppAction.requestResult("\(urlRequestString): HELLO WORLD!")

  case .trackAnalytics:
    return nil
  }
}


func realExecute(_ effect: MyEffect) -> AppAction? {
  switch effect {
  case let .print(message):
    Swift.print(message)
    return nil

  case let .request(urlRequestString):
    let sema = DispatchSemaphore(value: 0)
    DispatchQueue.global().asyncAfter(deadline: .now() + 1) { sema.signal() }
    sema.wait()
    return AppAction.requestResult("\(urlRequestString): HELLO WORLD!")

  case let .trackAnalytics(eventName, properties):
    DispatchQueue.global().asyncAfter(deadline: .now() + 1) { print("tracked \(eventName): \(properties)") }
    return nil
  }
}

let combinedReducer: Reducer<AppState, AppAction, MyEffect> =
  settingsReducer.lift(action: AppAction.prism.settingsAction, state: \.settingsState)
    <> counterReducer.lift(action: AppAction.prism.counterAction, state: \.counter)
