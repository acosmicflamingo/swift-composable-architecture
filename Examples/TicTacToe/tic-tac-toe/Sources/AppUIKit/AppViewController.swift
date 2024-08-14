import AppCore
import ComposableArchitecture
import LoginUIKit
import LoginCore
import NewGameCore
import NewGameUIKit
import SwiftUI
import UIKit

public struct UIKitAppView: UIViewControllerRepresentable {
  let store: StoreOf<TicTacToe>

  public init(store: StoreOf<TicTacToe>) {
    self.store = store
  }

  public func makeUIViewController(context: Context) -> UIViewController {
    AppViewController(store: store)
  }

  public func updateUIViewController(
    _ uiViewController: UIViewController,
    context: Context
  ) {
    // Nothing to do
  }
}

class AppViewController: UINavigationController {
  let store: StoreOf<TicTacToe>

  init(store: StoreOf<TicTacToe>) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    observe { [weak self] in
      guard let self else { return }
      switch store.case {
      case let .login(store):
        setViewControllers([LoginViewController(store: store)], animated: false)
      case let .newGame(store):
        setViewControllers([NewGameViewController(store: store)], animated: false)
      }
    }
  }
}

@Reducer
struct RootFeature {
  @ObservableState
  struct State {
    var path = StackState<Path.State>()
    // ...
  }
  enum Action {
    case path(StackActionOf<Path>)
    // ...
  }

  @Reducer
  enum Path {
    case login(Login)
    case newGame(NewGame)
  }
}

class AppController: NavigationStackController {
  private var store: StoreOf<RootFeature>!

  @MainActor
  init(store: StoreOf<RootFeature>) {
    @UIBindable var store = store

    super.init(path: $store.scope(state: \.path, action: \.path)) {
      UIViewController()
    } destination: { store in
      switch store.case {
      case let .login(store):
        LoginViewController(store: store)
      case let .newGame(store):
        NewGameViewController(store: store)
      }
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
