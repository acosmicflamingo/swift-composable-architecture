import ComposableArchitecture
import SwiftUI

@Reducer
struct AppFeature {
  @Reducer(state: .equatable)
  enum Path {
    case detail(SyncUpDetail)
    case meeting(Meeting, syncUp: SyncUp)
    case record(RecordMeeting)
  }

  @ObservableState
  struct State: Equatable {
    var path = StackState<Path.State>()
    var syncUpsList = SyncUpsList.State()
  }

  enum Action {
    case path(StackActionOf<Path>)
    case pathResponse(StackState<Path.State>)
    case syncUpsList(SyncUpsList.Action)
    case pushToStackState
  }

  @Dependency(\.continuousClock) var continuousClock
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
          let currentPath = state.path
          var newPath = state.path
          newPath.append(.record(RecordMeeting.State(syncUp: sharedSyncUp)))
          state.path = newPath
          return .run { @MainActor [currentPath] send in
            try? await continuousClock.sleep(for: .seconds(5.0), tolerance: nil)
            var newPath2 = currentPath
            newPath2.append(.record(RecordMeeting.State(syncUp: sharedSyncUp)))
            send(.pathResponse(newPath2))
          }
        }

      case .path:
        return .none

      case let .pathResponse(path):
        state.path = path
        return .none

      case .pushToStackState:
        var currentPath = StackState<Path.State>()
        var newPath = StackState<Path.State>()
        newPath.append(.record(RecordMeeting.State(syncUp: Shared(SyncUp(id: SyncUp.ID())))))
        state.path = newPath
        return .run { @MainActor [currentPath] send in
          try? await continuousClock.sleep(for: .seconds(5.0), tolerance: nil)
          var newPath2 = currentPath
          newPath2.append(.meeting(Meeting(id: Meeting.ID(), date: .distantFuture, transcript: ""), syncUp: SyncUp(id: SyncUp.ID())))
          send(.pathResponse(newPath2))
        }

      case .syncUpsList:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}

struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>

  var body: some View {
    UIViewControllerRepresenting {
      AppController(store: store)
    }
  }
}

class AppController: NavigationStackController {
  var store: StoreOf<AppFeature>!

  convenience init(store: StoreOf<AppFeature>) {
    @UIBindable var store = store

    let viewControllerGenerator: (UIColor) -> UIViewController = { color in
      let controller = UIViewController()
      controller.view.backgroundColor = color
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

    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
      guard let self else { return }

      store.send(.pushToStackState)
    }
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
