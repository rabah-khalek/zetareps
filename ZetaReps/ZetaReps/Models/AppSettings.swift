//
//  AppSettings.swift
//  ZetaReps
//
//  Created by Claude Code
//

import Foundation
import Combine

enum ReminderFrequency: String, CaseIterable, Codable {
    case hourly = "Hourly"
    case twiceDaily = "Twice Daily"
    case daily = "Daily"
    case custom = "Custom Times"
    case disabled = "Disabled"
}

enum FitnessLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var displayName: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .beginner:
            return "New to push-ups or building endurance"
        case .intermediate:
            return "Regular training, moderate strength"
        case .advanced:
            return "High strength and endurance"
        }
    }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard

    // Keys
    private let frequencyKey = "reminderFrequency"
    private let excludeWeekendsKey = "excludeWeekends"
    private let customTimesKey = "customTimes"
    private let defaultRepsKey = "defaultReps" // Legacy key for backward compatibility
    private let targetSetsKey = "targetSets"
    private let targetRepsPerSetKey = "targetRepsPerSet"
    private let restTimeSecondsKey = "restTimeSeconds"
    private let notificationsEnabledKey = "notificationsEnabled"
    private let scheduleRuleKey = "scheduleRule"
    private let targetWorkoutDaysKey = "targetWorkoutDays"
    private let useRecommendedStandardsKey = "useRecommendedStandards"
    private let fitnessLevelKey = "fitnessLevel"
    private let userAgeKey = "userAge"

    // Flag to prevent scheduling during initialization
    private var isInitializing = true

    // Reminder Frequency
    @Published var reminderFrequency: ReminderFrequency {
        didSet {
            defaults.set(reminderFrequency.rawValue, forKey: frequencyKey)
            if !isInitializing {
                NotificationManager.shared.scheduleReminders()
            }
        }
    }

    // Exclude Weekends
    @Published var excludeWeekends: Bool {
        didSet {
            defaults.set(excludeWeekends, forKey: excludeWeekendsKey)
            if !isInitializing {
                NotificationManager.shared.scheduleReminders()
            }
        }
    }

    // Custom Times (stored as array of hour components)
    @Published var customTimes: [DateComponents] {
        didSet {
            if let encoded = try? JSONEncoder().encode(customTimes) {
                defaults.set(encoded, forKey: customTimesKey)
                if !isInitializing {
                    NotificationManager.shared.scheduleReminders()
                }
            }
        }
    }

    // Target Sets Per Workout (standalone parameter)
    @Published var targetSets: Int {
        didSet {
            defaults.set(targetSets, forKey: targetSetsKey)
            // Update legacy defaultReps for backward compatibility
            defaults.set(targetSets * targetRepsPerSet, forKey: defaultRepsKey)
        }
    }
    
    // Target Reps Per Set (standalone parameter)
    @Published var targetRepsPerSet: Int {
        didSet {
            defaults.set(targetRepsPerSet, forKey: targetRepsPerSetKey)
            // Update legacy defaultReps for backward compatibility
            defaults.set(targetSets * targetRepsPerSet, forKey: defaultRepsKey)
        }
    }
    
    // Rest Time Between Sets (in seconds)
    @Published var restTimeSeconds: Int {
        didSet {
            defaults.set(restTimeSeconds, forKey: restTimeSecondsKey)
        }
    }
    
    // Legacy: Default Reps (calculated from sets × repsPerSet for backward compatibility)
    var defaultReps: Int {
        get {
            return targetSets * targetRepsPerSet
        }
        set {
            // When setting, distribute proportionally if both are set
            // Otherwise, default to a reasonable split
            if targetSets > 0 && targetRepsPerSet > 0 {
                // Try to maintain ratio or adjust reps per set
                let idealRepsPerSet = newValue / targetSets
                if idealRepsPerSet > 0 {
                    targetRepsPerSet = idealRepsPerSet
                }
            } else {
                // Default: 3 sets × 10 reps = 30 total
                targetSets = 3
                targetRepsPerSet = max(newValue / 3, 5)
            }
        }
    }

    // Target Workout Days Per Week (for consistency calculation)
    @Published var targetWorkoutDays: Int {
        didSet {
            defaults.set(targetWorkoutDays, forKey: targetWorkoutDaysKey)
        }
    }

    // Notifications Enabled
    @Published var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: notificationsEnabledKey)
            if notificationsEnabled {
                NotificationManager.shared.requestPermission { _ in }
            }
        }
    }

    // Current Schedule Rule (new granular scheduling system)
    @Published var currentScheduleRule: ScheduleRule? {
        didSet {
            if let rule = currentScheduleRule,
               let encoded = try? JSONEncoder().encode(rule) {
                defaults.set(encoded, forKey: scheduleRuleKey)
                if !isInitializing {
                    NotificationManager.shared.scheduleReminders()
                }
            } else {
                defaults.removeObject(forKey: scheduleRuleKey)
            }
        }
    }
    
    // Use Recommended Standards (toggle)
    @Published var useRecommendedStandards: Bool {
        didSet {
            defaults.set(useRecommendedStandards, forKey: useRecommendedStandardsKey)
            if useRecommendedStandards && !isInitializing {
                // Auto-update targets when toggling on
                updateRecommendedTargets()
            }
        }
    }
    
    // Fitness Level (for recommended standards)
    @Published var fitnessLevel: FitnessLevel {
        didSet {
            defaults.set(fitnessLevel.rawValue, forKey: fitnessLevelKey)
            if useRecommendedStandards && !isInitializing {
                updateRecommendedTargets()
            }
        }
    }
    
    // User Age (optional, for age-adjusted benchmarks)
    @Published var userAge: Int? {
        didSet {
            if let age = userAge {
                defaults.set(age, forKey: userAgeKey)
            } else {
                defaults.removeObject(forKey: userAgeKey)
            }
            if useRecommendedStandards && !isInitializing {
                updateRecommendedTargets()
            }
        }
    }
    
    // Computed: Get effective target sets per workout (either custom or recommended)
    var effectiveTargetSets: Int {
        return useRecommendedStandards ? RecommendedStandards.getTargetSets(for: fitnessLevel) : targetSets
    }
    
    // Computed: Get effective target reps per set (either custom or recommended)
    var effectiveTargetRepsPerSet: Int {
        return useRecommendedStandards ? RecommendedStandards.getTargetRepsPerSet(for: fitnessLevel) : targetRepsPerSet
    }
    
    // Computed: Get effective target total reps per workout (sets × reps per set)
    var effectiveTargetReps: Int {
        return effectiveTargetSets * effectiveTargetRepsPerSet
    }
    
    // Computed: Get effective target days (either custom or recommended)
    var effectiveTargetDays: Int {
        return useRecommendedStandards ? RecommendedStandards.getTargetDays(for: fitnessLevel) : targetWorkoutDays
    }
    
    // Computed: Get effective rest time between sets (minimum 30 seconds based on references)
    var effectiveRestTimeSeconds: Int {
        // Minimum rest time: 30 seconds (based on general fitness recommendations)
        // User can customize, but minimum is 30s
        return max(restTimeSeconds, 30)
    }
    
    // Update recommended targets based on fitness level
    private func updateRecommendedTargets() {
        targetSets = RecommendedStandards.getTargetSets(for: fitnessLevel)
        targetRepsPerSet = RecommendedStandards.getTargetRepsPerSet(for: fitnessLevel)
        targetWorkoutDays = RecommendedStandards.getTargetDays(for: fitnessLevel)
    }

    private init() {
        // Load saved values - initialize backing storage directly to avoid triggering didSet
        if let savedFrequency = defaults.string(forKey: frequencyKey),
           let frequency = ReminderFrequency(rawValue: savedFrequency) {
            _reminderFrequency = Published(initialValue: frequency)
        } else {
            _reminderFrequency = Published(initialValue: .daily)
        }

        _excludeWeekends = Published(initialValue: defaults.bool(forKey: excludeWeekendsKey))

        if let savedTimes = defaults.data(forKey: customTimesKey),
           let times = try? JSONDecoder().decode([DateComponents].self, from: savedTimes) {
            _customTimes = Published(initialValue: times)
        } else {
            // Default custom times: 9 AM and 6 PM
            _customTimes = Published(initialValue: [
                DateComponents(hour: 9, minute: 0),
                DateComponents(hour: 18, minute: 0)
            ])
        }

        // Load target sets (default: 3)
        let targetSetsValue = defaults.integer(forKey: targetSetsKey)
        _targetSets = Published(initialValue: targetSetsValue == 0 ? 3 : targetSetsValue)
        
        // Load target reps per set (default: 10)
        let targetRepsPerSetValue = defaults.integer(forKey: targetRepsPerSetKey)
        _targetRepsPerSet = Published(initialValue: targetRepsPerSetValue == 0 ? 10 : targetRepsPerSetValue)
        
        // Backward compatibility: if old defaultReps exists but new values don't, migrate
        let legacyDefaultReps = defaults.integer(forKey: defaultRepsKey)
        if legacyDefaultReps > 0 && targetSetsValue == 0 && targetRepsPerSetValue == 0 {
            // Migrate: split legacy reps into 3 sets
            let migratedSets = 3
            let migratedRepsPerSet = max(legacyDefaultReps / migratedSets, 5)
            _targetSets = Published(initialValue: migratedSets)
            _targetRepsPerSet = Published(initialValue: migratedRepsPerSet)
            defaults.set(migratedSets, forKey: targetSetsKey)
            defaults.set(migratedRepsPerSet, forKey: targetRepsPerSetKey)
        }
        
        // Load rest time (default: 60 seconds, minimum 30)
        let restTimeValue = defaults.integer(forKey: restTimeSecondsKey)
        _restTimeSeconds = Published(initialValue: restTimeValue == 0 ? 60 : max(restTimeValue, 30))

        let targetDaysValue = defaults.integer(forKey: targetWorkoutDaysKey) == 0 ? 5 : defaults.integer(forKey: targetWorkoutDaysKey)
        _targetWorkoutDays = Published(initialValue: targetDaysValue)

        _notificationsEnabled = Published(initialValue: defaults.bool(forKey: notificationsEnabledKey))
        
        // Load recommended standards settings
        _useRecommendedStandards = Published(initialValue: defaults.bool(forKey: useRecommendedStandardsKey))
        
        if let savedLevel = defaults.string(forKey: fitnessLevelKey),
           let level = FitnessLevel(rawValue: savedLevel) {
            _fitnessLevel = Published(initialValue: level)
        } else {
            _fitnessLevel = Published(initialValue: .beginner)
        }
        
        let savedAge = defaults.integer(forKey: userAgeKey)
        _userAge = Published(initialValue: savedAge > 0 ? savedAge : nil)

        // Load schedule rule if exists - initialize backing storage directly
        if let savedRule = defaults.data(forKey: scheduleRuleKey),
           let rule = try? JSONDecoder().decode(ScheduleRule.self, from: savedRule) {
            _currentScheduleRule = Published(initialValue: rule)
        } else {
            _currentScheduleRule = Published(initialValue: nil)
        }

        // Initialization complete - enable scheduling for future changes
        isInitializing = false
    }
}

// MARK: - Recommended Standards

struct RecommendedStandards {
    // Target days per week based on fitness level
    static func getTargetDays(for level: FitnessLevel) -> Int {
        switch level {
        case .beginner:
            // Beginner: 3-4 days/week (target: 3.5 rounded to 4)
            return 4
        case .intermediate:
            // Intermediate: 4-5 days/week (target: 4.5 rounded to 5)
            return 5
        case .advanced:
            // Advanced: 5-6 days/week (target: 5.5 rounded to 6)
            return 6
        }
    }
    
    // Target sets per workout based on fitness level
    static func getTargetSets(for level: FitnessLevel) -> Int {
        switch level {
        case .beginner:
            // Beginner: 2-3 sets (target: middle = 2.5 rounded to 3)
            return 3
        case .intermediate:
            // Intermediate: 3-4 sets (target: middle = 3.5 rounded to 4)
            return 4
        case .advanced:
            // Advanced: 4-5 sets (target: middle = 4.5 rounded to 5)
            return 5
        }
    }
    
    // Target reps per set based on fitness level
    static func getTargetRepsPerSet(for level: FitnessLevel) -> Int {
        switch level {
        case .beginner:
            // Beginner: 5-10 reps per set (target: middle = 7.5 rounded to 8)
            return 8
        case .intermediate:
            // Intermediate: 10-20 reps per set (target: middle = 15)
            return 15
        case .advanced:
            // Advanced: 20-40 reps per set (target: middle = 30)
            return 30
        }
    }
    
    // Target total reps per workout (sets × reps per set)
    static func getTargetRepsPerWorkout(for level: FitnessLevel) -> Int {
        return getTargetSets(for: level) * getTargetRepsPerSet(for: level)
    }
    
    // Legacy method for backward compatibility - returns total reps per workout
    static func getTargetReps(for level: FitnessLevel, age: Int? = nil) -> Int {
        return getTargetRepsPerWorkout(for: level)
    }
    
    // Legacy method for backward compatibility - returns days for intermediate level
    static func getTargetDays() -> Int {
        return getTargetDays(for: .intermediate)
    }
    
    // Get description of standards for info page
    static func getStandardsDescription() -> (frequency: String, setsReps: String, sources: [(name: String, url: String, description: String)]) {
        return (
            frequency: "Beginner: 3-4 days/week, Intermediate: 4-5 days/week, Advanced: 5-6 days/week",
            setsReps: """
            Beginner: 2-3 sets × 5-10 reps = 3-4 days/week (30-120 reps/week)
            Intermediate: 3-4 sets × 10-20 reps = 4-5 days/week (120-400 reps/week)
            Advanced: 4-5 sets × 20-40 reps = 5-6 days/week (400-1,200 reps/week)
            """,
            sources: [
                (name: "MedicineNet",
                 url: "https://www.medicinenet.com/how_many_push-ups_should_i_do_a_day/article.htm",
                 description: "Daily push-up recommendations"),
                (name: "Peloton",
                 url: "https://www.onepeloton.com/blog/correct-pushup-form/",
                 description: "Push-up form and technique"),
                (name: "The Citadel",
                 url: "https://www.citadel.edu/corps/physical-fitness/to-improve-push-ups/",
                 description: "Military fitness push-up improvement"),
                (name: "Healthline",
                 url: "https://www.healthline.com/health/fitness-exercise/muscles-worked-push-ups",
                 description: "Muscles worked by push-ups"),
                (name: "Marathon Handbook",
                 url: "https://marathonhandbook.com/how-many-push-ups-should-i-be-able-to-do/",
                 description: "Push-up capacity benchmarks"),
                (name: "Xcel Fitness",
                 url: "https://xcelfitness.com/how-many-push-ups-should-you-do-every-day-to-maximize-results/",
                 description: "Daily push-up volume optimization"),
                (name: "Tata AIG",
                 url: "https://www.tataaig.com/knowledge-center/health-insurance/how-many-pushups-should-i-do-a-day",
                 description: "Daily push-up frequency guidelines"),
                (name: "Fitness FAQs",
                 url: "https://fitnessfaqs.com/articles/7-best-intermediate-push-ups-for-next-level-strength/",
                 description: "Intermediate push-up progression")
            ]
        )
    }
}
