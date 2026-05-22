# SUT (Yentest) - 專案架構文件

## 專案概述
一款多功能 iOS App，主要功能包含**健康記錄**（體重追蹤、運動紀錄）與**房貸試算**。
使用 SwiftUI + Core Data 構建，整合 Firebase 與 Google Maps SDK。

## 技術棧
- **UI 框架**: SwiftUI
- **資料持久化**: Core Data (`MeditationApp.xcdatamodeld`)
- **第三方服務**: Firebase (FirebaseCore)、Google Maps (GoogleMaps SDK)
- **圖表**: SwiftUI Charts (iOS 16+)
- **最低支援**: iOS 16+

## 目錄結構
```
SUT/
├── SUTApp.swift                 # App 入口，配置 Firebase、Google Maps、Core Data
├── ContentView.swift            # 主 TabView（健康記錄、房貸試算）
├── Persistence.swift            # Core Data PersistenceController (Singleton)
├── Services.swift               # 共用服務 (HapticManager, SoundManager - Singleton)
│
├── Health/                      # 健康記錄模組
│   ├── HealthViewModel.swift    # 健康記錄 ViewModel (Core Data CRUD、日曆邏輯)
│   ├── RecordEditView.swift     # 編輯紀錄 Sheet（體重、運動類型、運動時間）
│   └── WeightTrendView.swift    # 體重趨勢圖表 (SwiftUI Charts)
│
├── HealthRecordView.swift       # 健康記錄主畫面（日曆 + 日期格子）
├── MortgageCalculatorView.swift # 房貸試算頁面 + 結果 Sheet
├── LocationMapView.swift        # Google Maps 地圖頁面（從房貸試算進入）
│
├── ContractionTimerView.swift   # 宮縮記錄（目前未使用於 TabView）
├── MeditationSession.swift      # 冥想 Model（目前未使用於 TabView）
├── MeditationViewModel.swift    # 冥想 ViewModel（目前未使用於 TabView）
├── PlayerView.swift             # 冥想播放畫面（目前未使用於 TabView）
│
├── Config/                      # 建置環境設定
│   ├── Debug.xcconfig
│   ├── Release.xcconfig
│   └── Staging.xcconfig
│
└── Assets.xcassets              # 圖片資源
```

## 架構模式: MVVM

### View 層
| View | 說明 |
|------|------|
| `ContentView` | 主 TabView，管理 Tab 切換與全域 UI 外觀設定 |
| `HealthRecordView` | 健康記錄首頁，日曆格子顯示體重/運動 emoji |
| `RecordEditView` | 編輯單日紀錄的 Sheet (體重、運動類型、運動時間) |
| `WeightTrendView` | 當月體重趨勢折線圖 |
| `MortgageCalculatorView` | 房貸試算輸入表單 + 結果 Sheet |
| `MortgageResultView` | 試算結果顯示（寬限期方案比較） |
| `LocationMapView` | Google Maps 地圖頁面 |

### ViewModel 層
| ViewModel | 說明 |
|-----------|------|
| `HealthViewModel` | 管理日曆邏輯、Core Data 的 CRUD、月份切換 |

### Model / Data 層
| 元件 | 說明 |
|------|------|
| `DailyRecord` (Core Data Entity) | 每日健康紀錄：date, weight, hasExercise, exerciseType, exerciseDuration |
| `MortgageResultData` | 房貸試算結果的資料模型 (純 struct) |
| `PersistenceController` | Core Data Stack 管理 (Singleton: `PersistenceController.shared`) |

### Singleton 服務層
| 服務 | 檔案 | 說明 |
|------|------|------|
| `PersistenceController.shared` | Persistence.swift | Core Data 容器管理 |
| `HapticManager.shared` | Services.swift | 觸覺回饋服務 |
| `SoundManager.shared` | Services.swift | 系統音效播放服務 |
| `AppFormatters.shared` | Services.swift | 共用 DateFormatter / NumberFormatter |
| `ExerciseConfig.shared` | Services.swift | 運動類型定義與 emoji 對應 |

## Core Data 模型
**Entity: DailyRecord**
| 屬性 | 型別 | 說明 |
|------|------|------|
| `date` | Date? | 紀錄日期 (startOfDay) |
| `weight` | Double | 體重 (kg)，預設 0.0 |
| `hasExercise` | Boolean | 當日是否有運動 |
| `exerciseType` | String? | 運動類型（跑步、走路、瑜伽等） |
| `exerciseDuration` | Double | 運動時間（分鐘），預設 0.0 |

## 頁面導航流程
```
TabView (ContentView)
├── Tab 1: 健康記錄 (HealthRecordView) ← 首頁
│   ├── 點擊日期 → Sheet: RecordEditView (編輯體重/運動)
│   └── 點擊圖表按鈕 → Sheet: WeightTrendView (體重趨勢)
│
└── Tab 2: 房貸試算 (MortgageCalculatorView)
    ├── 點擊試算 → Sheet: MortgageResultView (結果)
    └── 點擊地圖 → Sheet: LocationMapView (Google Maps)
```

## 運動類型對應
| 類型 | Emoji |
|------|-------|
| 跑步 | 🏃 |
| 走路 | 🚶 |
| 瑜伽 | 🧘 |
| 游泳 | 🏊 |
| 重訓 | 🏋️ |
| 騎車 | 🚴 |
| 有氧 | 💪 |
| 球類 | ⚽ |
| 其他 | 🏅 |

## 開發注意事項
- Core Data model 檔案名稱為 `MeditationApp.xcdatamodeld`（歷史命名）
- Google Maps API Key 設定在 `SUTApp.swift` 的 `init()` 中
- Firebase 透過 `GoogleService-Info.plist` 配置
- 鍵盤收起：全域支援點擊空白處收起鍵盤，表單頁面有 toolbar 完成按鈕
- 所有 DateFormatter 與 NumberFormatter 透過 `AppFormatters.shared` 共用，避免重複建立
- 運動類型選項與 emoji 對應透過 `ExerciseConfig.shared` 統一管理
