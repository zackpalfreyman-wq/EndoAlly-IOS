import SwiftUI

struct CycleRingView: View {
    let cycleInfo: CycleInfo

    private var phase: CyclePhase { cycleInfo.phase }
    private var color: Color { phaseColor(for: phase) }

    var body: some View {
        CardView(backgroundColor: color.opacity(0.09)) {
            VStack(alignment: .leading, spacing: 16) {
                // Top row: phase info + ring
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(phase.rawValue.uppercased())
                            .font(.custom("DMSans-Bold", size: 10).leading(.tight))
                            .tracking(1.2)
                            .foregroundColor(color)
                        Text(phase.subtitle)
                            .font(.custom("DMSans-SemiBold", size: 22))
                            .foregroundColor(color)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    SmallCycleRing(cycleInfo: cycleInfo)
                        .frame(width: 96, height: 96)
                }

                // Phase description bullets
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(phase.descriptions.prefix(3), id: \.self) { desc in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(color)
                                .frame(width: 6, height: 6)
                            Text(desc)
                                .font(.custom("DMSans-Medium", size: 13))
                                .foregroundColor(.charcoal)
                        }
                    }
                    if cycleInfo.day >= cycleInfo.fertileStartDay && cycleInfo.day <= cycleInfo.fertileEndDay {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.phaseGold)
                                .frame(width: 6, height: 6)
                            Text("Fertile window active")
                                .font(.custom("DMSans-SemiBold", size: 13))
                                .foregroundColor(.charcoal)
                        }
                    }
                    if cycleInfo.isIrregular {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.slateMid)
                                .frame(width: 6, height: 6)
                            Text("Cycles appear irregular — predictions are estimates")
                                .font(.custom("DMSans-Regular", size: 13))
                                .foregroundColor(.slateMid)
                        }
                    }
                }

                // Stat chips
                HStack(spacing: 8) {
                    StatChip(value: countdownValue, label: countdownLabel, color: color)
                    StatChip(value: "Day \(cycleInfo.day)", label: "of \(cycleInfo.avgCycleLength)", color: color)
                }
            }
        }
    }

    private var countdownValue: String {
        if cycleInfo.isOnPeriod, let pd = cycleInfo.currentPeriodDay {
            return "Day \(pd)"
        } else if let duo = cycleInfo.daysUntilOvulation, duo <= 3, duo > 0 {
            return "\(duo) \(duo == 1 ? "Day" : "Days")"
        } else if cycleInfo.daysUntilOvulation == 0 {
            return "Today"
        } else {
            return "\(cycleInfo.daysUntilNext) \(cycleInfo.daysUntilNext == 1 ? "Day" : "Days")"
        }
    }

    private var countdownLabel: String {
        if cycleInfo.isOnPeriod {
            return "of period"
        } else if let duo = cycleInfo.daysUntilOvulation, duo <= 3 {
            return duo == 0 ? "ovulation" : "to ovulation"
        } else {
            return "to period"
        }
    }
}

// MARK: - Stat Chip
struct StatChip: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.custom("DMSans-Bold", size: 14))
                .foregroundColor(color)
            Text(label.uppercased())
                .font(.custom("DMSans-SemiBold", size: 10).leading(.tight))
                .tracking(0.6)
                .foregroundColor(.slateMid)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.5))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.5), lineWidth: 1))
    }
}

// MARK: - Small SVG-style ring
struct SmallCycleRing: View {
    let cycleInfo: CycleInfo

    var body: some View {
        Canvas { context, size in
            let cx     = size.width / 2
            let cy     = size.height / 2
            let radius = min(cx, cy) - 8
            let strokeW: CGFloat = 8
            let cl     = cycleInfo.avgCycleLength
            let pl     = cycleInfo.avgPeriodLength
            let day    = cycleInfo.day

            let follicularEnd = Int(Double(cl) * 0.4)
            let ovulationEnd  = Int(Double(cl) * 0.55)

            let segments: [(phase: CyclePhase, start: Int, end: Int)] = [
                (.menstruation, 1,                  pl),
                (.follicular,   pl + 1,             follicularEnd),
                (.ovulation,    follicularEnd + 1,  ovulationEnd),
                (.luteal,       ovulationEnd + 1,   cl),
            ].filter { $0.start <= $0.end }

            let todayF = Double(day) / Double(cl)

            // Track circle
            context.stroke(
                Circle().path(in: CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)),
                with: .color(Color.black.opacity(0.08)),
                lineWidth: strokeW
            )

            for seg in segments {
                let sf = Double(seg.start - 1) / Double(cl)
                let ef = Double(seg.end) / Double(cl)
                let col = phaseColor(for: seg.phase)

                func arc(_ startF: Double, _ endF: Double) -> Path {
                    var p = Path()
                    let startAngle = Angle(degrees: startF * 360 - 90)
                    let endAngle   = Angle(degrees: endF   * 360 - 90)
                    p.addArc(center: CGPoint(x: cx, y: cy), radius: radius,
                             startAngle: startAngle, endAngle: endAngle, clockwise: false)
                    return p
                }

                if sf >= todayF {
                    context.stroke(arc(sf, ef), with: .color(col.opacity(0.2)), style: StrokeStyle(lineWidth: strokeW, lineCap: .butt))
                } else if ef <= todayF {
                    context.stroke(arc(sf, ef), with: .color(col), style: StrokeStyle(lineWidth: strokeW, lineCap: .butt))
                } else {
                    context.stroke(arc(sf, todayF), with: .color(col), style: StrokeStyle(lineWidth: strokeW, lineCap: .butt))
                    context.stroke(arc(todayF, ef), with: .color(col.opacity(0.2)), style: StrokeStyle(lineWidth: strokeW, lineCap: .butt))
                }
            }

            // Today dot
            let angle = todayF * 2 * .pi - .pi / 2
            let dotX = cx + radius * cos(angle)
            let dotY = cy + radius * sin(angle)
            let dotRect = CGRect(x: dotX - 5, y: dotY - 5, width: 10, height: 10)
            context.fill(Circle().path(in: dotRect), with: .color(.white))
            context.stroke(Circle().path(in: dotRect), with: .color(phaseColor(for: cycleInfo.phase)), lineWidth: 2)
        }
        .overlay(
            VStack(spacing: 0) {
                Text("DAY")
                    .font(.custom("DMSans-SemiBold", size: 7).leading(.tight))
                    .tracking(0.6)
                    .foregroundColor(.slateMid)
                Text("\(cycleInfo.day)")
                    .font(.custom("DMSans-Bold", size: 18))
                    .foregroundColor(.charcoal)
                Text("OF \(cycleInfo.avgCycleLength)")
                    .font(.custom("DMSans-SemiBold", size: 7).leading(.tight))
                    .tracking(0.6)
                    .foregroundColor(.slateMid)
            }
        )
    }
}
