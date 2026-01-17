//
//  ContentView.swift
//  RideTogether
//
//  Created by Auto on 2024/12/19.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authState: AuthStateManager
    
    var body: some View {
        if authState.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if authState.isAuthenticated {
            MainTabView()
        } else {
            LoginView()
        }
    }
}

