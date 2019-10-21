import Foundation
import Combine

public protocol StoreActionType {}
public protocol SubstateType {
    init()
}

public typealias StoreStateType = Dictionary<Int, SubstateType>
public typealias StoreReducer = (StoreStateType, StoreActionType) -> StoreStateType
public typealias StatePublisher = AnyPublisher<StoreStateType, Never>
public typealias ActionPublisher = AnyPublisher<StoreActionType?, Never>
public typealias StateAndActionPublisher = AnyPublisher<(StoreStateType, StoreActionType?), Never>

public protocol MiddlewareType: class {
    func observe(store: StoreType)
}

public protocol StoreType: class {
    var currentState: StoreStateType { get }
    var state: AnyPublisher<StoreStateType, Never> { get }
    var lastDispatchedAction: AnyPublisher<StoreActionType?, Never> { get }
    var lastStateAndAction: AnyPublisher<(StoreStateType, StoreActionType?), Never> { get }
    var middlewares: Array<MiddlewareType> { get }

    init(reducer: @escaping StoreReducer)

    func dispatch(action: StoreActionType)
    func register(middleware: MiddlewareType)
    func register(middlewares: Array<MiddlewareType>)
}

public final class Store: StoreType {
    public enum Action: StoreActionType {
        case add(substate: SubstateType, forKey: Int)
        case remove(key: Int)
        case reset
    }

    public var currentState: StoreStateType { _state.value }
    public var state: StatePublisher { _state.eraseToAnyPublisher() }
    public var lastDispatchedAction: ActionPublisher { _lastDispatchedAction.eraseToAnyPublisher() }
    public var lastStateAndAction: StateAndActionPublisher { state.zip(lastDispatchedAction).eraseToAnyPublisher() }
    public var middlewares: Array<MiddlewareType> { _middlewares }

    private let reducer: StoreReducer

    private var _state = CurrentValueSubject<StoreStateType, Never>([:])
    private var _lastDispatchedAction = CurrentValueSubject<StoreActionType?, Never>(nil)
    private var _middlewares: Array<MiddlewareType> = []

    public init(reducer: @escaping StoreReducer) {
        self.reducer = { state, action -> StoreStateType in
            switch action {
            case let storeAction as Store.Action: return Store.reduce(state: state, action: storeAction)
            default: return reducer(state, action)
            }
        }
    }

    public func dispatch(action: StoreActionType) {
        _state.send(reducer(_state.value, action))
        _lastDispatchedAction.send(action)
    }

    public func register(middleware: MiddlewareType) {
        middleware.observe(store: self)
        _middlewares.append(middleware)
    }

    public func register(middlewares: Array<MiddlewareType>) {
        middlewares.forEach { self.register(middleware: $0) }
    }

    static func reduce(state: StoreStateType, action: Store.Action) -> StoreStateType {
        var state = state
        switch action {
        case let .add(substate: substate, forKey: key):
            state[key] = substate
            return state
        case let .remove(key: key):
            state.removeValue(forKey: key)
            return state
        case .reset:
            return [:]
        }
    }
}
