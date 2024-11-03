import SwiftUI
import AudioKit
import AudioKitEX
import AVFoundation

class GuitarAmpManager: ObservableObject {
  private var engine = AudioEngine()
  private var input: AudioEngine.InputNode?
  private var distortion: Distortion?
  private var reverb: Reverb?
  private var delay: Delay?
  private var mixer: Mixer?
  private var bassEQ: ParametricEQ?
  private var midEQ: ParametricEQ?
  private var trebleEQ: ParametricEQ?
  
  @Published var availableDevices: [Device] = []
  @Published var selectedDevice: Device?
  
  @Published var volume: Double = 2.5 {
    didSet { updateVolume() }
  }
  @Published var drive: Double = 2.5 {
    didSet { updateDistortionParameters() }
  }
  @Published var bass: Double = 2.5 {
    didSet { updateEQParameters() }
  }
  @Published var middle: Double = 2.5 {
    didSet { updateEQParameters() }
  }
  @Published var treble: Double = 2.5 {
    didSet { updateEQParameters() }
  }
  @Published var reverbMix: Double = 2.5 {
    didSet { updateReverbParameters() }
  }
  @Published var delayMix: Double = 2.5 {
    didSet { updateDelayParameters() }
  }
  @Published var delayTime: Double = 2.5 {
    didSet { updateDelayParameters() }
  }
  @Published var isRunning: Bool = false

  init() {
    updateAvailableDevices()
    setupAudioChain()
  }

  func updateAvailableDevices() {
    availableDevices = AudioEngine.devices
    selectedDevice = engine.device
  }

  func setDevice(_ device: Device) {
    do {
      engine.stop()
      try engine.setDevice(device)
      selectedDevice = device
      setupAudioChain()
      try engine.start()
    } catch {
      print("Error setting device: \(error)")
    }
  }

  func start() {
    do {
      try engine.start()
      isRunning = true
    } catch {
      print("Error starting the AudioKit engine: \(error)")
      isRunning = false
    }
  }

  func stop() {
    engine.stop()
    isRunning = false
  }
}

private extension GuitarAmpManager {
  private func setupAudioChain() {
    engine.output = nil
    engine.stop()

    guard let input = engine.input else {
      print("Error: Input node not available.")
      return
    }

    self.input = input

    let distortion = Distortion(input)
    distortion.delay = 0.1
    distortion.decay = 1.0
    distortion.delayMix = 0.0
    distortion.ringModFreq1 = 100
    distortion.ringModFreq2 = 100
    distortion.ringModBalance = 50
    distortion.decimation = 0
    distortion.rounding = 0
    distortion.decimationMix = 0
    distortion.linearTerm = 1.0
    distortion.squaredTerm = 0
    distortion.cubicTerm = 0
    distortion.polynomialMix = 0
    distortion.ringModMix = 0
    distortion.softClipGain = -80
    distortion.finalMix = 50
    self.distortion = distortion

    let bassEQ = ParametricEQ(distortion)
    bassEQ.centerFreq = 100
    bassEQ.q = 0.8
    bassEQ.gain = 0

    let midEQ = ParametricEQ(bassEQ)
    midEQ.centerFreq = 1000
    midEQ.q = 0.8
    midEQ.gain = 0

    let trebleEQ = ParametricEQ(midEQ)
    trebleEQ.centerFreq = 5000
    trebleEQ.q = 0.8
    trebleEQ.gain = 0

    self.bassEQ = bassEQ
    self.midEQ = midEQ
    self.trebleEQ = trebleEQ

    let reverb = Reverb(trebleEQ)
    reverb.dryWetMix = 0
    self.reverb = reverb

    let delay = Delay(reverb)
    delay.time = 0.5
    delay.feedback = 0
    delay.dryWetMix = 0
    self.delay = delay

    let mixer = Mixer(delay)
    mixer.volume = 1.0
    self.mixer = mixer

    engine.output = mixer

    updateDistortionParameters()
    updateEQParameters()
    updateReverbParameters()
    updateDelayParameters()
    updateVolume()
  }
  private func updateDistortionParameters() {
    let normalizedDrive = (drive - 1) / 9
    distortion?.softClipGain = AUValue(normalizedDrive * 100 - 80)
    distortion?.finalMix = AUValue(50 + normalizedDrive * 50)
    distortion?.ringModMix = AUValue(normalizedDrive * 20)
    distortion?.decimation = AUValue(normalizedDrive * 50)
    distortion?.rounding = AUValue(normalizedDrive * 20)
    distortion?.decimationMix = AUValue(normalizedDrive * 50)
    distortion?.polynomialMix = AUValue(normalizedDrive * 100)
    distortion?.linearTerm = AUValue(1 - normalizedDrive * 0.5)
    distortion?.squaredTerm = AUValue(normalizedDrive * 10)
    distortion?.cubicTerm = AUValue(normalizedDrive * 20)
  }

  private func updateEQParameters() {
    bassEQ?.gain = AUValue((bass - 2.5) * 4.8)
    midEQ?.gain = AUValue((middle - 2.5) * 4.8)
    trebleEQ?.gain = AUValue((treble - 2.5) * 4.8)
  }

  private func updateReverbParameters() {
    reverb?.dryWetMix = AUValue((reverbMix - 1) / 4 * 100)
  }

  private func updateDelayParameters() {
    delay?.time = AUValue(delayTime / 5)
    delay?.dryWetMix = AUValue((delayMix - 1) / 4 * 100)
  }

  private func updateVolume() {
    mixer?.volume = AUValue((volume - 1) / 4 * 2)
  }

  private func updateAllParameters() {
    updateVolume()
    updateDistortionParameters()
    updateEQParameters()
    updateReverbParameters()
    updateDelayParameters()
  }
}
