import SwiftUI

struct DeviceInfoView: View {
  @ObservedObject private var viewModel = DeviceInfoViewModel()
  
  var body: some View {
    TabView {
      FiltersView()
        .tabItem {
          Label("Filters", systemImage: "slider.horizontal.3")
        }
      
      AdjustmentsView()
        .tabItem {
          Label("Adjustments", systemImage: "wand.and.rays")
        }
      
      DeviceSettingsView(viewModel: viewModel)
        .tabItem {
          Label("Device", systemImage: "video")
        }
    }
    .navigationTitle("Settings")
    .textSelection(.enabled)
  }
}


