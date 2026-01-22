# RideTogether MVVM + Combine Refactoring Progress

**Last Updated:** 2026-01-23
**Status:** Phase 4 Complete ✅ | Phase 5-7 Remaining

---

## ✅ COMPLETED PHASES (1-4)

### Phase 1: Foundation Infrastructure ✅
**Goal:** Create core Combine infrastructure

**Completed Files:**
- ✅ `RideTogether/Repositories/FirestorePublisher.swift` - Custom Publisher with proper ListenerRegistration management
- ✅ `RideTogether/Repositories/RepositoryError.swift` - Unified error handling
- ✅ `RideTogether/Repositories/RepositoryContainer.swift` - Dependency injection container
- ✅ `RideTogether/Repositories/UserRepository.swift` - User operations with Combine
- ✅ `RideTogether/Managers/AuthStateManager.swift` - REFACTORED to use UserRepository + Combine

**Key Achievement:** Eliminated dual state management, replaced callbacks with Combine

---

### Phase 2: Home Feature ✅
**Goal:** Complete Home feature with MVVM + Combine

**Completed Files:**
- ✅ `RideTogether/Repositories/MapsRepository.swift` - Routes/Records with Combine
- ✅ `RideTogether/ViewModels/HomeViewModel.swift` - MVVM implementation
- ✅ `RideTogether/Views/Home/HomeView.swift` - Enhanced UI with loading/error states

**Key Achievement:** Home feature now fully reactive with proper state management

---

### Phase 3: Group Feature (CRITICAL MEMORY LEAK FIX) ✅
**Goal:** Fix GroupManager memory leak with Combine Publishers

**Completed Files:**
- ✅ `RideTogether/Repositories/GroupRepository.swift` - **FIXES MEMORY LEAK**
  - Old: `GroupManager.addRequestListener` (lines 148-179) never cancelled listeners
  - New: `observeRequests()` uses `FirestorePublisher` with proper cleanup
- ✅ `RideTogether/ViewModels/GroupViewModel.swift` - Full MVVM implementation
- ✅ `RideTogether/Views/MainTabView.swift` - Refactored GroupBadgeViewModel with Combine
- ✅ `RideTogether/Views/Group/GroupView.swift` - Complete UI with groups & requests

**Key Achievement:** Critical memory leak FIXED - Firestore listeners now properly cancelled

---

### Phase 4: Journey Feature - GPS & Recording ✅
**Goal:** Implement journey recording with location tracking

**Completed Files:**
- ✅ `RideTogether/Repositories/LocationRepository.swift` - CLLocationManager wrapped with Combine
  - `observeLocationUpdates()` - Real-time location publisher
  - `observeAuthorizationStatus()` - Permission status publisher
  - Proper delegation with PassthroughSubject
- ✅ `RideTogether/Repositories/RecordRepository.swift` - Recording operations with Combine
  - `uploadRecord()` - Upload GPX files to Firebase Storage
  - `uploadGPXData()` - Direct data upload with metadata
  - `deleteRecord()` - Delete from Storage and Firestore
- ✅ `RideTogether/ViewModels/JourneyViewModel.swift` - Complete GPS tracking logic
  - Real-time location tracking with Combine
  - Distance, duration, speed calculations
  - GPX file generation
  - Recording state management (start/pause/stop)
- ✅ `RideTogether/Views/Journey/JourneyView.swift` - Full UI implementation
  - SwiftUI Map with user location
  - Stats card (distance, time, average speed)
  - Recording controls (start, pause, resume, stop)
  - Current speed display
  - Save dialog with filename input
- ✅ `RideTogether/Repositories/RepositoryContainer.swift` - Updated with LocationRepository and RecordRepository

**Key Achievement:** Complete GPS tracking and recording system with reactive Combine publishers

---

## 🚧 REMAINING PHASES (5-7)

### Phase 4: Journey Feature - GPS & Recording
**Goal:** Implement journey recording with location tracking

**Files to Create:**
1. `RideTogether/Repositories/LocationRepository.swift`
   ```swift
   protocol LocationRepositoryProtocol {
       func observeLocationUpdates() -> AnyPublisher<CLLocation, Error>
       func requestLocationPermission() -> AnyPublisher<Bool, Error>
   }
   // Wrap LocationManager with Combine Publishers
   ```

2. `RideTogether/Repositories/RecordRepository.swift`
   ```swift
   protocol RecordRepositoryProtocol {
       func fetchRecords() -> AnyPublisher<[Record], Error>
       func uploadRecord(_ record: Record) -> AnyPublisher<URL, Error>
       func deleteRecord(_ recordId: String) -> AnyPublisher<Void, Error>
   }
   ```

3. `RideTogether/ViewModels/JourneyViewModel.swift`
   ```swift
   class JourneyViewModel: ObservableObject {
       @Published var currentLocation: CLLocation?
       @Published var isRecording = false
       @Published var trackingData: [CLLocation] = []
       @Published var distance: Double = 0

       func startRecording()
       func stopRecording()
       func saveRecording()
       func generateGPX() -> String
   }
   ```

4. `RideTogether/Views/Journey/JourneyView.swift` - MODIFY
   - Add map display with real-time location
   - Recording controls (start/stop/pause)
   - Stats display (distance, time, speed)
   - Save/upload functionality

**Reference Files:**
- `/RideTogether/Manager/LocationManager.swift` - Existing location logic
- `/RideTogether/Manager/RecordManager.swift` - Existing record logic

**Update RepositoryContainer:**
```swift
let locationRepository: LocationRepositoryProtocol
let recordRepository: RecordRepositoryProtocol
```

---

### Phase 5: Profile Feature - User Management
**Goal:** Complete user profile with statistics

**Files to Create:**
1. `RideTogether/ViewModels/ProfileViewModel.swift`
   ```swift
   class ProfileViewModel: ObservableObject {
       @Published var userInfo: UserInfo?
       @Published var records: [Record] = []
       @Published var isLoading = false

       func updateProfile(name: String)
       func uploadProfilePicture(_ imageData: Data)
       func fetchUserRecords()
       func logout()
       func deleteAccount()
   }
   ```

2. `RideTogether/Views/Profile/ProfileView.swift` - MODIFY
   - Display user info and stats
   - Profile editing functionality
   - Record history display
   - Settings (logout, delete account)

**Dependencies:**
- Uses `UserRepository` (already created in Phase 1)
- Uses `RecordRepository` (created in Phase 4)

---

### Phase 6: Additional Features & Optimization
**Goal:** Complete remaining features and optimize

**Files to Create:**
1. `RideTogether/Repositories/WeatherRepository.swift`
   ```swift
   protocol WeatherRepositoryProtocol {
       func fetchWeather(for location: CLLocation) -> AnyPublisher<WeatherData, Error>
   }
   // Wrap WeatherManager with Combine
   ```

2. `RideTogether/Repositories/UBikeRepository.swift`
   ```swift
   protocol UBikeRepositoryProtocol {
       func fetchNearbyStations(location: CLLocation) -> AnyPublisher<[BikeStation], Error>
   }
   // Wrap UbikeManager with Combine
   ```

**Optimization Tasks:**
- Add `.share()` operator to expensive Publishers (e.g., fetchRoutes)
- Add `.retry()` for network operations
- Add `.catch()` for graceful error recovery
- Run Instruments to verify no memory leaks
- Performance testing (launch time, memory usage)

**Reference Files:**
- `/RideTogether/Manager/WeatherManager.swift`
- `/RideTogether/Manager/UbikeManager.swift`

---

### Phase 7: Cleanup & Deprecation
**Goal:** Remove legacy code and finalize migration

**Files to DELETE:**
```
RideTogether/ViewController/Home/HomeViewController.swift
RideTogether/ViewController/Group/GroupViewController.swift
RideTogether/ViewController/Journey/JourneyViewController.swift
RideTogether/ViewController/Profile/ProfileViewController.swift
RideTogether/ViewController/TabBarController.swift
```
(Keep LoginViewController, SignUpViewController, PolicyViewController as backup)

**Files to UPDATE:**
- Mark deprecated methods in Managers with `@available(*, deprecated)`
- Remove unused imports
- Clean up commented code
- Run SwiftLint
- Update README.md with new architecture

**Final Testing:**
- Full regression testing of all features
- Memory leak testing with Instruments
- Verify no functionality lost
- Test all user flows end-to-end

---

## 📋 QUICK REFERENCE: Key Patterns

### 1. Repository Pattern
```swift
protocol ExampleRepositoryProtocol {
    func fetchData() -> AnyPublisher<[Data], Error>
}

class ExampleRepository: ExampleRepositoryProtocol {
    private let manager: ExampleManager

    func fetchData() -> AnyPublisher<[Data], Error> {
        Future { [weak self] promise in
            self?.manager.fetchData { result in
                promise(result)
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
```

### 2. ViewModel Pattern
```swift
class ExampleViewModel: ObservableObject {
    @Published var data: [Data] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: ExampleRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(repository: ExampleRepositoryProtocol) {
        self.repository = repository
    }

    func fetchData() {
        isLoading = true
        repository.fetchData()
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            })
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] data in
                    self?.data = data
                }
            )
            .store(in: &cancellables)
    }

    deinit {
        cancellables.removeAll()
    }
}
```

### 3. View Pattern
```swift
struct ExampleView: View {
    @Environment(\.repositories) private var repositories
    @StateObject private var viewModel: ExampleViewModel

    init() {
        let repo = ExampleRepository()
        _viewModel = StateObject(wrappedValue: ExampleViewModel(repository: repo))
    }

    var body: some View {
        // UI implementation
    }
}
```

### 4. Real-time Listener Pattern (CRITICAL for preventing memory leaks)
```swift
// Use FirestorePublisher for real-time updates
func observeData() -> AnyPublisher<[Data], Error> {
    let query = db.collection("data")
    return FirestorePublisher<Data>(query: query)
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    // FirestorePublisher automatically cancels listener when subscription ends
}
```

---

## 🔧 HOW TO CONTINUE IMPLEMENTATION

### Step 1: Add Repository to Container
Edit `RideTogether/Repositories/RepositoryContainer.swift`:
```swift
let newRepository: NewRepositoryProtocol

init(newRepository: NewRepositoryProtocol? = nil) {
    self.newRepository = newRepository ?? NewRepository()
}
```

### Step 2: Create ViewModel with Dependency Injection
```swift
class NewViewModel: ObservableObject {
    private let repository: NewRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(repository: NewRepositoryProtocol) {
        self.repository = repository
    }
}
```

### Step 3: Update View to Use ViewModel
```swift
struct NewView: View {
    @StateObject private var viewModel: NewViewModel

    init() {
        let repo = NewRepository()
        _viewModel = StateObject(wrappedValue: NewViewModel(repository: repo))
    }
}
```

---

## 📊 TESTING CHECKLIST

After each phase:
- [ ] Build succeeds without errors
- [ ] Feature works as expected
- [ ] No console errors or warnings
- [ ] Run Instruments to check for memory leaks
- [ ] Test on simulator (verify UI responsiveness)
- [ ] Verify Firestore listeners are properly cancelled

Final testing:
- [ ] All features working end-to-end
- [ ] Memory leaks checked with Instruments
- [ ] No crashes or console errors
- [ ] UI is responsive (60fps)
- [ ] Login/logout flows work correctly
- [ ] Real-time updates work (badge counts, groups, etc.)

---

## 🚨 CRITICAL NOTES

1. **ALWAYS use FirestorePublisher for real-time listeners** - prevents memory leaks
2. **ALWAYS use `Set<AnyCancellable>`** in ViewModels and clean up in deinit
3. **ALWAYS use `.receive(on: DispatchQueue.main)`** for UI updates (not manual DispatchQueue.main.async)
4. **NEVER call Manager.shared directly from Views** - use Repository → ViewModel → View
5. **Test with Instruments after each phase** - memory leaks are easy to introduce

---

## 📁 PROJECT STRUCTURE

```
RideTogether/
├── Repositories/          ✅ Phase 1-3 complete
│   ├── FirestorePublisher.swift
│   ├── RepositoryError.swift
│   ├── RepositoryContainer.swift
│   ├── UserRepository.swift
│   ├── MapsRepository.swift
│   └── GroupRepository.swift
│   └── LocationRepository.swift      🚧 TODO: Phase 4
│   └── RecordRepository.swift        🚧 TODO: Phase 4
│   └── WeatherRepository.swift       🚧 TODO: Phase 6
│   └── UBikeRepository.swift         🚧 TODO: Phase 6
├── ViewModels/            ✅ Phase 1-3 complete
│   ├── HomeViewModel.swift
│   └── GroupViewModel.swift
│   └── JourneyViewModel.swift        🚧 TODO: Phase 4
│   └── ProfileViewModel.swift        🚧 TODO: Phase 5
├── Views/
│   ├── Home/              ✅ Complete
│   ├── Group/             ✅ Complete
│   ├── Journey/           🚧 TODO: Phase 4
│   └── Profile/           🚧 TODO: Phase 5
├── Managers/              ⚠️ Keep for backward compatibility
└── Model/                 ✅ No changes needed
```

---

## 💡 WHAT TO DO IF SERVICE STOPS

1. **Read this file** to understand current progress
2. **Check the TODO list** in the code for pending tasks
3. **Continue from Phase 4** (Journey feature)
4. **Follow the patterns** documented in Quick Reference section
5. **Test after each file creation** to ensure no regressions
6. **Refer to existing files** as examples:
   - UserRepository.swift (simple repository)
   - GroupRepository.swift (real-time listener repository)
   - HomeViewModel.swift (simple ViewModel)
   - GroupViewModel.swift (complex ViewModel with CRUD)

---

**Remember:** The hardest part (memory leak fix) is DONE. Remaining phases follow the same patterns established in Phases 1-3.
