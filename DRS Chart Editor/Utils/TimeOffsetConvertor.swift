import DRSKit
//
//  TimeOffsetConvertor.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/22.
//
import Foundation

// thanks chatgpt
func tickToTime(_ noteStartTick: Int32, seq: Seq) -> Double {
    var noteStartMs: Double = 0.0

    for i in 0..<seq.info.bpm.count {
        let currentBPMChange = seq.info.bpm[i]
        let nextStartTick = (i + 1 < seq.info.bpm.count) ? seq.info.bpm[i + 1].tick : seq.info.endTick

        // Calculate the number of ticks in the current segment
        let ticksInSegment = min(noteStartTick, nextStartTick) - currentBPMChange.tick

        // Calculate milliseconds per beat for the current BPM
        let millisecondsPerBeat = 6000000.0 / Double(currentBPMChange.bpm)

        // Calculate milliseconds per tick
        let millisecondsPerTick = millisecondsPerBeat / Double(seq.info.timeUnit)

        // Calculate the duration of the ticks in this segment
        noteStartMs += Double(ticksInSegment) * millisecondsPerTick

        // If the noteStartTick falls within this segment, we can stop the loop
        if noteStartTick <= nextStartTick {
            break
        }
    }

    return noteStartMs
}

func timeToTick(_ time: Double, seq: Seq) -> Int32 {
    var accumulatedMs: Double = 0.0
    var currentTick: Int32 = 0

    for i in 0..<seq.info.bpm.count {
        let currentBPMChange = seq.info.bpm[i]
        let nextStartTick = (i + 1 < seq.info.bpm.count) ? seq.info.bpm[i + 1].tick : seq.info.endTick

        // Calculate milliseconds per beat and per tick for the current BPM
        let millisecondsPerBeat = 6000000.0 / Double(currentBPMChange.bpm)
        let millisecondsPerTick = millisecondsPerBeat / Double(seq.info.timeUnit)

        // Calculate the number of ticks in the current BPM segment
        let ticksInSegment = nextStartTick - currentBPMChange.tick

        // Calculate the duration in milliseconds for the entire segment
        let segmentDurationMs = Double(ticksInSegment) * millisecondsPerTick

        if accumulatedMs + segmentDurationMs > time {
            // The timeMs falls within this segment, calculate the exact tick
            let remainingMs = time - accumulatedMs
            let additionalTicks = Int32(remainingMs / millisecondsPerTick)
            return currentTick + additionalTicks
        }

        // Accumulate the total time in milliseconds
        accumulatedMs += segmentDurationMs

        // Update the current tick count
        currentTick += ticksInSegment
    }

    // If the timeMs exceeds the total song length, return the end tick
    return seq.info.endTick
}

enum BeatDirection {
    case next
    case previous
}

func numTickWithMeasures(_ givenTick: Int32, seq: Seq, direction: BeatDirection) -> Int32 {
    var currentTick = givenTick
    let measures = seq.info.measure

    if direction == .next {
        for i in 0..<measures.count {
            let currentMeasure = measures[i]
            let nextMeasureTick = (i + 1 < measures.count) ? measures[i + 1].tick : seq.info.endTick

            // Calculate ticks per beat for the current measure
            let ticksPerBeat = (seq.info.timeUnit * 4) / currentMeasure.denominator

            // Find the next numerator position within the measure
            let measureLength = ticksPerBeat * currentMeasure.num
            let positionInMeasure = currentTick % measureLength
            let nextNumeratorPosition = ((positionInMeasure / ticksPerBeat) + 1) * ticksPerBeat

            // Calculate the tick for the next numerator position
            let nextNumeratorTick = currentTick + (nextNumeratorPosition - positionInMeasure)

            // If the next numerator tick is within the current measure, return it
            if nextNumeratorTick < nextMeasureTick {
                return nextNumeratorTick
            }

            // If we reach here, the next numerator is in the next measure segment
            currentTick = nextMeasureTick
        }

        // If no suitable tick was found, return the end tick
        return seq.info.endTick
    } else {
        for i in (0..<measures.count).reversed() {
            let currentMeasure = measures[i]
            let previousMeasureTick = i > 0 ? measures[i - 1].tick : 0

            // Calculate ticks per beat for the current measure
            let ticksPerBeat = (seq.info.timeUnit * 4) / currentMeasure.denominator

            // Find the previous numerator position within the measure
            let measureLength = ticksPerBeat * currentMeasure.num
            let positionInMeasure = currentTick % measureLength
            let previousNumeratorPosition = (positionInMeasure / ticksPerBeat) * ticksPerBeat

            // Calculate the tick for the previous numerator position
            var previousNumeratorTick = currentTick - (positionInMeasure - previousNumeratorPosition)
            
            if previousNumeratorTick == givenTick {
                previousNumeratorTick -= ticksPerBeat
            }

            // If the previous numerator tick is within the current measure, return it
            if previousNumeratorTick >= currentMeasure.tick {
                return previousNumeratorTick
            }

            // If we reach here, the previous numerator is in the previous measure segment
            currentTick = previousMeasureTick
        }

        // If no suitable tick was found, return 0 (the start of the song)
        return 0
    }
}

func allNumeratorTicks(seq: Seq) -> [Int32] {
    var numeratorTicks: [Int32] = []
    let measures = seq.info.measure
    var currentTick: Int32 = 0

    for i in 0..<measures.count {
        let currentMeasure = measures[i]
        let nextMeasureTick = (i + 1 < measures.count) ? measures[i + 1].tick : seq.info.endTick

        // Calculate ticks per beat for the current measure
        let ticksPerBeat = (seq.info.timeUnit * 4) / currentMeasure.denominator

        // Find the next numerator position within the measure
        let measureLength = ticksPerBeat * currentMeasure.num
        while currentTick < nextMeasureTick {
            let positionInMeasure = currentTick % measureLength
            let nextNumeratorPosition = ((positionInMeasure / ticksPerBeat) + 1) * ticksPerBeat

            // Calculate the tick for the next numerator position
            let nextNumeratorTick = currentTick + (nextNumeratorPosition - positionInMeasure)

            // If the next numerator tick is within the current measure, return it
            if nextNumeratorTick < nextMeasureTick {
                numeratorTicks.append(nextNumeratorTick)
            }
            currentTick = nextNumeratorTick
        }

        // If we reach here, the next numerator is in the next measure segment
        currentTick = nextMeasureTick
    }

    return numeratorTicks
}

func allBeatTicks(seq: Seq) -> [Int32] {
    var beatTicks: [Int32] = []
    let measures = seq.info.measure
    var currentTick: Int32 = 0

    for i in 0..<measures.count {
        let currentMeasure = measures[i]
        let nextMeasureTick = (i + 1 < measures.count) ? measures[i + 1].tick : seq.info.endTick

        // Calculate ticks per beat for the current measure
        let ticksPerBeat = (seq.info.timeUnit * 4) / currentMeasure.denominator

        // Find the next numerator position within the measure
        let measureLength = ticksPerBeat * currentMeasure.num
        while currentTick < nextMeasureTick {
            let positionInMeasure = currentTick % measureLength
            let nextBeatPosition = ((positionInMeasure / ticksPerBeat) + currentMeasure.num) * ticksPerBeat

            // Calculate the tick for the next numerator position
            let nextBeatTick = currentTick + (nextBeatPosition - positionInMeasure)

            // If the next numerator tick is within the current measure, return it
            if nextBeatTick < nextMeasureTick {
                beatTicks.append(nextBeatTick)
            }
            currentTick = nextBeatTick
        }

        // If we reach here, the next numerator is in the next measure segment
        currentTick = nextMeasureTick
    }

    return beatTicks
}

func timeToOffset(_ time: Double, speed: Double) -> CGFloat {
    CGFloat(time) / 10.0 * speed
}

func tickToOffset(_ tick: Int32, seq: Seq, speed: Double) -> CGFloat {
    let time = tickToTime(tick, seq: seq)
    return timeToOffset(time, speed: speed)
}

func offsetToTime(_ offset: CGFloat, speed: Double) -> Double {
    return Double(offset * 10.0 / speed)
}

func offsetToTick(_ offset: CGFloat, seq: Seq, speed: Double) -> Int32 {
    let time = offsetToTime(offset, speed: speed)
    let tick = timeToTick(time, seq: seq)
    return tick
}
