//
//  TimeOffsetConvertor.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/22.
//
import Foundation
import DRSKit

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
