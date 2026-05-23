/// Evaluates a throwing closure on first access and caches the result for subsequent calls.
///
/// Useful for memoising expensive operations whose evaluation cost should only be paid
/// when (and if) the value is actually needed.
final class LazyThrowing<Value> {
    private enum State {
        case pending(() throws -> Value)
        case resolved(Result<Value, any Error>)
    }

    private var state: State

    init(_ compute: @escaping () throws -> Value) {
        state = .pending(compute)
    }

    func value() throws -> Value {
        switch state {
        case let .pending(compute):
            let result = Result { try compute() }
            state = .resolved(result)
            return try result.get()
        case let .resolved(result):
            return try result.get()
        }
    }
}
