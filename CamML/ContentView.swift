//
//  ContentView.swift
//  CamML
//
//  Created by Almahdi Morris on 05/25/24.
//
import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraController = CameraController()
    @State private var isSettingsPresented = false
    @State private var isCameraViewOnTop = false
    
    var body: some View {
        VStack {
            CameraView(cameraController: cameraController)
                .frame(width: 800, height: 600)
                .onTapGesture(count: 2, perform: cameraController.capturePhoto)
                .contextMenu {
                    Button("Take Photo", action: cameraController.capturePhoto)
                    Button("Copy Frame", action: cameraController.copyFrame)
                    Button("Pause Live Feed", action: cameraController.pauseLiveFeed)
                    Button("Start Recording", action: cameraController.startRecording)
                }
            
            Button("Settings") {
                isSettingsPresented.toggle()
            }
            .sheet(isPresented: $isSettingsPresented) {
                CameraSettings(cameraController: cameraController)
            }
            
            Toggle("Stay on Top", isOn: $isCameraViewOnTop)
                .onChange(of: isCameraViewOnTop) { newValue in
                    if newValue {
                        UIApplication.shared.windows.first?.windowLevel = UIWindow.Level.statusBar + 1
                    } else {
                        UIApplication.shared.windows.first?.windowLevel = UIWindow.Level.normal
                    }
                }
        }
    }
}
