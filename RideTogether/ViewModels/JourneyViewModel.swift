//
//  JourneyViewModel.swift
//  RideTogether
//
//  Created by Auto on 2026/01/23.
//

import Combine
import CoreLocation
import Foundation
import MapKit

/// ViewModel for Journey feature following MVVM + Combine architecture
/// Manages GPS tracking, recording, and GPX file generation
final class JourneyViewModel: ObservableObject {
    // MARK: - Published Properties

    // Location tracking
    @Published var currentLocation: CLLocation?
    @Published var trackingPoints: [CLLocation] = []
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25.042393, longitude: 121.56496),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    // Recording state
    @Published var isRecording = false
    @Published var isPaused = false

    // Stats
    @Published var distance: Double = 0 // in meters
    @Published var duration: TimeInterval = 0
    @Published var averageSpeed: Double = 0 // km/h
    @Published var currentSpeed: Double = 0 // km/h

    // Authorization
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var showPermissionAlert = false

    // UI state
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSaveDialog = false
    @Published var recordingFileName = ""

    // MARK: - Dependencies
    private let locationRepository: LocationRepositoryProtocol
    private let recordRepository: RecordRepositoryProtocol

    // MARK: - Private Properties
    private var recordingStartTime: Date?
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init (Dependency Injection)
    init(
        locationRepository: LocationRepositoryProtocol,
        recordRepository: RecordRepositoryProtocol
    ) {
        self.locationRepository = locationRepository
        self.recordRepository = recordRepository

        setupLocationObserver()
        setupAuthorizationObserver()
    }

    // MARK: - Public Methods

    /// Request location permission
    func requestLocationPermission() {
        locationRepository.requestLocationPermission()
    }

    /// Start recording GPS track
    func startRecording() {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            showPermissionAlert = true
            return
        }

        isRecording = true
        isPaused = false
        recordingStartTime = Date()
        trackingPoints.removeAll()
        distance = 0
        duration = 0

        locationRepository.startUpdatingLocation()
        startTimer()
    }

    /// Pause recording
    func pauseRecording() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }

    /// Resume recording
    func resumeRecording() {
        isPaused = false
        startTimer()
    }

    /// Stop recording and prompt to save
    func stopRecording() {
        isRecording = false
        isPaused = false
        timer?.invalidate()
        timer = nil

        locationRepository.stopUpdatingLocation()

        if !trackingPoints.isEmpty {
            // Generate default filename
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm"
            recordingFileName = "Ride_\(formatter.string(from: Date())).gpx"
            showSaveDialog = true
        }
    }

    /// Save recording to Firebase
    func saveRecording(fileName: String) {
        guard !trackingPoints.isEmpty else {
            errorMessage = "沒有追蹤點可以儲存"
            return
        }

        isLoading = true
        errorMessage = nil

        // Generate GPX data
        let gpxString = generateGPX(fileName: fileName)
        guard let gpxData = gpxString.data(using: .utf8) else {
            errorMessage = "無法產生 GPX 檔案"
            isLoading = false
            return
        }

        // Upload to Firebase
        recordRepository.uploadGPXData(gpxData, fileName: fileName)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "上傳失敗: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] url in
                    print("Recording saved successfully: \(url)")
                    self?.errorMessage = "紀錄已儲存"
                    self?.showSaveDialog = false

                    // Update user's total length
                    let distanceKm = (self?.distance ?? 0) / 1000.0
                    self?.updateUserTotalLength(distanceKm)

                    // Reset tracking data
                    self?.trackingPoints.removeAll()
                    self?.distance = 0
                    self?.duration = 0
                }
            )
            .store(in: &cancellables)
    }

    /// Discard recording without saving
    func discardRecording() {
        trackingPoints.removeAll()
        distance = 0
        duration = 0
        showSaveDialog = false
    }

    /// Center map on current location
    func centerOnCurrentLocation() {
        if let location = currentLocation {
            mapRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }

    // MARK: - Private Methods

    private func setupLocationObserver() {
        locationRepository.observeLocationUpdates()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "定位錯誤: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] location in
                    self?.handleLocationUpdate(location)
                }
            )
            .store(in: &cancellables)
    }

    private func setupAuthorizationObserver() {
        locationRepository.observeAuthorizationStatus()
            .sink { [weak self] status in
                self?.authorizationStatus = status
            }
            .store(in: &cancellables)
    }

    private func handleLocationUpdate(_ location: CLLocation) {
        currentLocation = location
        currentSpeed = location.speed * 3.6 // Convert m/s to km/h

        // Update map region to follow user
        if isRecording && !isPaused {
            mapRegion.center = location.coordinate
        }

        // Add to tracking points if recording
        if isRecording && !isPaused {
            // Calculate distance from last point
            if let lastPoint = trackingPoints.last {
                let distanceFromLast = location.distance(from: lastPoint)
                distance += distanceFromLast
            }

            trackingPoints.append(location)

            // Calculate average speed
            if duration > 0 {
                averageSpeed = (distance / duration) * 3.6 // Convert m/s to km/h
            }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }
            self.duration += 1
        }
    }

    private func generateGPX(fileName: String) -> String {
        let dateFormatter = ISO8601DateFormatter()

        var gpxString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="RideTogether"
             xmlns="http://www.topografix.com/GPX/1/1"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
          <metadata>
            <name>\(fileName)</name>
            <time>\(dateFormatter.string(from: Date()))</time>
          </metadata>
          <trk>
            <name>\(fileName)</name>
            <trkseg>
        """

        for point in trackingPoints {
            let timestamp = dateFormatter.string(from: point.timestamp)
            let lat = point.coordinate.latitude
            let lon = point.coordinate.longitude
            let elevation = point.altitude

            gpxString += """
                  <trkpt lat="\(lat)" lon="\(lon)">
                    <ele>\(elevation)</ele>
                    <time>\(timestamp)</time>
                  </trkpt>

            """
        }

        gpxString += """
            </trkseg>
          </trk>
        </gpx>
        """

        return gpxString
    }

    private func updateUserTotalLength(_ distanceKm: Double) {
        // This would typically go through UserRepository
        // For now, just print
        print("User rode \(distanceKm) km")
    }

    // MARK: - Computed Properties

    var formattedDistance: String {
        let km = distance / 1000.0
        return String(format: "%.2f km", km)
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var formattedAverageSpeed: String {
        return String(format: "%.1f km/h", averageSpeed)
    }

    var formattedCurrentSpeed: String {
        let speed = max(0, currentSpeed) // Don't show negative speeds
        return String(format: "%.1f km/h", speed)
    }

    // MARK: - Deinit
    deinit {
        timer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - Factory
extension JourneyViewModel {
    /// Create JourneyViewModel with repositories from container
    static func create(
        locationRepository: LocationRepositoryProtocol,
        recordRepository: RecordRepositoryProtocol
    ) -> JourneyViewModel {
        JourneyViewModel(
            locationRepository: locationRepository,
            recordRepository: recordRepository
        )
    }
}
