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
    @Environment(\.repositories) private var repositories
    @StateObject private var viewModel: HomeViewModel

    init() {
        // Initialize with placeholder - will be updated in onAppear
        let placeholderRepo = MapsRepository()
        _viewModel = StateObject(wrappedValue: HomeViewModel(repository: placeholderRepo))
    }

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.routes.isEmpty {
                    // Loading state
                    ProgressView("載入中...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let errorMessage = viewModel.errorMessage, viewModel.routes.isEmpty {
                    // Error state
                    VStack(spacing: 16) {
                        Text("載入失敗")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("重試") {
                            viewModel.retry()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    // Content
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
                        ForEach(RoutesType.allCases, id: \.self) { routeType in
                            Section {
                                RouteTypeRow(
                                    type: routeType,
                                    routes: viewModel.routes(for: routeType)
                                )
                                .onTapGesture {
                                    // Handle route selection - will be implemented later
                                    // Navigate to route detail or route list for this type
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
                    .refreshable {
                        viewModel.fetchRoutes()
                    }
                }
            }
            .navigationTitle("探索路線")
            .onAppear {
                // Update viewModel with repository from environment
                if viewModel.routes.isEmpty && !viewModel.isLoading {
                    viewModel.fetchRoutes()
                }
            }
        }
    }
}

struct HomeHeaderView: View {
    @EnvironmentObject private var authState: AuthStateManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let userInfo = authState.userInfo {
                HStack {
                    // User picture
                    if let pictureRef = userInfo.pictureRef, !pictureRef.isEmpty {
                        AsyncImage(url: URL(string: pictureRef)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(userInfo.userName ?? "破風手")
                            .font(.headline)
                        Text("總里程: \(String(format: "%.2f", userInfo.totalLength)) km")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()

                // Stats row
                HStack(spacing: 20) {
                    StatView(title: "騎乘團數", value: "\(userInfo.totalGroups)")
                    StatView(title: "騎友數", value: "\(userInfo.totalFriends)")
                    StatView(title: "總里程", value: String(format: "%.1f km", userInfo.totalLength))
                }
                .padding(.horizontal)
            } else {
                // Loading placeholder
                HStack {
                    ProgressView()
                    Text("載入使用者資訊...")
                }
                .padding()
            }
        }
        .frame(height: 180)
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RouteTypeRow: View {
    let type: RoutesType
    let routes: [Route]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            if let image = type.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
            }

            // Gradient overlay
            LinearGradient(
                colors: [Color.black.opacity(0.6), Color.clear],
                startPoint: .bottom,
                endPoint: .center
            )
            .frame(height: 200)

            // Text overlay
            VStack(alignment: .leading, spacing: 4) {
                Text(type.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("\(routes.count) 條路線")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding()
        }
        .frame(height: 200)
        .cornerRadius(12)
    }
}

