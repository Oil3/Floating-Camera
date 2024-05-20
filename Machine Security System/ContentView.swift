//
//  ContentView.swift
//  Machine Security System
//
//  Created by Almahdi Morris on 04/25/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        CameraView()
            .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

