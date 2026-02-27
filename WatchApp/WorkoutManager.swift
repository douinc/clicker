import HealthKit

/// Manages an HKWorkoutSession to keep the app frontmost during presentations.
/// Without an active workout session, watchOS dismisses apps on wrist-down.
class WorkoutManager: NSObject, ObservableObject, HKWorkoutSessionDelegate {
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    @Published var isActive = false

    func start() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard session == nil else { return }

        let typesToShare: Set<HKSampleType> = [HKObjectType.workoutType()]
        healthStore.requestAuthorization(toShare: typesToShare, read: nil) { [weak self] success, _ in
            guard success else { return }
            DispatchQueue.main.async {
                self?.startSession()
            }
        }
    }

    private func startSession() {
        guard session == nil else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .indoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            session?.delegate = self
            session?.startActivity(with: Date())
            isActive = true
        } catch {
            print("⌚ Failed to start workout session: \(error)")
        }
    }

    func stop() {
        session?.end()
        session = nil
        isActive = false
    }

    // MARK: - HKWorkoutSessionDelegate

    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.isActive = toState == .running
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("⌚ Workout session error: \(error)")
        DispatchQueue.main.async {
            self.isActive = false
            self.session = nil
        }
    }
}
