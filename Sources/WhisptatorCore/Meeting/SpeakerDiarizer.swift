import Foundation

/// One time range attributed to a speaker on the recording timeline (seconds).
public struct DiarizedSegment: Sendable, Equatable {
    public let start: Double
    public let end: Double
    public let speaker: String

    public init(start: Double, end: Double, speaker: String) {
        self.start = start
        self.end = end
        self.speaker = speaker
    }

    public var duration: Double { end - start }
}

/// Engine abstraction for speaker diarization (pyannote-based for this
/// release, replaceable without touching transcript output format).
public protocol SpeakerDiarizer: Sendable {
    /// True when the models are loaded/available and the engine can run.
    var isReady: Bool { get async }

    /// Produces speaker segments for the system (right) channel of the
    /// session audio. The mic channel is not routed through the engine —
    /// mic-dominant lines are labeled "Me" by the relabeler.
    func diarize(mp3URL: URL) async throws -> [DiarizedSegment]
}
