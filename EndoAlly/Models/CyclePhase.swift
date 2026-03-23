import Foundation
import SwiftUI

enum CyclePhase: String, CaseIterable {
    case menstruation = "Menstruation"
    case follicular   = "Follicular"
    case ovulation    = "Ovulation"
    case luteal       = "Luteal"

    var subtitle: String {
        switch self {
        case .menstruation: return "Your period is here"
        case .follicular:   return "Energy is building"
        case .ovulation:    return "Peak fertility window"
        case .luteal:       return "Winding down to your next period"
        }
    }

    var descriptions: [String] {
        switch self {
        case .menstruation: return ["Cramping likely", "Heavy flow possible", "Fatigue expected", "Lower back pain"]
        case .follicular:   return ["Energy returning", "Pain likely easing", "Mood improving"]
        case .ovulation:    return ["Mid-cycle pain possible", "Light spotting may occur", "Bloating common"]
        case .luteal:       return ["PMS symptoms likely", "Bloating may increase", "Mood changes expected", "Breast tenderness"]
        }
    }
}

struct CycleInfo {
    let day: Int
    let phase: CyclePhase
    let daysUntilNext: Int
    let progress: Double
    let lastPeriodStart: String
    let avgCycleLength: Int
    let avgPeriodLength: Int
    let ovulationCycleDay: Int
    let fertileStartDay: Int
    let fertileEndDay: Int
    let isIrregular: Bool
    let isOnPeriod: Bool
    let daysUntilOvulation: Int?
    let currentPeriodDay: Int?
}

// MARK: - Cycle calculation
func getPhase(cycleDay: Int, cycleLength: Int, periodLength: Int) -> CyclePhase {
    let follicularEnd = Int(Double(cycleLength) * 0.4)
    let ovulationEnd  = Int(Double(cycleLength) * 0.55)
    if cycleDay <= periodLength  { return .menstruation }
    if cycleDay <= follicularEnd { return .follicular }
    if cycleDay <= ovulationEnd  { return .ovulation }
    return .luteal
}

func todayString() -> String {
    let d = Date()
    let cal = Calendar.current
    let y = cal.component(.year, from: d)
    let m = cal.component(.month, from: d)
    let day = cal.component(.day, from: d)
    return String(format: "%04d-%02d-%02d", y, m, day)
}

func diffDays(_ a: String, _ b: String) -> Int {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    fmt.timeZone = TimeZone(identifier: "UTC")
    guard let da = fmt.date(from: a), let db = fmt.date(from: b) else { return 0 }
    return Int(db.timeIntervalSince(da) / 86400)
}

func addDays(_ dateStr: String, _ n: Int) -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    fmt.timeZone = TimeZone(identifier: "UTC")
    guard let d = fmt.date(from: dateStr) else { return dateStr }
    let new = d.addingTimeInterval(Double(n) * 86400)
    return fmt.string(from: new)
}

struct PeriodRecord {
    let start: String
    let end: String?
}

func detectPeriods(checkins: [(date: String, flow: String)]) -> [PeriodRecord] {
    guard !checkins.isEmpty else { return [] }

    let sorted = checkins.sorted { $0.date < $1.date }
    var byDate = [String: String]()
    for c in sorted { byDate[c.date] = c.flow }

    let flowDays: Set<String> = ["light", "medium", "heavy"]

    // Bridge single-day gaps
    var allDates = Set(sorted.map { $0.date })
    for c in sorted {
        let prev = addDays(c.date, -1)
        let next = addDays(c.date, 1)
        if let pf = byDate[prev], flowDays.contains(pf),
           let nf = byDate[next], flowDays.contains(nf),
           byDate[c.date] == nil {
            byDate[c.date] = "light"
            allDates.insert(c.date)
        }
    }

    let resolvedDates = allDates.sorted()
    var periods: [PeriodRecord] = []
    var inPeriod = false
    var periodStart: String?
    var periodEnd: String?
    var nonFlowStreak = 2

    for (i, date) in resolvedDates.enumerated() {
        let flow = byDate[date] ?? "none"
        let hasFlow = flowDays.contains(flow)

        if !inPeriod {
            if hasFlow && nonFlowStreak >= 2 {
                inPeriod = true
                periodStart = date
                nonFlowStreak = 0
            } else if !hasFlow {
                nonFlowStreak += 1
            } else {
                nonFlowStreak = 0
            }
        } else {
            if hasFlow {
                nonFlowStreak = 0
                periodEnd = date
            } else {
                let prev = i > 0 ? resolvedDates[i - 1] : nil
                if let prev = prev, diffDays(prev, date) >= 2 {
                    periods.append(PeriodRecord(start: periodStart!, end: periodEnd))
                    inPeriod = false; periodStart = nil; periodEnd = nil; nonFlowStreak = 1
                } else {
                    periods.append(PeriodRecord(start: periodStart!, end: periodEnd))
                    inPeriod = false; periodStart = nil; periodEnd = nil; nonFlowStreak = 1
                }
            }
        }
    }

    if inPeriod, let start = periodStart {
        periods.append(PeriodRecord(start: start, end: periodEnd))
    }
    return periods
}

func getSmartCycleInfo(
    checkins: [(date: String, flow: String)],
    profile: Profile
) -> CycleInfo? {
    let todayStr = todayString()
    let periods = detectPeriods(checkins: checkins)

    var avgCycleLength  = profile.cycleLength  ?? 28
    var avgPeriodLength = profile.periodLength ?? 5
    var lastPeriodStart: String? = nil
    var isIrregular = false

    if periods.count >= 1 {
        lastPeriodStart = periods.last!.start
    }

    if periods.count >= 2 {
        var cycleLengths = [Int]()
        for i in 1..<periods.count {
            cycleLengths.append(diffDays(periods[i-1].start, periods[i].start))
        }
        let sum = cycleLengths.reduce(0, +)
        avgCycleLength = max(21, min(45, sum / cycleLengths.count))

        let spread = (cycleLengths.max() ?? 0) - (cycleLengths.min() ?? 0)
        isIrregular = spread > 7

        let periodLengths: [Int] = periods.compactMap { p in
            guard let end = p.end else { return nil }
            return diffDays(p.start, end) + 1
        }
        if !periodLengths.isEmpty {
            let psum = periodLengths.reduce(0, +)
            avgPeriodLength = max(1, min(10, psum / periodLengths.count))
        }
    }

    if lastPeriodStart == nil { lastPeriodStart = profile.lastPeriodStart }
    guard let lps = lastPeriodStart else { return nil }

    let dayNum  = diffDays(lps, todayStr) + 1
    let day     = ((dayNum - 1) % avgCycleLength) + 1
    let phase   = getPhase(cycleDay: day, cycleLength: avgCycleLength, periodLength: avgPeriodLength)
    let daysUntilNext = avgCycleLength - day + 1
    let progress = Double(day) / Double(avgCycleLength)

    let ovulationCycleDay = max(avgCycleLength - 14, avgPeriodLength + 1)
    let fertileBuffer     = isIrregular ? 7 : 5
    let fertileStartDay   = max(ovulationCycleDay - fertileBuffer, avgPeriodLength + 1)
    let fertileEndDay     = ovulationCycleDay + 1
    let daysUntilOvulation: Int? = ovulationCycleDay >= day ? (ovulationCycleDay - day) : nil

    let todayCheckin = checkins.first(where: { $0.date == todayStr })
    let flowSet: Set<String> = ["light", "medium", "heavy"]
    let isOnPeriod: Bool
    if let tc = todayCheckin {
        isOnPeriod = flowSet.contains(tc.flow)
    } else {
        isOnPeriod = day <= avgPeriodLength
    }

    var currentPeriodDay: Int? = nil
    if isOnPeriod {
        if let last = periods.last {
            currentPeriodDay = diffDays(last.start, todayStr) + 1
        } else {
            currentPeriodDay = day
        }
    }

    return CycleInfo(
        day: day,
        phase: phase,
        daysUntilNext: daysUntilNext,
        progress: progress,
        lastPeriodStart: lps,
        avgCycleLength: avgCycleLength,
        avgPeriodLength: avgPeriodLength,
        ovulationCycleDay: ovulationCycleDay,
        fertileStartDay: fertileStartDay,
        fertileEndDay: fertileEndDay,
        isIrregular: isIrregular,
        isOnPeriod: isOnPeriod,
        daysUntilOvulation: daysUntilOvulation,
        currentPeriodDay: currentPeriodDay
    )
}
