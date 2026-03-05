//
//  SUTApp.swift
//  SUT
//
//  Created by bokmacdev on 2025/12/9.99999
//

import SwiftUI
import FirebaseCore
import GoogleMaps // 1. 引入 Google Maps

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}
@main
struct SUTApp: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    init() {
            // ⚠️ 請將這裡替換為您從 Google Cloud Console 申請到的真實 API Key
            // 如果沒有 Key，App 執行時會閃退或地圖呈現空白
//        AIzaSyBB_XEKiVLcyllurnxDM4X8-hi6J19ByNc--首頁
//        AIzaSyDlxDCB0Ci3XBR01XTA4oLKoCRmZvwfEPQ--我的
            GMSServices.provideAPIKey("AIzaSyDlxDCB0Ci3XBR01XTA4oLKoCRmZvwfEPQ")
        }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
