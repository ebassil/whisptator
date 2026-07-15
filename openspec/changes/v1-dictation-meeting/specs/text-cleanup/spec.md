## ADDED Requirements

### Requirement: Deterministic cleanup pipeline
The system SHALL apply text cleanup as an ordered pipeline: filler removal → word replacement → snippet expansion → whitespace normalization. Each step is independently togglable.

#### Scenario: Full pipeline execution
- **WHEN** transcription completes and cleanup mode is set to "Clean"
- **THEN** the raw transcript passes through all enabled cleanup steps in order and the cleaned text is returned

#### Scenario: Raw mode bypasses cleanup
- **WHEN** cleanup mode is set to "Raw"
- **THEN** the raw transcript is returned without any processing

### Requirement: Filler word removal
The system SHALL remove filler words from the transcript. Default fillers include "um", "uh", and sentence-start fillers "so", "well", "like". The user SHALL be able to toggle individual fillers and add custom ones.

#### Scenario: Default fillers removed
- **WHEN** the transcript contains "um" or "uh" between words
- **THEN** these words are removed and surrounding whitespace is collapsed

#### Scenario: Sentence-start fillers removed
- **WHEN** a sentence begins with "So", "Well", or "Like"
- **THEN** the filler word is removed and the sentence starts with the next word

#### Scenario: Custom fillers
- **WHEN** the user adds a custom filler word in Settings
- **THEN** that word is also removed from transcripts

### Requirement: Word replacement
The system SHALL replace configured words/phrases in the transcript with their target replacements. Rules are case-insensitive with whole-word matching.

#### Scenario: Word replacement applied
- **WHEN** the transcript contains "aye pee eye" and a rule maps it to "API"
- **THEN** the output contains "API"

#### Scenario: Case-insensitive matching
- **WHEN** the transcript contains "Kubernetes" (capitalized) and a rule maps "kubernetes" to "K8s"
- **THEN** the output contains "K8s"

#### Scenario: Toggle without deletion
- **WHEN** the user disables a word replacement rule
- **THEN** the rule is skipped during processing but remains in the list for re-enabling

### Requirement: Snippet expansion
The system SHALL replace short trigger phrases with longer text expansions. Triggers are matched longest-first to prevent partial matches.

#### Scenario: Snippet expanded
- **WHEN** the transcript contains "my signature" and a snippet maps it to "Best regards, Emile"
- **THEN** the output contains "Best regards, Emile"

#### Scenario: Longest match wins
- **WHEN** the transcript contains "my signature" and both "my sig" and "my signature" are defined as triggers
- **THEN** the longer trigger "my signature" is expanded

### Requirement: Whitespace normalization
The system SHALL collapse multiple spaces into one, fix spacing around punctuation, and capitalize the first letter of the output.

#### Scenario: Multiple spaces collapsed
- **WHEN** the transcript contains multiple consecutive spaces
- **THEN** they are collapsed to a single space

#### Scenario: Punctuation spacing fixed
- **WHEN** the transcript contains a period, comma, or question mark preceded by a space
- **THEN** the space before the punctuation is removed

#### Scenario: First letter capitalized
- **WHEN** the cleaned text starts with a lowercase letter
- **THEN** the first letter is capitalized

### Requirement: Pipeline performance
The entire text cleanup pipeline SHALL complete in under 1 millisecond for texts up to 5000 characters.

#### Scenario: Pipeline speed
- **WHEN** a 5000-character transcript is processed through all cleanup steps
- **THEN** the total processing time is under 1 millisecond
