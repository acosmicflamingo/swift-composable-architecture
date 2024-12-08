import AppCore
import ComposableArchitecture
import SwiftUI
import UIKit
import UIKitNavigation

// MARK: - SceneDelegate

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  let store = Store(initialState: TicTacToe.State.login(.init())) {
    TicTacToe.body._printChanges()
  }

  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let windowScene = scene as? UIWindowScene {
      let rootView = RootView(store: store)
      let rootViewController = UIHostingController(
        rootView: rootView
      )
      let window = UIWindow(windowScene: windowScene)
      // Would be nice to completely rely on reducer to configure
      // userInterfaceStyle, but doing so results in some delayed
      // UX updates. Workaround seems to be to just override window's
      // userInterfaceStyle here before it has been made visible.
      //
      // Actually...this might not even be needed. Testing is most
      // beneficial when device userInterfaceStyle is different from
      // app userInterfaceStyle
      window.rootViewController = rootViewController
      window.makeKeyAndVisible()
      self.window = window
    }
  }

  func sceneDidDisconnect(_ scene: UIScene) {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is
    // discarded. Release any resources associated with this scene that can be re-created
    // the next time the scene connects. The scene may re-connect later, as its session
    // was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when
    // the scene was inactive.
  }

  func sceneWillResignActive(_ scene: UIScene) {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
  }

  func sceneDidEnterBackground(_ scene: UIScene) {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough
    // scene-specific state information to restore the scene back to its current state.
  }

  func sceneWillEnterForeground(_ scene: UIScene) {
  }
}

// MARK: - AppDelegate

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Override point for customization after application launch.
    prepareDependencies {
      $0.date.now = Date(timeIntervalSince1970: 0.0)
    }
    return true
  }

  // MARK: UISceneSession Lifecycle

  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    return UISceneConfiguration(
      name: "Default Configuration",
      sessionRole: connectingSceneSession.role
    )
  }
}
