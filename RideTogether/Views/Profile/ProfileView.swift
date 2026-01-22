//
//  ProfileView.swift
//  RideTogether
//
//  Created by Auto on 2024/12/19.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @Environment(\.repositories) private var repositories
    @EnvironmentObject private var authState: AuthStateManager
    @StateObject private var viewModel: ProfileViewModel

    init() {
        // Initialize with placeholder - will use environment repositories
        let userRepo = UserRepository()
        let recordRepo = RecordRepository()
        let authManager = AuthStateManager()
        _viewModel = StateObject(wrappedValue: ProfileViewModel(
            userRepository: userRepo,
            recordRepository: recordRepo,
            authStateManager: authManager
        ))
    }

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    // Profile Header
                    Section {
                        ProfileHeaderView(viewModel: viewModel)
                    } header: {
                        EmptyView()
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    // Stats Section
                    Section {
                        StatsSection(viewModel: viewModel)
                    } header: {
                        Text("統計資料")
                    }

                    // Menu Items
                    ForEach(ProfileItemType.allCases, id: \.self) { item in
                        Section {
                            ProfileMenuItem(item: item, viewModel: viewModel)
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
                    viewModel.fetchRecords()
                }

                // Loading overlay
                if viewModel.isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("個人")
            .alert("錯誤", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("確定") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .sheet(isPresented: $viewModel.showEditProfile) {
                EditProfileView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Profile Header

struct ProfileHeaderView: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Profile photo
            if let pictureRef = viewModel.userInfo?.pictureRef, !pictureRef.isEmpty {
                AsyncImage(url: URL(string: pictureRef)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }

            // User name
            Text(viewModel.userInfo?.userName ?? "破風手")
                .font(.title2)
                .fontWeight(.bold)

            // Edit button
            Button {
                viewModel.showEditProfile = true
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("編輯個人資料")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Stats Section

struct StatsSection: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        HStack(spacing: 20) {
            StatCard(title: "總里程", value: viewModel.formattedTotalDistance, icon: "arrow.left.and.right")
            StatCard(title: "騎乘次數", value: "\(viewModel.totalRecordings)", icon: "bicycle")
            StatCard(title: "團數", value: viewModel.formattedTotalGroups, icon: "person.3")
        }
        .padding(.vertical, 8)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(12)
    }
}

// MARK: - Profile Menu Item

struct ProfileMenuItem: View {
    let item: ProfileItemType
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showRecords = false
    @State private var showAccountSettings = false

    var body: some View {
        Button(action: {
            handleItemTap()
        }) {
            HStack {
                if let image = item.image {
                    Image(uiImage: image)
                        .foregroundColor(Color.B5)
                }
                Text(item.title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(height: 60)
        }
        .sheet(isPresented: $showAccountSettings) {
            AccountSettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showRecords) {
            RecordsListView(viewModel: viewModel)
        }
    }

    private func handleItemTap() {
        switch item {
        case .routeRecord:
            showRecords = true
        case .recommendMap:
            // Navigate to shared maps wall
            break
        case .userAccount:
            showAccountSettings = true
        case .saveRoutes:
            // Navigate to saved routes
            break
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        NavigationView {
            Form {
                Section("個人資料") {
                    TextField("名稱", text: $viewModel.editedUserName)
                }

                Section("大頭貼") {
                    Button {
                        viewModel.showImagePicker = true
                    } label: {
                        HStack {
                            Text("選擇照片")
                            Spacer()
                            if let image = viewModel.selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
            }
            .navigationTitle("編輯個人資料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        saveChanges()
                    }
                }
            }
        }
    }

    private func saveChanges() {
        if let image = viewModel.selectedImage {
            viewModel.uploadProfilePicture(image)
        }
        if viewModel.editedUserName != viewModel.userInfo?.userName {
            viewModel.updateUserName(viewModel.editedUserName)
        }
    }
}

// MARK: - Records List View

struct RecordsListView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.records, id: \.recordId) { record in
                    RecordRow(record: record, viewModel: viewModel)
                }
            }
            .navigationTitle("騎乘紀錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.fetchRecords()
            }
        }
    }
}

struct RecordRow: View {
    let record: Record
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.recordName)
                    .font(.headline)
                Text(record.createdTime.dateValue().formatted())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                viewModel.deleteRecord(record)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Account Settings View

struct AccountSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationView {
            List {
                Button("登出帳號") {
                    viewModel.signOut()
                    dismiss()
                }
                .foregroundColor(.blue)

                Button("刪除帳號") {
                    showDeleteConfirmation = true
                }
                .foregroundColor(.red)
            }
            .navigationTitle("帳戶設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("確定要刪除帳號？", isPresented: $showDeleteConfirmation) {
                Button("取消", role: .cancel) {}
                Button("刪除", role: .destructive) {
                    viewModel.deleteAccount { success in
                        if success {
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("此操作無法復原，所有資料將被永久刪除")
            }
        }
    }
}

