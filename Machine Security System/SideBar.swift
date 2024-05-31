//
//  SideBar.swift
//  Machine Security System
//
//  Created by Almahdi Morris on 31/5/24.
//

import SwiftUI

struct Sidebar: View {
    var body: some View {
        List {
            NavigationLink(destination: CameraView()) {
                Label("Camera", systemImage: "camera")
            }
            NavigationLink(destination: VideoView()) {
                Label("Video", systemImage: "video")
            }

            NavigationLink(destination: ViewLogsView()) {
                Label("View Logs", systemImage: "doc.text.magnifyingglass")
            }
            NavigationLink(destination: SettingsView()) {
                Label("Settings", systemImage: "gear")
            }
            NavigationLink(destination: CoreMLView()) {
                Label("CoreML", systemImage: "brain.head.profile")
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Menu")
    }
}
