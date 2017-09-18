import Boundaries
import BoundariesTestSupport
import SnapshotTesting
import XCTest

final class BoundariesTests: XCTestCase {
  override func setUp() {
    super.setUp()
  }

  func testBoundaries() {
    let store = TestStore<CounterState, MyEffect>(
      reducer: counterReducer.lift(action: AppAction.prism.counterAction),
      initialState: .init(count: 0),
      execute: testExecute
    )

    store.dispatch(.counterAction(.incr))
    store.dispatch(.counterAction(.incr))
    store.dispatch(.counterAction(.decr))

    assertSnapshot(matching: store)
  }

  func testCombinedBoundaries() {
    let store = TestStore(
      reducer: combinedReducer,
      initialState: AppState(counter: .init(count: 0), loggedIn: true),
      execute: testExecute
    )

    store.dispatch(.counterAction(.incr))
    store.dispatch(.counterAction(.decr))
    store.dispatch(.settingsAction(.logout))

    assertSnapshot(matching: store)
  }
}

