//
//  ChartView.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/21.
//

import Combine
import DRSKit
import Kroma
import SwiftUI
import AVFoundation

struct PlayBarModifier: @preconcurrency Animatable, ViewModifier {
    @Binding var offset: CGFloat
    @Binding var isPlaying: Bool
    let seq: Seq
    var speed: Double
    let musicURL: URL?
    private var offsetValue: CGFloat
    @State private var player: AVPlayer = .init()
    @State var error: Error?
    @State var showError = false

    var animatableData: CGFloat {
        get { offsetValue }
        set { offsetValue = newValue }
    }

    init(offset: Binding<CGFloat>, isPlaying: Binding<Bool>, seq: Seq, speed: Double, musicURL: URL?) {
        _offset = offset
        offsetValue = offset.wrappedValue
        _isPlaying = isPlaying
        self.seq = seq
        self.speed = speed
        self.musicURL = musicURL
    }

    func body(content: Content) -> some View {
        content
            .offset(y: offsetValue)
            .onChange(of: isPlaying) {
                if isPlaying {
                    startAnimation()
                } else {
                    stopAnimation()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(error?.localizedDescription ?? "Unknown error has occurred.")
            }
            .onReceive(player.periodicTimePublisher()) { time in
                if time.seconds > player.currentItem?.duration.seconds ?? 0 {
                    self.isPlaying = false
                    self.offset = 0
                } else {
                    self.offset = timeToOffset(time.seconds * 1000, speed: self.speed)
                }
            }
    }

    func startAnimation() {
        do {
            let currPosToTime = offsetToTime(offsetValue, speed: speed)
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            if let musicURL, musicURL.startAccessingSecurityScopedResource() {
                player.replaceCurrentItem(with: AVPlayerItem(url: musicURL))
                player.seek(to: CMTime(seconds: currPosToTime / 1000, preferredTimescale: 1))
                player.play()
            }
        } catch {
            isPlaying = false
            self.error = error
            self.showError = true
        }
    }

    func stopAnimation() {
        player.pause()
        musicURL?.stopAccessingSecurityScopedResource()
    }
}

struct ChartView: View {
    @Binding var seq: Seq
    @State var speed: Double = 4.0
    @State private var position = ScrollPosition(edge: .top)
    @State var isPlaying = false
    @State var playBarOffset: CGFloat = 0.0
    @State var musicURL: URL?
    @State var showEndTickSetting = false
    @State var showSpeedSetting = false
    @State var showMusicImporter = false
    @State var error: Error?
    @State var showError: Bool = false
    var nf: NumberFormatter {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.usesGroupingSeparator = false
        nf.allowsFloats = false
        return nf
    }
    var floatNf: NumberFormatter {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.usesGroupingSeparator = false
        nf.allowsFloats = true
        return nf
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ScrollView {
                    LazyVStack {
                        ZStack(alignment: .topLeading) {
                            Lanes()
                                .frame(
                                    height: tickToOffset(seq.info.endTick, seq: seq, speed: speed)
                                )
                                .padding([.horizontal], 32)
                            ForEach($seq.steps, id: \.self) { step in
                                StepView(step: step, seq: seq, speed: speed)
                            }
                        }
                        .overlay(
                            Rectangle()
                                .fill(Color.blue.darker(by: 0.2))
                                .frame(width: 32)
                                .onTapGesture { location in
                                    playBarOffset = location.y
                                }, alignment: .trailing
                        )

                        .overlay(
                            HorizontalLine()
                                .stroke(
                                    .green,
                                    style: StrokeStyle(
                                        lineWidth: 4, lineCap: .round, lineJoin: .round)
                                )
                                .frame(height: 4)
                                .offset(y: 2)
                                .modifier(
                                    PlayBarModifier(
                                        offset: $playBarOffset, isPlaying: $isPlaying, seq: seq, speed: speed, musicURL: musicURL)),
                            alignment: .topLeading)
                    }
                    Spacer()
                        .frame(height: geometry.size.height)
                }
                .scrollPosition($position)
            }
        }
        .padding()
        .alert("End Tick", isPresented: $showEndTickSetting) {
            TextField("End Tick", value: $seq.info.endTick, formatter: nf)
            Button("OK") {
                showEndTickSetting = false
            }
        } message: {
            Text("Set the end tick")
        }
        .alert("Speed", isPresented: $showSpeedSetting) {
            TextField("Speed", value: $speed, formatter: nf)
            Button("OK") {
                showSpeedSetting = false
            }
        } message: {
            Text("Set the lane speed")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(error?.localizedDescription ?? "Unknown error has occurred.")
        }
        .fileImporter(isPresented: $showMusicImporter, allowedContentTypes: [.audio]) { result in
            switch result {
            case .success(let success):
                musicURL = success
            case .failure(let failure):
                error = failure
                showError = true
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Menu {
                    Button {
                        showSpeedSetting = true
                    } label: {
                        Label("Speed", systemImage: "hare")
                    }
                    Button {
                        showEndTickSetting = true
                    } label: {
                        Label("End Tick", systemImage: "forward.end")
                    }
                    Button {
                        showMusicImporter = true
                    } label: {
                        Label("Change Music", systemImage: "music.note")
                    }
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                Button {
                    withAnimation {
                        position.scrollTo(edge: .top)
                        playBarOffset = 0
                    }
                } label: {
                    Label("Go Top", systemImage: "arrow.up.to.line")
                }
                .disabled(position.edge == .top)
                Button {
                    let offset = tickToOffset(seq.info.endTick, seq: seq, speed: speed)
                    withAnimation {
                        position.scrollTo(y: offset)
                        playBarOffset = offset
                    }
                } label: {
                    Label("Go Bottom", systemImage: "arrow.down.to.line")
                }
                .disabled(position.edge == .bottom)
                Menu {
                    Button {

                    } label: {
                        Label("Note", systemImage: "minus")
                    }
                    Button {

                    } label: {
                        Label(
                            "Long Note", systemImage: "rectangle.portrait.fill")
                    }
                    Button {

                    } label: {
                        Label("Down", systemImage: "arrowshape.down")
                    }
                    Button {

                    } label: {
                        Label("Jump", systemImage: "chevron.up.2")
                    }
                } label: {
                    Label("New", systemImage: "plus")
                }
                .disabled(isPlaying)

                if isPlaying {
                    Button {
                        isPlaying = false
                    } label: {
                        Label("Pause", systemImage: "pause.fill")
                    }
                } else {
                    Button {
                        isPlaying = true
                    } label: {
                        Label("Play", systemImage: "play.fill")
                    }
                    .disabled(musicURL == nil)
                }
            }
        }
    }

    func getBPMAndMeasure(by tick: Int32) -> (Seq.Info.BPM, Seq.Info.Measure) {
        let bpm = seq.info.bpm.enumerated().first(where: { (i, bpm) in
            i + 1 == seq.info.bpm.count
                || (bpm.tick <= tick && seq.info.bpm[i + 1].tick > tick)
        })!.element

        let measure = seq.info.measure.enumerated().first(where: {
            (i, measure) in
            i + 1 == seq.info.measure.count
                || (measure.tick <= tick && seq.info.measure[i + 1].tick > tick)
        })!.element

        return (bpm, measure)
    }
}

#Preview {
    struct ChartViewPreview: View {
        var body: some View {
            NavigationStack {
                ChartView(
                    seq: Binding<Seq>(
                        get: { testSeq! },
                        set: { testSeq = $0 }
                    ))
            }
        }
    }

    return ChartViewPreview()
}
