//
//  ChartView.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/21.
//

import AVFoundation
import Combine
import DRSKit
import Kroma
import SwiftUI

struct PlayBarModifier: ViewModifier {
    @Binding var offset: CGFloat
    @Binding var isPlaying: Bool
    @Binding var scrollPosition: ScrollPosition
    let seq: Seq
    var speed: Double
    let musicURL: URL?
    @State private var player: AVPlayer = .init()
    @State var error: Error?
    @State var showError = false

    init(
        offset: Binding<CGFloat>, isPlaying: Binding<Bool>, scrollPosition: Binding<ScrollPosition>, seq: Seq,
        speed: Double, musicURL: URL?
    ) {
        _offset = offset
        _isPlaying = isPlaying
        _scrollPosition = scrollPosition
        self.seq = seq
        self.speed = speed
        self.musicURL = musicURL
    }

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
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
                    scrollPosition.scrollTo(y: self.offset)
                }
            }
    }

    func startAnimation() {
        do {
            let currPosToTime = offsetToTime(offset, speed: speed)
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
    @State var playBarTick: Int32 = 0
    @State var musicURL: URL?
    @State var showEndTimeSetting = false
    @State var endTime: Double = 0.0
    @State var showSpeedSetting = false
    @State var showMusicImporter = false
    @State var showChartExporter = false
    @State var showPlayBarTickSetting: Bool = false
    @State var error: Error?
    @State var showError: Bool = false
    @State var removeStepIndex: Int?
    @State var showRemoveStep: Bool = false
    @State var numTicks = [Int32]()
    @State var beatTicks = [Int32]()
    //    var nf: NumberFormatter {
    //        let nf = NumberFormatter()
    //        nf.numberStyle = .none
    //        nf.allowsFloats = false
    //        return nf
    //    }
    var floatNf: NumberFormatter {
        let nf = NumberFormatter()
        nf.numberStyle = .none
        return nf
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack {
                    ZStack(alignment: .topLeading) {
                        Lanes()
                            .frame(
                                height: tickToOffset(seq.info.endTick, seq: seq, speed: speed)
                            )
                            .padding([.horizontal], 32)
                        ForEach(numTicks, id: \.self) { tick in
                            HorizontalLine()
                                .stroke(
                                    style: StrokeStyle(
                                        lineWidth: 2, lineCap: .round, lineJoin: .round)
                                )
                                .frame(height: 2)
                                .offset(y: tickToOffset(tick, seq: seq, speed: speed))
                        }
                        ForEach(beatTicks, id: \.self) { tick in
                            HorizontalLine()
                                .stroke(
                                    style: StrokeStyle(
                                        lineWidth: 4, lineCap: .round, lineJoin: .round)
                                )
                                .frame(height: 4)
                                .offset(y: tickToOffset(tick, seq: seq, speed: speed))
                        }
                        ForEach(Array(zip(seq.steps.indices, $seq.steps)), id: \.1.id) { index, step in
                            StepView(step: step, seq: seq, speed: speed)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        seq.steps.remove(at: index)
                                    } label: {
                                        Label("Delete", systemImage: "delete.left")
                                    }
                                }
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
                            .id("playBar")
                            .frame(height: 4)
                            .offset(y: 2)
                            .overlay(
                                Text(verbatim: "\(getCurrentTick())")
                                    .onTapGesture {
                                        showPlayBarTickSetting = true
                                    }
                            )
                            .modifier(
                                PlayBarModifier(
                                    offset: $playBarOffset, isPlaying: $isPlaying, scrollPosition: $position, seq: seq,
                                    speed: speed,
                                    musicURL: musicURL)),
                        alignment: .topLeading)
                    Spacer()
                        .frame(height: geometry.size.height)
                }
            }
            .scrollPosition($position)
        }
        .padding()
        .alert("End Time", isPresented: $showEndTimeSetting) {
            TextField(String(endTime), value: $endTime, formatter: floatNf)
                #if os(iOS)
                    .keyboardType(.decimalPad)
                #endif
                .onAppear {
                    endTime = tickToTime(seq.info.endTick, seq: seq)
                }
            Button("OK") {
                seq.info.endTick = timeToTick(endTime, seq: seq)
                showEndTimeSetting = false
            }
        } message: {
            Text("Set the end time (in ms)")
        }
        .alert("Speed", isPresented: $showSpeedSetting) {
            TextField(String(speed), value: $speed, formatter: floatNf)
                #if os(iOS)
                    .keyboardType(.decimalPad)
                #endif
            Button("OK") {
                showSpeedSetting = false
            }
        } message: {
            Text("Set the lane speed")
        }
        .alert("Play Bar Tick", isPresented: $showPlayBarTickSetting) {
            CustomStepperWithTextField(value: $playBarTick, maxValue: seq.info.endTick) {
                playBarTick = numTickWithMeasures(playBarTick, seq: seq, direction: .next)
            } onDecrement: {
                playBarTick = numTickWithMeasures(playBarTick, seq: seq, direction: .previous)
            }
            .onAppear {
                playBarTick = getCurrentTick()
            }
            .onChange(of: playBarTick) {
                playBarOffset = tickToOffset(playBarTick, seq: seq, speed: speed)
            }
            Button("OK") {
                showPlayBarTickSetting = false
            }
        } message: {
            Text("Set the current play bar tick")
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
        .fileExporter(isPresented: $showChartExporter, document: seq, contentType: .xml) { result in
            switch result {
            case .success(_):
                break
            case .failure(let failure):
                error = failure
                showError = true
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    showChartExporter = true
                } label: {
                    Label("Save", systemImage: "square.and.arrow.up")
                }
                Menu {
                    Button {
                        showSpeedSetting = true
                    } label: {
                        Label("Speed", systemImage: "hare")
                    }
                    Button {
                        showEndTimeSetting = true
                    } label: {
                        Label("End Time", systemImage: "forward.end")
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
                        let tick = getCurrentTick()
                        seq.steps.append(
                            .init(
                                startTick: tick, endTick: tick, leftPos: 0, rightPos: 65536,
                                longPoints: [], kind: .left, playerID: .Player1))
                    } label: {
                        Label("Step", systemImage: "minus")
                    }
                    Button {
                        let tick = getCurrentTick()
                        seq.steps.append(
                            .init(
                                startTick: tick,
                                endTick: numTickWithMeasures(tick, seq: seq, direction: .next), leftPos: 0,
                                rightPos: 65536,
                                longPoints: [
                                    .init(
                                        tick: numTickWithMeasures(tick, seq: seq, direction: .next), leftPos: 0,
                                        rightPos: 65536)
                                ], kind: .left, playerID: .Player1))
                    } label: {
                        Label(
                            "Long Step", systemImage: "rectangle.portrait.fill")
                    }
                    Button {
                        let tick = getCurrentTick()
                        seq.steps.append(
                            .init(
                                startTick: tick, endTick: tick, leftPos: 0, rightPos: 65536,
                                longPoints: [], kind: .down, playerID: .dummy3))
                    } label: {
                        Label("Down", systemImage: "arrowshape.down")
                    }
                    Button {
                        seq.steps.append(
                            .init(
                                startTick: getCurrentTick(), endTick: getCurrentTick(), leftPos: 0, rightPos: 65536,
                                longPoints: [], kind: .jump, playerID: .dummy3))
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
        .onAppear {
            updateBackgroundTicks()
        }
        .onChange(of: seq.info.bpm) {
            updateBackgroundTicks()
        }
        .onChange(of: seq.info.measure) {
            updateBackgroundTicks()
        }
    }

    func updateBackgroundTicks() {
        numTicks = allNumeratorTicks(seq: seq)
        beatTicks = allBeatTicks(seq: seq)
    }

    func getCurrentTick() -> Int32 {
        offsetToTick(playBarOffset, seq: seq, speed: speed)
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
