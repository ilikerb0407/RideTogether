//
//  HomeView.swift
//  RideTogether
//
//  Created by Auto on 2024/12/19.
//

import SwiftUI

// Temporary color extension until Color+Extension.swift is added to build target
extension Color {
    static let B3 = Color("B3")
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModelSwiftUI()
    
    var body: some View {
        NavigationView {
            List {
                // Header Section
                Section {
                    HomeHeaderView()
                } header: {
                    EmptyView()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                // Routes Section
                ForEach(RoutesType.allCases.indices, id: \.self) { index in
                    Section {
                        RouteTypeRow(type: RoutesType.allCases[index])
                            .onTapGesture {
                                // Handle route selection
                            }
                    } header: {
                        EmptyView()
                    }
                }
            }
            .listStyle(.grouped)
            .background(
                LinearGradient(
                    colors: [Color.white, Color.B3],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.85)
            )
            .navigationTitle("探索路線")
            .onAppear {
                viewModel.fetchTrailData()
            }
        }
    }
}

struct HomeHeaderView: View {
    @State private var userInfo = UserManager.shared.userInfo
    
    var body: some View {
        // Header implementation - will be enhanced later
        Text("Header")
            .frame(height: 270)
    }
}

struct RouteTypeRow: View {
    let type: RoutesType
    
    var body: some View {
        HStack {
            if let image = type.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
            }
            Text(type.title)
        }
        .frame(height: 200)
    }
}

// MARK: - HomeViewModel for SwiftUI

class HomeViewModelSwiftUI: ObservableObject {
    @Published var routes: [Route] = []
    
    func fetchTrailData() {
        // Placeholder - will be implemented with actual data fetching
    }
}

