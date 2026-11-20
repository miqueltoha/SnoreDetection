//
//  SleepClockSelector.swift
//  SnoreDetection
//
//  Created by Miquel Toha Perera on 19/4/25.
//

import SwiftUI
import UIKit

struct SleepClockSelector: View {
  @Binding var bedtime: Date
  @Binding var wakeTime: Date
  
  @State private var animatedColor: Color = .blue
  @State private var lastHapticState: Bool = false
  
  private let clockSize: CGFloat = 320
  private let handleSize: CGFloat = 32
  
  var body: some View {
    ZStack {
      Circle()
        .fill(Color(.systemGray6))
        .frame(width: clockSize, height: clockSize)
        .shadow(color: .black.opacity(0.2), radius: 10)
      
      SleepArcGradient(bedtime: bedtime, wakeTime: wakeTime, radius: clockSize / 2 - 12)
        .fill(animatedColor)
        .animation(.easeInOut(duration: 0.3), value: animatedColor)
      
      ForEach(0..<24) { hour in
        if hour % 6 == 0 {
          Text("\(hour)")
            .font(.caption2)
            .foregroundColor(.gray)
            .position(getPosition(for: hourAngle(hour: hour), radius: clockSize / 2 + 26))
        }
      }
      
      VStack(spacing: 8) {
        Text("Bedtime: \(formattedTime(bedtime))")
          .font(.headline)
        Text("Wake up: \(formattedTime(wakeTime))")
          .font(.subheadline)
          .foregroundColor(.secondary)
        Text("🛌 \(sleepDurationString)")
          .font(.title2)
          .bold()
          .foregroundColor(animatedColor)
          .animation(.easeInOut(duration: 0.3), value: animatedColor)
      }
      .foregroundColor(.primary)
      
      Circle()
        .fill(Color.yellow)
        .frame(width: handleSize, height: handleSize)
        .overlay(Text("🌙").font(.caption))
        .position(getPosition(for: angle(from: bedtime), radius: clockSize / 2))
        .gesture(DragGesture().onChanged { value in
          bedtime = date(from: value.location)
          updateColorAndFeedback()
        })
      
      Circle()
        .fill(Color.orange)
        .frame(width: handleSize, height: handleSize)
        .overlay(Text("☀️").font(.caption))
        .position(getPosition(for: angle(from: wakeTime), radius: clockSize / 2))
        .gesture(DragGesture().onChanged { value in
          wakeTime = date(from: value.location)
          updateColorAndFeedback()
        })
    }
    .frame(width: clockSize, height: clockSize + 40)
    .onAppear(perform: updateColorAndFeedback)
  }
  
  private var sleepDuration: TimeInterval {
    let end = wakeTime > bedtime ? wakeTime : wakeTime.addingTimeInterval(86400)
    return end.timeIntervalSince(bedtime)
  }
  
  private var sleepDurationString: String {
    let totalMinutes = Int(sleepDuration / 60)
    let h = totalMinutes / 60
    let m = totalMinutes % 60
    return String(format: "%dh %02dm", h, m)
  }
  
  private func computeColor(for duration: TimeInterval) -> Color {
    let h = duration / 3600
    switch h {
    case ..<6: return .red
    case 6..<7.5: return .orange
    case 7.5..<9: return .green
    default: return .blue
    }
  }
  
  private func updateColorAndFeedback() {
    let color = computeColor(for: sleepDuration)
    let currentHapticState = sleepDuration >= 28800 // 8h en segons
    
    if currentHapticState != lastHapticState {
      let generator = UIImpactFeedbackGenerator(style: .medium)
      generator.impactOccurred()
      lastHapticState = currentHapticState
    }
    
    withAnimation(.easeInOut(duration: 0.3)) {
      animatedColor = color
    }
  }
  
  private func formattedTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
  }
  
  private func angle(from date: Date) -> Angle {
    let components = Calendar.current.dateComponents([.hour, .minute], from: date)
    let hour = Double(components.hour ?? 0)
    let minute = Double(components.minute ?? 0)
    return Angle(degrees: ((hour + minute / 60) / 24) * 360)
  }
  
  private func hourAngle(hour: Int) -> Angle {
    Angle(degrees: (Double(hour) / 24) * 360)
  }
  
  private func getPosition(for angle: Angle, radius: CGFloat) -> CGPoint {
    let r = radius
    let rad = angle.radians - .pi / 2
    return CGPoint(x: clockSize / 2 + CGFloat(cos(rad)) * r, y: clockSize / 2 + CGFloat(sin(rad)) * r)
  }
  
  private func date(from point: CGPoint) -> Date {
    let center = CGPoint(x: clockSize / 2, y: clockSize / 2)
    let dx = point.x - center.x
    let dy = point.y - center.y
    let angle = atan2(dy, dx) + .pi / 2
    let degrees = (angle < 0 ? angle + 2 * .pi : angle) * 180 / .pi
    let hours = (degrees / 360) * 24
    let hour = Int(hours)
    let minute = Int((hours - Double(hour)) * 60)
    return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
  }
}

struct SleepArcGradient: Shape {
  var bedtime: Date
  var wakeTime: Date
  var radius: CGFloat
  
  func path(in rect: CGRect) -> Path {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let startAngle = angle(from: bedtime)
    let endAngle = angle(from: wakeTime > bedtime ? wakeTime : wakeTime.addingTimeInterval(86400))
    var path = Path()
    path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
    return path
  }
  
  private func angle(from date: Date) -> Angle {
    let components = Calendar.current.dateComponents([.hour, .minute], from: date)
    let hour = Double(components.hour ?? 0)
    let minute = Double(components.minute ?? 0)
    return Angle(degrees: ((hour + minute / 60) / 24) * 360 - 90)
  }
}

#Preview {
  SleepClockSelector(
    bedtime: .constant(Date()),
    wakeTime: .constant(Calendar.current.date(byAdding: .hour, value: 8, to: Date())!)
  )
}
