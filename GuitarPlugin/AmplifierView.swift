import SwiftUI
import AudioKit

struct AmplifierView: View {
  @StateObject var amp = GuitarAmpManager()

  var body: some View {
    ZStack {
      Rectangle()
        .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
        .overlay(
          Rectangle()
            .fill(.black)
            .opacity(0.4)
            .blendMode(.multiply)
        )

      VStack {
        Rectangle()
          .fill(Color(red: 0.3, green: 0.3, blue: 0.3))
          .frame(height: 250)
          .overlay(
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
              ForEach(0..<10) { _ in
                GridRow {
                  ForEach(0..<20) { _ in
                    Circle()
                      .fill(.black)
                      .opacity(0.3)
                  }
                }
              }
            }
              .padding()
          )

        VStack(alignment: .center, spacing: 20) {
          HStack {
            Text("VIRTUAL AMP")
              .font(.custom("Helvetica-Bold", size: 28))
              .foregroundColor(.white)
              .padding(.vertical, 8)
              .padding(.horizontal, 20)
              .background(
                Rectangle()
                  .fill(Color(white: 0.15))
                  .overlay(
                    Rectangle()
                      .stroke(Color(white: 0.6), lineWidth: 1)
                  )
              )
            
            Spacer()

            VStack(spacing: 10) {
              Circle()
                .fill(amp.isRunning ? Color.red : Color(white: 0.3))
                .frame(width: 20, height: 20)
                .overlay(
                  Circle()
                    .stroke(Color(white: 0.6), lineWidth: 2)
                )
                .shadow(color: amp.isRunning ? .red.opacity(0.8) : .clear, radius: 8)
              
              Button(action: {
                if amp.isRunning {
                  amp.stop()
                } else {
                  amp.start()
                }
              }) {
                Text(amp.isRunning ? "ON" : "OFF")
                  .font(.system(size: 16, weight: .bold))
                  .foregroundColor(.white)
                  .frame(width: 60, height: 60)
                  .background(
                    Circle()
                      .fill(amp.isRunning ? Color.green.opacity(0.6) : Color.red.opacity(0.6))
                      .shadow(color: amp.isRunning ? .green.opacity(0.5) : .red.opacity(0.5), radius: 5)
                  )
                  .overlay(
                    Circle()
                      .stroke(Color.white.opacity(0.6), lineWidth: 2)
                  )
              }
              
              Text("POWER")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            }
            .padding(.trailing, 40)
          }
          .padding(.top, 20)
          
          VStack(spacing: 30) {
            HStack(spacing: 40) {
              KnobView(value: $amp.volume, title: "VOLUME", color: .white)
              KnobView(value: $amp.bass, title: "BASS", color: .white)
              KnobView(value: $amp.middle, title: "MIDDLE", color: .white)
              KnobView(value: $amp.treble, title: "TREBLE", color: .white)
            }

            HStack(spacing: 40) {
              KnobView(value: $amp.reverbMix, title: "REVERB", color: .white)
              KnobView(value: $amp.delayMix, title: "DELAY", color: .white)
              KnobView(value: $amp.delayTime, title: "TIME", color: .white)
            }
          }
          
          Spacer()
        }
        .padding(30)
        .background(Color(white: 0.12))
        .frame(maxHeight: .infinity)
      }
    }
    .ignoresSafeArea()
  }
}

struct KnobView: View {
  @Binding var value: Double
  let title: String
  let color: Color

  var body: some View {
    VStack(spacing: 8) {
      ZStack {
        Circle()
          .fill(Color(white: 0.2))
          .frame(width: 50, height: 50)
          .overlay(
            Circle()
              .stroke(Color(white: 0.3), lineWidth: 2)
          )
          .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)

        Rectangle()
          .fill(.white)
          .frame(width: 2, height: 18)
          .offset(y: -12)
          .rotationEffect(.degrees(220 + (value - 1) * 280 / 4))
      }
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { gesture in
            let center = CGPoint(x: 25, y: 25)
            let location = gesture.location
            let angle = Double(atan2(location.y - center.y, location.x - center.x)) * 180 / .pi
            let normalizedAngle = (angle + 90 + 360).truncatingRemainder(dividingBy: 360)
            
            if normalizedAngle >= 220 && normalizedAngle <= 500 {
              let normalized = (normalizedAngle - 220) / 280
              value = 1 + normalized * 4
            }
          }
      )

      Text(title)
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(color)
    }
  }
}

#Preview {
  AmplifierView()
}
