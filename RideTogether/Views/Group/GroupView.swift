//
//  GroupView.swift
//  RideTogether
//
//  Created by Auto on 2024/12/19.
//

import SwiftUI

struct GroupView: View {
    @Environment(\.repositories) private var repositories
    @StateObject private var viewModel: GroupViewModel
    @State private var searchText = ""
    @State private var showRequestsSheet = false

    init() {
        // Initialize with placeholder repository
        let placeholderRepo = GroupRepository()
        _viewModel = StateObject(wrappedValue: GroupViewModel(repository: placeholderRepo))
    }

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.groups.isEmpty {
                    // Loading state
                    ProgressView("載入中...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let errorMessage = viewModel.errorMessage, viewModel.groups.isEmpty {
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
                        // Requests Section
                        if !viewModel.getUnblockedRequests().isEmpty {
                            Section {
                                ForEach(viewModel.getUnblockedRequests(), id: \.self) { request in
                                    RequestRow(request: request, viewModel: viewModel)
                                }
                            } header: {
                                HStack {
                                    Text("加入申請")
                                    Spacer()
                                    Text("\(viewModel.getUnblockedRequests().count)")
                                        .foregroundColor(.blue)
                                }
                            }
                        }

                        // Groups Section
                        Section {
                            ForEach(viewModel.filteredGroups, id: \.groupId) { group in
                                GroupRow(group: group, viewModel: viewModel)
                            }
                        } header: {
                            Text("可用團隊")
                        }
                    }
                    .searchable(text: $searchText, prompt: "搜尋團隊名稱或路線")
                    .onChange(of: searchText) { newValue in
                        viewModel.filterGroups(searchText: newValue)
                    }
                    .refreshable {
                        viewModel.fetchGroups()
                    }
                }
            }
            .navigationTitle("群組")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showCreateGroupSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCreateGroupSheet) {
                CreateGroupView(viewModel: viewModel)
            }
            .onAppear {
                if viewModel.groups.isEmpty && !viewModel.isLoading {
                    viewModel.fetchGroups()
                    viewModel.startListening()
                }
            }
        }
    }
}

// MARK: - Request Row

struct RequestRow: View {
    let request: Request
    @ObservedObject var viewModel: GroupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.groupName)
                        .font(.headline)
                    Text("申請者: \(request.requestId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(request.createdTime.dateValue().formatted())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        viewModel.acceptRequest(request)
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }

                    Button {
                        viewModel.rejectRequest(request)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Group Row

struct GroupRow: View {
    let group: Group
    @ObservedObject var viewModel: GroupViewModel
    @State private var showActionSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.groupName)
                        .font(.headline)
                    Text(group.routeName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(spacing: 16) {
                        Label("\(group.userIds.count)/\(group.limit)", systemImage: "person.2.fill")
                            .font(.caption)
                        Label(group.date.dateValue().formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    if group.isExpired == true {
                        Text("已過期")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                }

                Spacer()

                Button {
                    showActionSheet = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }

            if !group.note.isEmpty {
                Text(group.note)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
        .confirmationDialog("團隊操作", isPresented: $showActionSheet) {
            if group.userIds.contains(UserManager.shared.userInfo.uid) {
                Button("離開團隊", role: .destructive) {
                    viewModel.leaveGroup(group)
                }
            } else if group.userIds.count < group.limit && group.isExpired != true {
                Button("申請加入") {
                    viewModel.sendJoinRequest(to: group)
                }
            }
            Button("取消", role: .cancel) {}
        }
    }
}

// MARK: - Create Group View

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GroupViewModel

    @State private var groupName = ""
    @State private var routeName = ""
    @State private var note = ""
    @State private var limit = 5
    @State private var selectedDate = Date()

    var body: some View {
        NavigationView {
            Form {
                Section("基本資訊") {
                    TextField("團隊名稱", text: $groupName)
                    TextField("路線名稱", text: $routeName)
                    Stepper("人數上限: \(limit)", value: $limit, in: 2...20)
                    DatePicker("出發時間", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                }

                Section("備註") {
                    TextEditor(text: $note)
                        .frame(height: 100)
                }
            }
            .navigationTitle("建立團隊")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("建立") {
                        createGroup()
                    }
                    .disabled(groupName.isEmpty || routeName.isEmpty)
                }
            }
        }
    }

    private func createGroup() {
        let userInfo = UserManager.shared.userInfo

        var group = Group()
        group.groupName = groupName
        group.routeName = routeName
        group.note = note
        group.limit = limit
        group.date = Timestamp(date: selectedDate)
        group.hostId = userInfo.uid
        group.userIds = [userInfo.uid]

        viewModel.createGroup(group)
        dismiss()
    }
}

