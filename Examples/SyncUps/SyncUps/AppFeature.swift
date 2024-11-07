import ComposableArchitecture
import SwiftUI

@Reducer
struct AppFeature {
  @Reducer
  enum Path {
    case detail(SyncUpDetail)
    case meeting(Meeting, syncUp: SyncUp)
    case record(RecordMeeting)
  }

  @ObservableState
  struct State: Equatable {
    var path = StackState<Path.State>()
    var syncUpsList = SyncUpsList.State()
    init(
      path: StackState<Path.State> = StackState<Path.State>(),
      syncUpsList: SyncUpsList.State = SyncUpsList.State()
    ) {
      self.path = StackState<Path.State>.init([.detail(.init(syncUp: Shared(SyncUp(id: .init()))))])
      self.syncUpsList = syncUpsList
    }
  }

  enum Action {
    case path(StackActionOf<Path>)
    case syncUpsList(SyncUpsList.Action)
    case pushToStackState
  }

  @Dependency(\.date.now) var now
  @Dependency(\.uuid) var uuid

  var body: some ReducerOf<Self> {
    Scope(state: \.syncUpsList, action: \.syncUpsList) {
      SyncUpsList()
    }
    Reduce { state, action in
      switch action {
      case let .path(.element(_, .detail(.delegate(delegateAction)))):
        switch delegateAction {
        case let .startMeeting(sharedSyncUp):
          state.path.append(.record(RecordMeeting.State(syncUp: sharedSyncUp)))
          return .none
        }

      case .path:
        return .none

      case .pushToStackState:
        var currentPath = StackState<Path.State>()
        var newPath = StackState<Path.State>()
        newPath.append(.record(RecordMeeting.State(syncUp: Shared(SyncUp(id: SyncUp.ID())))))
        state.path = newPath
        return .none

      case .syncUpsList:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}
extension AppFeature.Path.State: Equatable {}

struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>

  var body: some View {
    UIViewControllerRepresenting {
      AppController(store: store)
    }
  }
}

class TapViewController: UIViewController {
  var action: (() -> Void)?

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    let gesture = UITapGestureRecognizer(target: self, action: #selector(sendAction))
    view.addGestureRecognizer(gesture)
  }

  @objc func sendAction() {
    action?()
  }
}

class AppController: NavigationStackController {
  var store: StoreOf<AppFeature>!

  convenience init(store: StoreOf<AppFeature>) {
    @UIBindable var store = store

    let viewControllerGenerator: (UIColor) -> UIViewController = { color in
      let controller = TapViewController()
      controller.view.backgroundColor = color
      controller.action = { [weak store] in
        store?.send(.pushToStackState)
      }
      return controller
    }
    self.init(path: $store.scope(state: \.path, action: \.path)) {
      viewControllerGenerator(.red)
    } destination: { store in
      switch store.case {
      case let .detail(store):
        viewControllerGenerator(.green)
      case let .meeting(meeting, syncUp):
        viewControllerGenerator(.blue)
      case let .record(store):
        viewControllerGenerator(.yellow)
      }
    }

    self.store = store
  }
}

#Preview {
  @Shared(.syncUps) var syncUps = [
    .mock,
    .productMock,
    .engineeringMock,
  ]
  return AppView(
    store: Store(initialState: AppFeature.State()) {
      AppFeature()
    }
  )
}
