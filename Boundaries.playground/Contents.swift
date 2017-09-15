import Boundaries
import Optics
import Prelude
import Dispatch
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

extension Array {
  public func _pmap<B>(_ f: @escaping (Iterator.Element) -> B) -> [B] {

    let semaphore = DispatchSemaphore(value: 0)
    var result: [B?] = [B?].init(repeating: nil, count: self.count)
    var completed = 0

    self.enumerated().forEach { idx, x in
      DispatchQueue.global(qos: .userInitiated).async {
        result[idx] = f(x)
        completed += 1

        if completed == self.count - 1 {
          semaphore.signal()
        }
      }
    }

    semaphore.wait()

    print("-----")
    print(result.count)
    print(result)
    print("-----")
    return result.map { $0! }
  }

  func parallelMap<T>(_ f: @escaping (Iterator.Element) -> T) -> [T] {
    guard !self.isEmpty else { return [] }

    var result: [Int: [T]] = [:]

    let coreCount = ProcessInfo.processInfo.activeProcessorCount
    let sampleSize = Int(ceil(Double(self.count) / Double(coreCount)))

    let group = DispatchGroup()

    (0..<sampleSize).forEach { idx in

      let startIndex = idx * coreCount
      let endIndex = Swift.min((startIndex + (coreCount - 1)), self.count - 1)
      result[startIndex] = []

      group.enter()
      DispatchQueue.global().async {
        (startIndex...endIndex).forEach { idx in
          result[startIndex]?.append(f(self[idx]))
        }
        group.leave()
      }
    }

    group.wait()

    return result.sorted(by: { $0.0 < $1.0 }).flatMap(second)
  }
}

import Foundation
ProcessInfo.processInfo.activeProcessorCount

Array(1...102)
  .parallelMap { $0 + 1 }
  .reduce(0, +)

2

//struct CounterState {
//  var count: Int
//}
//
//enum CounterAction {
//  case incr
//  case decr
//}
//
//let counterReducer = Reducer<CounterState, CounterAction> { action, state in
//  switch action {
//  case .incr:
//    return (state |> \.count +~ 1, .noop)
//  case .decr:
//    return (state |> \.count -~ 1, .noop)
//  }
//}
//
//let store = Store(reducer: counterReducer, initialState: .init(count: 0))
//
//store.subscribe { print($0) }
//
//store.dispatch(.incr)
//store.dispatch(.incr)
//store.dispatch(.incr)

