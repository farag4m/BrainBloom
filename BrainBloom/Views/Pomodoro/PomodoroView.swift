import SwiftUI
import AVFoundation

struct PomodoroView: View {
    @Environment(\.colorScheme) private var scheme

    @AppStorage("detoxSelectedMinutes") private var selectedMinutes: Int = 20
    @AppStorage("detoxSoundSelection") private var storedSound: String = DetoxSound.brownNoise.rawValue

    @State private var remainingSeconds: Int = 20 * 60
    @State private var isRunning = false
    @State private var audioController = DetoxAudioController()
    @State private var showCustomDuration = false
    @State private var customMinutes: Int = 25
    @State private var timerTask: Task<Void, Never>?
    @State private var isPanelExpanded = false

    private let durationOptions = [1, 15, 25, 50]

    private var selectedSound: DetoxSound {
        DetoxSound(rawValue: storedSound) ?? .brownNoise
    }

    private var totalSeconds: Int {
        max(1, selectedMinutes) * 60
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - Double(remainingSeconds) / Double(totalSeconds)
    }

    private var primaryText: Color {
        scheme == .dark ? .white : Color(red: 0.14, green: 0.18, blue: 0.32)
    }

    private var secondaryText: Color {
        scheme == .dark ? .white.opacity(0.75) : Color(red: 0.20, green: 0.28, blue: 0.45)
    }

    private var timeLabel: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardGridBackground().ignoresSafeArea()

                VStack(spacing: 16) {
                    DetoxFlowerCard(progress: progress, primaryText: primaryText, secondaryText: secondaryText)

                    if isRunning {
                        Text(timeLabel)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(primaryText)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 120)

                if isPanelExpanded {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .zIndex(5)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                isPanelExpanded = false
                            }
                        }
                }

                PomodoroControlSheet(
                    isExpanded: $isPanelExpanded,
                    isRunning: isRunning,
                    selectedMinutes: $selectedMinutes,
                    customMinutes: $customMinutes,
                    isCustomPresented: $showCustomDuration,
                    options: durationOptions,
                    selectedSound: selectedSound,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    onSelectDuration: handleDurationChange,
                    onSelectSound: handleSoundChange,
                    onStart: {
                        if isRunning {
                            stopDetox()
                        } else {
                            startDetox()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                isPanelExpanded = false
                            }
                        }
                    }
                )
            }
            .navigationTitle("Pomodoro")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onAppear {
            syncRemaining()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                isPanelExpanded = true
            }
        }
        }
        .onChange(of: isRunning) { running in
            if running {
                startTimerLoop()
            } else {
                timerTask?.cancel()
                timerTask = nil
            }
        }
    }

    private func syncRemaining() {
        remainingSeconds = totalSeconds
    }

    private func handleDurationChange(_ minutes: Int) {
        selectedMinutes = minutes
        if !isRunning {
            syncRemaining()
        }
    }

    private func handleSoundChange(_ sound: DetoxSound) {
        storedSound = sound.rawValue
        if audioController.isPlaying {
            audioController.play(sound: sound)
        }
    }

    private func startDetox() {
        if remainingSeconds == 0 {
            syncRemaining()
        }
        audioController.play(sound: selectedSound)
        isRunning = true
    }

    private func stopDetox() {
        isRunning = false
        audioController.stop()
        syncRemaining()
    }

    private func finishDetox() {
        isRunning = false
        audioController.stop()
    }

    private func startTimerLoop() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled && isRunning && remainingSeconds > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    guard isRunning else { return }
                    remainingSeconds = max(0, remainingSeconds - 1)
                    if remainingSeconds == 0 {
                        finishDetox()
                    }
                }
            }
        }
    }
}

private struct PomodoroControlSheet: View {
    @Binding var isExpanded: Bool
    let isRunning: Bool
    @Binding var selectedMinutes: Int
    @Binding var customMinutes: Int
    @Binding var isCustomPresented: Bool
    let options: [Int]
    let selectedSound: DetoxSound
    let primaryText: Color
    let secondaryText: Color
    let onSelectDuration: (Int) -> Void
    let onSelectSound: (DetoxSound) -> Void
    let onStart: () -> Void

    var body: some View {
        GeometryReader { geo in
            let expandedHeight: CGFloat = 320
            let availableHeight = geo.size.height
            let minOffset = availableHeight - expandedHeight
            let hiddenOffset = availableHeight + 40
            let offset = isExpanded ? minOffset : hiddenOffset

            VStack(spacing: 12) {
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)

                DetoxDurationCard(
                    selectedMinutes: $selectedMinutes,
                    customMinutes: $customMinutes,
                    isCustomPresented: $isCustomPresented,
                    options: options,
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    onSelect: onSelectDuration
                )

                DetoxSoundCard(
                    selectedSound: selectedSound,
                    primaryText: primaryText,
                    onSelectSound: onSelectSound
                )

                Button(isRunning ? "End Session" : "Start Session") {
                    onStart()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
            .background(
                GlassCard(cornerRadius: 28)
                    .shadow(color: .black.opacity(0.18), radius: 14, y: -6)
            )
            .offset(y: offset)
            .animation(.spring(response: 0.45, dampingFraction: 0.9), value: isExpanded)
        }
        .ignoresSafeArea(edges: .bottom)
        .zIndex(10)
    }
}

private struct DetoxDurationCard: View {
    @Binding var selectedMinutes: Int
    @Binding var customMinutes: Int
    @Binding var isCustomPresented: Bool
    let options: [Int]
    let primaryText: Color
    let secondaryText: Color
    let onSelect: (Int) -> Void
    @State private var pendingCustomMinutes: Int = 25

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pomodoro length")
                .font(.headline.weight(.semibold))
                .foregroundStyle(primaryText)

            HStack(spacing: 8) {
                ForEach(options, id: \.self) { minutes in
                    Button(action: {
                        selectedMinutes = minutes
                        onSelect(minutes)
                    }) {
                        Text(label(for: minutes))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                selectedMinutes == minutes
                                ? Color.sgTeal.opacity(0.30)
                                : Color.white.opacity(0.20)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(primaryText)
                }

                Button(action: {
                    pendingCustomMinutes = customMinutes
                    isCustomPresented = true
                }) {
                    Text(customLabel)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            isCustomSelected
                            ? Color.sgTeal.opacity(0.30)
                            : Color.white.opacity(0.20)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .foregroundStyle(primaryText)
            }

            Text("Classic is 25 minutes. Choose a shorter reset or a deeper sprint.")
                .font(.caption)
                .foregroundStyle(secondaryText)
        }
        .padding(16)
        .background(GlassCard(cornerRadius: 20))
        .sheet(isPresented: $isCustomPresented) {
            NavigationStack {
                VStack(spacing: 16) {
                    Text("Custom duration")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(primaryText)

                    Stepper(value: $pendingCustomMinutes, in: 1...90, step: 1) {
                        Text("\(pendingCustomMinutes) minutes")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(primaryText)
                    }
                    .padding(.horizontal, 24)

                    Text("Set any duration between 1 and 90 minutes.")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DashboardGridBackground().ignoresSafeArea())
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isCustomPresented = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Set") {
                            customMinutes = pendingCustomMinutes
                            selectedMinutes = pendingCustomMinutes
                            onSelect(pendingCustomMinutes)
                            isCustomPresented = false
                        }
                    }
                }
            }
        }
    }

    private var isCustomSelected: Bool {
        !options.contains(selectedMinutes)
    }

    private var customLabel: String {
        isCustomSelected ? "Custom \(selectedMinutes)m" : "Custom"
    }

    private func label(for minutes: Int) -> String {
        switch minutes {
        case 1:
            return "1 min"
        case 15:
            return "Quick 15"
        case 25:
            return "Classic 25"
        case 50:
            return "Deep 50"
        default:
            return "\(minutes) min"
        }
    }
}

private struct DetoxSoundCard: View {
    let selectedSound: DetoxSound
    let primaryText: Color
    let onSelectSound: (DetoxSound) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background sound")
                .font(.headline.weight(.semibold))
                .foregroundStyle(primaryText)

            HStack(spacing: 8) {
                ForEach(DetoxSound.options, id: \.self) { sound in
                    Button(action: { onSelectSound(sound) }) {
                        Text(sound.label)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                selectedSound == sound
                                ? Color.sgTeal.opacity(0.30)
                                : Color.white.opacity(0.20)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(primaryText)
                }
            }
        }
        .padding(16)
        .background(GlassCard(cornerRadius: 20))
    }
}

private struct DetoxFlowerCard: View {
    let progress: Double
    let primaryText: Color
    let secondaryText: Color

    var body: some View {
        VStack(spacing: 12) {
            Text("Healing Focus")
                .font(.headline.weight(.semibold))
                .foregroundStyle(primaryText)

            BloomRecoveryView(progress: progress)
                .scaleEffect(0.34, anchor: .center)
                .frame(width: 120, height: 120, alignment: .center)
                .frame(maxWidth: .infinity)
                .shadow(color: Color.sgTeal.opacity(0.22), radius: 14, y: 6)

            Text("A little time away helps your mind and flower recover.")
                .font(.caption)
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(GlassCard(cornerRadius: 20))
    }
}

private enum DetoxSound: String, CaseIterable {
    case brownNoise
    case oceanWaves

    static var options: [DetoxSound] {
        [.brownNoise, .oceanWaves]
    }

    var label: String {
        switch self {
        case .brownNoise: return "Brown"
        case .oceanWaves: return "Ocean"
        }
    }
}

private final class DetoxAudioController {
    private let engine = AVAudioEngine()
    private var noisePlayer: AVAudioPlayerNode?
    private var currentSound: DetoxSound = .brownNoise
    private(set) var isPlaying = false

    init() {
        configureSession()
    }

    func play(sound: DetoxSound) {
        currentSound = sound
        playNoise()
    }

    func stop() {
        if let node = noisePlayer {
            node.stop()
            engine.detach(node)
        }
        engine.stop()
        noisePlayer = nil
        isPlaying = false
    }

    private func playNoise() {
        stop()
        let node = AVAudioPlayerNode()
        noisePlayer = node
        engine.attach(node)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
        guard let format else { return }

        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 44100)!
        buffer.frameLength = buffer.frameCapacity

        let channels = buffer.floatChannelData![0]
        var last: Float = 0
        var phase: Float = 0

        for i in 0..<Int(buffer.frameLength) {
            let white = Float.random(in: -1...1)
            switch currentSound {
            case .brownNoise:
                last = (last + white * 0.02).clamped(to: -1...1)
                channels[i] = last
            case .oceanWaves:
                last = (last + white * 0.01).clamped(to: -1...1)
                phase += 0.0008
                let swell = (sin(phase) + 1) * 0.5
                channels[i] = last * Float(0.6 + 0.4 * swell)
            }
        }

        engine.connect(node, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
            node.volume = 0.6
            node.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            node.play()
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Ignore session errors.
        }
    }
}

private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
