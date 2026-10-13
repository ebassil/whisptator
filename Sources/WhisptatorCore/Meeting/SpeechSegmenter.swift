import Foundation

/// Consumes aligned PCM chunks from the session stream and emits speech
/// segments asynchronously via `onSegment`.
///
/// Implementations are called from the session's serial audio context; the
/// callback fires on the same context.
public protocol SpeechSegmenter: AnyObject {
    var onSegment: ((SpeechSegment) -> Void)? { get set }

    /// Feed the next aligned chunk of the continuous stream.
    func append(_ chunk: AlignedAudioChunk)

    /// End of stream: emit any in-flight segment and reset state.
    func flush()

    /// Discard all state (new session).
    func reset()
}
