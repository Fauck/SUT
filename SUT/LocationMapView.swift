import SwiftUI
import GoogleMaps
import CoreLocation

// MARK: - Location Manager (定位管理器)
// 負責處理 GPS 權限與座標更新
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    // 發布給 View 的使用者位置
    @Published var userLocation: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // 請求定位權限
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            print("使用者拒絕定位權限")
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}

// MARK: - Google Maps SwiftUI Wrapper
// 將 UIKit 的 GMSMapView 包裝給 SwiftUI 使用
struct GoogleMapsView: UIViewRepresentable {
    @Binding var userLocation: CLLocationCoordinate2D?
    
    func makeUIView(context: Context) -> GMSMapView {
        // 預設鏡頭位置 (台北 101)
        let camera = GMSCameraPosition.camera(withLatitude: 25.033964, longitude: 121.564468, zoom: 15.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        
        // 啟用「我的位置」藍點 (需要 Info.plist 權限)
        mapView.isMyLocationEnabled = true
        // 啟用內建的「回到我的位置」按鈕
        mapView.settings.myLocationButton = true
        // 啟用指北針
        mapView.settings.compassButton = true
        
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // 當收到新的使用者位置時，移動鏡頭
        if let location = userLocation {
            let cameraUpdate = GMSCameraUpdate.setTarget(location, zoom: 16.0)
            mapView.animate(with: cameraUpdate)
        }
    }
}

// MARK: - 主地圖頁面
struct LocationMapView: View {
    @StateObject private var locationManager = LocationManager()
    
    // 新增：環境變數，用於關閉視窗
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Google Maps 地圖
                GoogleMapsView(userLocation: $locationManager.userLocation)
                    .edgesIgnoringSafeArea(.top)
                
                // 自定義定位按鈕
                Button(action: {
                    locationManager.requestLocation()
                }) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.indigo)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("我的位置")
            .navigationBarTitleDisplayMode(.inline)
            // 新增：導航列工具
            .toolbar {
                // 左上角關閉按鈕
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                }
            }
        }
    }
}
