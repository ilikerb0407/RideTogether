//
//  JourneyView.swift
//  RideTogether
//
//  Created by Auto on 2024/12/19.
//

import SwiftUI
import MapKit
import CoreLocation

struct JourneyView: View {
    @StateObject private var viewModel: JourneyViewModel

    init() {
        // Initialize with repositories
        let locationRepo = LocationRepository()
        let recordRepo = RecordRepository()
        _viewModel = StateObject(wrappedValue: JourneyViewModel(
            locationRepository: locationRepo,
            recordRepository: recordRepo
        ))
    }

    var body: some View {
        ZStack {
            // Map
            let points: [MapPoint] = [
                MapPoint(coordinate: viewModel.mapRegion.center)
            ]

            Map(coordinateRegion: $viewModel.mapRegion,
                showsUserLocation: true,
                annotationItems: points
            ) { point in
                MapPin(coordinate: point.coordinate)
            }
            .ignoresSafeArea()

            // Overlay UI
            VStack {
                // Top Stats Card
                if viewModel.isRecording {
                    StatsCard(viewModel: viewModel)
                        .padding(.top, 60)
                        .padding(.horizontal)
                }

                Spacer()

                // Bottom Controls
                VStack(spacing: 16) {
                    // Speed Display
                    if viewModel.isRecording {
                        SpeedDisplay(speed: viewModel.formattedCurrentSpeed)
                    }

                    // Recording Controls
                    RecordingControls(viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                }
            }

            // Loading Overlay
            if viewModel.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView("上傳中...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
        .alert("需要定位權限", isPresented: $viewModel.showPermissionAlert) {
            Button("前往設定") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("請在設定中允許 RideTogether 存取您的位置資訊以記錄騎乘軌跡")
        }
        .alert("儲存紀錄", isPresented: $viewModel.showSaveDialog) {
            TextField("檔案名稱", text: $viewModel.recordingFileName)
            Button("儲存") {
                viewModel.saveRecording(fileName: viewModel.recordingFileName)
            }
            Button("捨棄", role: .destructive) {
                viewModel.discardRecording()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("是否要儲存這次的騎乘紀錄？")
        }
        .onAppear {
            if viewModel.authorizationStatus == .notDetermined {
                viewModel.requestLocationPermission()
            }
        }
    }
}

// MARK: - Stats Card

struct StatsCard: View {
    @ObservedObject var viewModel: JourneyViewModel

    var body: some View {
        HStack(spacing: 20) {
            StatItem(title: "距離", value: viewModel.formattedDistance, icon: "arrow.left.and.right")
            StatItem(title: "時間", value: viewModel.formattedDuration, icon: "clock.fill")
            StatItem(title: "平均速度", value: viewModel.formattedAverageSpeed, icon: "speedometer")
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .cornerRadius(16)
        .shadow(radius: 8)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Speed Display

struct SpeedDisplay: View {
    let speed: String

    var body: some View {
        VStack(spacing: 4) {
            Text(speed)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            Text("當前速度")
                .font(.caption)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - Recording Controls

struct RecordingControls: View {
    @ObservedObject var viewModel: JourneyViewModel

    var body: some View {
        HStack(spacing: 20) {
            if !viewModel.isRecording {
                // Start Button
                Button {
                    viewModel.startRecording()
                } label: {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                        Text("開始記錄")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                    .shadow(radius: 4)
                }
            } else {
                // Pause/Resume Button
                Button {
                    if viewModel.isPaused {
                        viewModel.resumeRecording()
                    } else {
                        viewModel.pauseRecording()
                    }
                } label: {
                    Image(systemName: viewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                        .shadow(radius: 4)
                }

                // Stop Button
                Button {
                    viewModel.stopRecording()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                        .shadow(radius: 4)
                }
            }

            // Center Location Button
            Button {
                viewModel.centerOnCurrentLocation()
            } label: {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .cornerRadius(16)
        .shadow(radius: 8)
    }
}

struct MapPoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
