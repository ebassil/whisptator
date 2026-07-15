# Local AI speech-to-text for macOS

**Session ID:** ses_09bf56a63ffe6WwLYNXEvmuaZl
**Created:** 7/15/2026, 2:30:43 PM
**Updated:** 7/15/2026, 3:50:22 PM

---

## User

Enter explore mode. Think deeply. Visualize freely. Follow the conversation wherever it goes.

**IMPORTANT: Explore mode is for thinking, not implementing.** You may read files, search code, and investigate the codebase, but you must NEVER write code or implement features. If the user asks you to implement something, remind them to exit explore mode first and create a change proposal. You MAY create OpenSpec artifacts (proposals, designs, specs) if the user asks—that's capturing thinking, not implementing.

**This is a stance, not a workflow.** There are no fixed steps, no required sequence, no mandatory outputs. You're a thinking partner helping the user explore.

**Store selection:** If the user names a store (a store is a standalone OpenSpec repo registered on this machine) or the work lives in one, run `openspec store list --json` to discover registered store ids, then pass `--store <id>` on the commands that read or write specs and changes (`new change`, `status`, `instructions`, `list`, `show`, `validate`, `archive`, `doctor`, `context`). Other commands do not take the flag. Hints printed by commands already carry the flag; keep it on follow-ups. Without a store, commands act on the nearest local `openspec/` root.

**Input**: The argument after `/opsx-explore` is whatever the user wants to think about. Could be:
- A vague idea: "real-time collaboration"
- A specific problem: "the auth system is getting unwieldy"
- A change name: "add-dark-mode" (to explore in context of that change)
- A comparison: "postgres vs sqlite for this"
- Nothing (just enter explore mode)

---

## The Stance

- **Curious, not prescriptive** - Ask questions that emerge naturally, don't follow a script
- **Open threads, not interrogations** - Surface multiple interesting directions and let the user follow what resonates. Don't funnel them through a single path of questions.
- **Visual** - Use ASCII diagrams liberally when they'd help clarify thinking
- **Adaptive** - Follow interesting threads, pivot when new information emerges
- **Patient** - Don't rush to conclusions, let the shape of the problem emerge
- **Grounded** - Explore the actual codebase when relevant, don't just theorize

---

## What You Might Do

Depending on what the user brings, you might:

**Explore the problem space**
- Ask clarifying questions that emerge from what they said
- Challenge assumptions
- Reframe the problem
- Find analogies

**Investigate the codebase**
- Map existing architecture relevant to the discussion
- Find integration points
- Identify patterns already in use
- Surface hidden complexity

**Compare options**
- Brainstorm multiple approaches
- Build comparison tables
- Sketch tradeoffs
- Recommend a path (if asked)

**Visualize**
```
┌─────────────────────────────────────────┐
│     Use ASCII diagrams liberally        │
├─────────────────────────────────────────┤
│                                         │
│      ┌────────┐         ┌────────┐      │
│      │ State  │────────▶│ State  │      │
│      │   A    │         │   B    │      │
│      └────────┘         └────────┘      │
│                                         │
│   System diagrams, state machines,      │
│   data flows, architecture sketches,    │
│   dependency graphs, comparison tables  │
│                                         │
└─────────────────────────────────────────┘
```

**Surface risks and unknowns**
- Identify what could go wrong
- Find gaps in understanding
- Suggest spikes or investigations

---

## OpenSpec Awareness

You have full context of the OpenSpec system. Use it naturally, don't force it.

### Check for context

At the start, quickly check what exists:
```bash
openspec list --json
```

This tells you:
- If there are active changes
- Their names, schemas, and status
- What the user might be working on

If the user mentioned a specific change name, read its artifacts for context.

### When no change exists

Think freely. When insights crystallize, you might offer:

- "This feels solid enough to start a change. Want me to create a proposal?"
- Or keep exploring - no pressure to formalize

### When a change exists

If the user mentions a change or you detect one is relevant:

1. **Resolve and read existing artifacts for context**
   - Run `openspec status --change "<name>" --json`.
   - Use `changeRoot`, `artifactPaths`, and `actionContext` from the status JSON.
   - Read existing files from `artifactPaths.<artifact>.existingOutputPaths`.

2. **Reference them naturally in conversation**
   - "Your design mentions using Redis, but we just realized SQLite fits better..."
   - "The proposal scopes this to premium users, but we're now thinking everyone..."

3. **Offer to capture when decisions are made**

    | Insight Type               | Where to Capture               |
    |----------------------------|--------------------------------|
    | New requirement discovered | `specs/<capability>/spec.md` |
    | Requirement changed        | `specs/<capability>/spec.md` |
    | Design decision made       | `design.md`                  |
    | Scope changed              | `proposal.md`                |
    | New work identified        | `tasks.md`                   |
    | Assumption invalidated     | Relevant artifact              |

   Example offers:
   - "That's a design decision. Capture it in design.md?"
   - "This is a new requirement. Add it to specs?"
   - "This changes scope. Update the proposal?"

4. **The user decides** - Offer and move on. Don't pressure. Don't auto-capture.

---

## What You Don't Have To Do

- Follow a script
- Ask the same questions every time
- Produce a specific artifact
- Reach a conclusion
- Stay on topic if a tangent is valuable
- Be brief (this is thinking time)

---

## Ending Discovery

There's no required ending. Discovery might:

- **Flow into a proposal**: "Ready to start? I can create a change proposal."
- **Result in artifact updates**: "Updated design.md with these decisions"
- **Just provide clarity**: User has what they need, moves on
- **Continue later**: "We can pick this up anytime"

When things crystallize, you might offer a summary - but it's optional. Sometimes the thinking IS the value.

---

## Guardrails

- **Don't implement** - Never write code or implement features. Creating OpenSpec artifacts is fine, writing application code is not.
- **Don't fake understanding** - If something is unclear, dig deeper
- **Don't rush** - Discovery is thinking time, not task time
- **Don't force structure** - Let patterns emerge naturally
- **Don't auto-capture** - Offer to save insights, don't just do it
- **Do visualize** - A good diagram is worth many paragraphs
- **Do explore the codebase** - Ground discussions in reality
- **Do question assumptions** - Including the user's and your own

I want to build Speech-to-text and AI text processing for macOS. Transcribe audio using on-device AI models. Your voice data stays on your Mac with local models. Use open weight models from huggingface models--openai--whisper-large-v3-turbo which I already have in my huggingface cache locally. Should have a global push-to-talk, global mac keyboard shortcuts to trigger recording audio and dictation. Transcribed text should be pasted in the window that is highlighted at the time of triggering the recording. Keep the UI simple. A configuration dialog to set the audio device for recording, the model to use from the huggingface local cache directory, typically ~/.cache/huggingface/hub, setting and resetting the shortcut keys that trigger push-to-talk and recording start/finish. I want the software to be as efficient a possible on MacOS, therefore, don't use languages such as Python or TypeScript. Dictation — Press a hotkey in any app, speak, text gets pasted. Hold for push-to-talk, or tap the hands-free shortcut to start and stop longer dictations. Works system-wide. The default uses Fn, but Settings -> Dictation can bind external-keyboard-friendly keys such as F13/F19 or End, modifier+key shortcuts, or modifier-only chords like Control+Option. A beta setting can pause supported Now Playing media while you dictate and resume it when capture stops. Meeting recording — Record system audio and microphone together, or pick microphone-only or system-only capture (microphone-only needs no Screen Recording permission). See a live local transcript preview, take notes during the call, then save the finalized transcript to the library with export, prompts, and chat. Choose how long to keep the source audio: keep it, auto-delete after a set number of days, or remove it right after transcription.   Text cleanup — Filler word removal, custom word replacements, text snippets with triggers. Deterministic pipeline, no LLM needed. Apple Silicon only (M1/M2/M3/M4). Nemotron and WhisperKit Transcribe require separate local model downloads before first use. 
Parakeet is best for English and its 25 supported European languages (v3 auto-detects among them). Get your inspiration from https://github.com/moona3k/macparakeet.

---

## Assistant (Build · Big Pickle · 9.2s)

_Thinking:_

The user wants to build a macOS speech-to-text and AI text processing application. Let me enter explore mode and think deeply about this. They've provided quite a detailed description. Let me first check what exists in the workspace and then think through the architecture.

Key requirements:
1. On-device speech-to-text using open-weight models (whisper-large-v3-turbo from HuggingFace)
2. Global push-to-talk and keyboard shortcuts
3. Transcribed text pasted into the active window
4. Simple UI with configuration dialog
5. Native macOS - no Python/TypeScript - efficient (likely Swift)


6. System-wide dictation with a hotkey trigger, pause Now Playing media optionally, and meeting recording that combines system audio and microphone7. Live transcript preview with text cleanup features like filler word removal and custom replacements
8. Apple Silicon optimized for M1/M2/M3/M4, using models like Parakeet or WhisperKit for local transcription9. I should check the macparakeet repo for inspiration on the implementation approach

Let me explore the workspace and understand what's already there.

**Tool: bash**

**Input:**
```json
{
  "command": "openspec list --json 2>/dev/null || echo \"No OpenSpec store found\"",
  "description": "Check existing OpenSpec changes"
}
```

**Output:**
```
{
  "changes": [],
  "root": {
    "path": "/Volumes/emile/PROJECTS/2026/whisptator",
    "source": "nearest"
  }
}

```

**Tool: read**

**Input:**
```json
{
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator"
}
```

**Output:**
```
<path>/Volumes/emile/PROJECTS/2026/whisptator</path>
<type>directory</type>
<entries>
.opencode/
openspec/

(2 entries)
</entries>
```

---

## Assistant (Build · Big Pickle · 5.5s)

_Thinking:_

The workspace is empty - just an OpenSpec root. Good, we're starting from scratch. Let me now fetch the macparakeet repo to understand its approach, and also check the whisper-large-v3-turbo model details.

Let me think through this carefully and explore what's needed.

The user wants:
1. A native macOS app (Swift, no Python/TypeScript)
2. On-device STT using Whisper large v3 turbo (from HuggingFace local cache)
3. Global keyboard shortcuts for push-to-talk and recording
4. Text pasted into the active window
5. Configuration dialog for audio device, model selection, shortcut keys
6. Meeting recording (system audio + microphone)


7. Live transcript preview
8. Text cleanup pipeline (filler words, custom replacements)
9. Apple Silicon optimized
10. Inspired by macparakeet

Now I need to check what macparakeet does and how it handles these features.

**Tool: webfetch**

**Input:**
```json
{
  "url": "https://github.com/moona3k/macparakeet",
  "format": "markdown"
}
```

**Output:**
```
                        GitHub - moona3k/macparakeet: Fast, local voice app for Mac — system-wide dictation, file & YouTube transcription, and meeting recording. Powered by Parakeet TDT on Apple Silicon. Free and open-source. · GitHub                                             

[Skip to content](#start-of-content)   

## Navigation Menu

Toggle navigation

[](/)

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fmoona3k%2Fmacparakeet)

Appearance settings

  

-   Platform
    
    -   AI CODE CREATION
        
        -   [
            
            GitHub CopilotWrite better code with AI
            
            ](https://github.com/features/copilot)
        -   [
            
            GitHub Copilot appDirect agents from issue to merge
            
            ](https://github.com/features/ai/github-app)
        -   [
            
            MCP RegistryNewIntegrate external tools
            
            ](https://github.com/mcp)
        
    -   DEVELOPER WORKFLOWS
        
        -   [
            
            ActionsAutomate any workflow
            
            ](https://github.com/features/actions)
        -   [
            
            CodespacesInstant dev environments
            
            ](https://github.com/features/codespaces)
        -   [
            
            IssuesPlan and track work
            
            ](https://github.com/features/issues)
        -   [
            
            Code ReviewManage code changes
            
            ](https://github.com/features/code-review)
        
    -   APPLICATION SECURITY
        
        -   [
            
            GitHub Advanced SecurityFind and fix vulnerabilities
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Code securitySecure your code as you build
            
            ](https://github.com/security/advanced-security/code-security)
        -   [
            
            Secret protectionStop leaks before they start
            
            ](https://github.com/security/advanced-security/secret-protection)
        
    -   EXPLORE
        
        -   [Why GitHub](https://github.com/why-github)
        -   [Documentation](https://docs.github.com)
        -   [Blog](https://github.blog)
        -   [Changelog](https://github.blog/changelog)
        -   [Marketplace](https://github.com/marketplace)
        
    
    [View all features](https://github.com/features)
    
-   Solutions
    
    -   BY COMPANY SIZE
        
        -   [Enterprises](https://github.com/enterprise)
        -   [Small and medium teams](https://github.com/team)
        -   [Startups](https://github.com/enterprise/startups)
        -   [Nonprofits](https://github.com/solutions/industry/nonprofits)
        
    -   BY USE CASE
        
        -   [App Modernization](https://github.com/solutions/use-case/app-modernization)
        -   [DevSecOps](https://github.com/solutions/use-case/devsecops)
        -   [DevOps](https://github.com/solutions/use-case/devops)
        -   [CI/CD](https://github.com/solutions/use-case/ci-cd)
        -   [View all use cases](https://github.com/solutions/use-case)
        
    -   BY INDUSTRY
        
        -   [Healthcare](https://github.com/solutions/industry/healthcare)
        -   [Financial services](https://github.com/solutions/industry/financial-services)
        -   [Manufacturing](https://github.com/solutions/industry/manufacturing)
        -   [Government](https://github.com/solutions/industry/government)
        -   [View all industries](https://github.com/solutions/industry)
        
    
    [View all solutions](https://github.com/solutions)
    
-   Resources
    
    -   EXPLORE BY TOPIC
        
        -   [AI](https://github.com/resources/articles?topic=ai)
        -   [Software Development](https://github.com/resources/articles?topic=software-development)
        -   [DevOps](https://github.com/resources/articles?topic=devops)
        -   [Security](https://github.com/resources/articles?topic=security)
        -   [View all topics](https://github.com/resources/articles)
        
    -   EXPLORE BY TYPE
        
        -   [Customer stories](https://github.com/customer-stories)
        -   [Events & webinars](https://github.com/resources/events)
        -   [Ebooks & reports](https://github.com/resources/whitepapers)
        -   [Business insights](https://github.com/solutions/executive-insights)
        -   [GitHub Skills](https://skills.github.com)
        
    -   SUPPORT & SERVICES
        
        -   [Documentation](https://docs.github.com)
        -   [Customer support](https://support.github.com)
        -   [Community forum](https://github.com/orgs/community/discussions)
        -   [Trust center](https://github.com/trust-center)
        -   [Partners](https://github.com/partners)
        
    
    [View all resources](https://github.com/resources)
    
-   Open Source
    
    -   COMMUNITY
        
        -   [
            
            GitHub SponsorsFund open source developers
            
            ](https://github.com/open-source/sponsors)
        
    -   PROGRAMS
        
        -   [Security Lab](https://securitylab.github.com)
        -   [Maintainer Community](https://maintainers.github.com)
        -   [Accelerator](https://github.com/open-source/accelerator)
        -   [GitHub Stars](https://stars.github.com)
        -   [Archive Program](https://archiveprogram.github.com)
        
    -   REPOSITORIES
        
        -   [Topics](https://github.com/topics)
        -   [Trending](https://github.com/trending)
        -   [Collections](https://github.com/collections)
        
    
-   Enterprise
    
    -   ENTERPRISE SOLUTIONS
        
        -   [
            
            Enterprise platformAI-powered developer platform
            
            ](https://github.com/enterprise)
        
    -   AVAILABLE ADD-ONS
        
        -   [
            
            GitHub Advanced SecurityEnterprise-grade security features
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Copilot for BusinessEnterprise-grade AI features
            
            ](https://github.com/features/copilot/copilot-business)
        -   [
            
            Premium SupportEnterprise-grade 24/7 support
            
            ](https://github.com/enterprise/premium-support)
        
    
-   [Pricing](https://github.com/pricing)

Search or jump to...

# Search code, repositories, users, issues, pull requests...

Search

Clear

[Search syntax tips](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax)

# Provide feedback

We read every piece of feedback, and take your input very seriously.

 Include my email address so I can be contacted

Cancel Submit feedback

# Saved searches

## Use saved searches to filter your results more quickly

Name  

Query 

To see all available qualifiers, see our [documentation](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax).

Cancel Create saved search

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fmoona3k%2Fmacparakeet)

[Sign up](/signup?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F%3Cuser-name%3E%2F%3Crepo-name%3E&source=header-repo&source_repo=moona3k%2Fmacparakeet)

Appearance settings

Resetting focus

You signed in with another tab or window. Reload to refresh your session. You signed out in another tab or window. Reload to refresh your session. You switched accounts on another tab or window. Reload to refresh your session. Dismiss alert

[moona3k](/moona3k) / **[macparakeet](/moona3k/macparakeet)** Public

-   ### Uh oh!
    
    There was an error while loading. Please reload this page.
    
-   [Notifications](/login?return_to=%2Fmoona3k%2Fmacparakeet) You must be signed in to change notification settings
-   [Fork 47](/login?return_to=%2Fmoona3k%2Fmacparakeet)
-   [Star 482](/login?return_to=%2Fmoona3k%2Fmacparakeet)
    

-   [Code](/moona3k/macparakeet)
-   [Issues 64](/moona3k/macparakeet/issues)
-   [Pull requests 2](/moona3k/macparakeet/pulls)
-   [Discussions](/moona3k/macparakeet/discussions)
-   [Actions](/moona3k/macparakeet/actions)
-   [Projects](/moona3k/macparakeet/projects)
-   [Security and quality 0](/moona3k/macparakeet/security)
-   [Insights](/moona3k/macparakeet/pulse)

Additional navigation options

-   [Code](/moona3k/macparakeet)
-   [Issues](/moona3k/macparakeet/issues)
-   [Pull requests](/moona3k/macparakeet/pulls)
-   [Discussions](/moona3k/macparakeet/discussions)
-   [Actions](/moona3k/macparakeet/actions)
-   [Projects](/moona3k/macparakeet/projects)
-   [Security and quality](/moona3k/macparakeet/security)
-   [Insights](/moona3k/macparakeet/pulse)

 [](/moona3k/macparakeet)

# moona3k/macparakeet

 main

[Branches](/moona3k/macparakeet/branches)[Tags](/moona3k/macparakeet/tags)

[](/moona3k/macparakeet/branches)[](/moona3k/macparakeet/tags)

Go to file

Code

Open more actions menu

## Folders and files

Name

Name

Last commit message

Last commit date

## Latest commit

## History

[2,086 Commits](/moona3k/macparakeet/commits/main/)

[](/moona3k/macparakeet/commits/main/)2,086 Commits

[.github](/moona3k/macparakeet/tree/main/.github ".github")

[.github](/moona3k/macparakeet/tree/main/.github ".github")

[Assets](/moona3k/macparakeet/tree/main/Assets "Assets")

[Assets](/moona3k/macparakeet/tree/main/Assets "Assets")

[Sources](/moona3k/macparakeet/tree/main/Sources "Sources")

[Sources](/moona3k/macparakeet/tree/main/Sources "Sources")

[Tests](/moona3k/macparakeet/tree/main/Tests "Tests")

[Tests](/moona3k/macparakeet/tree/main/Tests "Tests")

[benchmarks](/moona3k/macparakeet/tree/main/benchmarks "benchmarks")

[benchmarks](/moona3k/macparakeet/tree/main/benchmarks "benchmarks")

[brand-assets](/moona3k/macparakeet/tree/main/brand-assets "brand-assets")

[brand-assets](/moona3k/macparakeet/tree/main/brand-assets "brand-assets")

[diagnostics](/moona3k/macparakeet/tree/main/diagnostics "diagnostics")

[diagnostics](/moona3k/macparakeet/tree/main/diagnostics "diagnostics")

[docs](/moona3k/macparakeet/tree/main/docs "docs")

[docs](/moona3k/macparakeet/tree/main/docs "docs")

[integrations](/moona3k/macparakeet/tree/main/integrations "integrations")

[integrations](/moona3k/macparakeet/tree/main/integrations "integrations")

[marketing/video](/moona3k/macparakeet/tree/main/marketing/video "This path skips through empty directories")

[marketing/video](/moona3k/macparakeet/tree/main/marketing/video "This path skips through empty directories")

[plans](/moona3k/macparakeet/tree/main/plans "plans")

[plans](/moona3k/macparakeet/tree/main/plans "plans")

[screenshots](/moona3k/macparakeet/tree/main/screenshots "screenshots")

[screenshots](/moona3k/macparakeet/tree/main/screenshots "screenshots")

[scripts](/moona3k/macparakeet/tree/main/scripts "scripts")

[scripts](/moona3k/macparakeet/tree/main/scripts "scripts")

[spec](/moona3k/macparakeet/tree/main/spec "spec")

[spec](/moona3k/macparakeet/tree/main/spec "spec")

[.editorconfig](/moona3k/macparakeet/blob/main/.editorconfig ".editorconfig")

[.editorconfig](/moona3k/macparakeet/blob/main/.editorconfig ".editorconfig")

[.git-blame-ignore-revs](/moona3k/macparakeet/blob/main/.git-blame-ignore-revs ".git-blame-ignore-revs")

[.git-blame-ignore-revs](/moona3k/macparakeet/blob/main/.git-blame-ignore-revs ".git-blame-ignore-revs")

[.gitattributes](/moona3k/macparakeet/blob/main/.gitattributes ".gitattributes")

[.gitattributes](/moona3k/macparakeet/blob/main/.gitattributes ".gitattributes")

[.gitignore](/moona3k/macparakeet/blob/main/.gitignore ".gitignore")

[.gitignore](/moona3k/macparakeet/blob/main/.gitignore ".gitignore")

[.no-mistakes.yaml](/moona3k/macparakeet/blob/main/.no-mistakes.yaml ".no-mistakes.yaml")

[.no-mistakes.yaml](/moona3k/macparakeet/blob/main/.no-mistakes.yaml ".no-mistakes.yaml")

[.swift-format](/moona3k/macparakeet/blob/main/.swift-format ".swift-format")

[.swift-format](/moona3k/macparakeet/blob/main/.swift-format ".swift-format")

[AGENTS.md](/moona3k/macparakeet/blob/main/AGENTS.md "AGENTS.md")

[AGENTS.md](/moona3k/macparakeet/blob/main/AGENTS.md "AGENTS.md")

[CLAUDE.md](/moona3k/macparakeet/blob/main/CLAUDE.md "CLAUDE.md")

[CLAUDE.md](/moona3k/macparakeet/blob/main/CLAUDE.md "CLAUDE.md")

[LICENSE](/moona3k/macparakeet/blob/main/LICENSE "LICENSE")

[LICENSE](/moona3k/macparakeet/blob/main/LICENSE "LICENSE")

[Package.resolved](/moona3k/macparakeet/blob/main/Package.resolved "Package.resolved")

[Package.resolved](/moona3k/macparakeet/blob/main/Package.resolved "Package.resolved")

[Package.swift](/moona3k/macparakeet/blob/main/Package.swift "Package.swift")

[Package.swift](/moona3k/macparakeet/blob/main/Package.swift "Package.swift")

[README.md](/moona3k/macparakeet/blob/main/README.md "README.md")

[README.md](/moona3k/macparakeet/blob/main/README.md "README.md")

[THIRD\_PARTY\_LICENSES.md](/moona3k/macparakeet/blob/main/THIRD_PARTY_LICENSES.md "THIRD_PARTY_LICENSES.md")

[THIRD\_PARTY\_LICENSES.md](/moona3k/macparakeet/blob/main/THIRD_PARTY_LICENSES.md "THIRD_PARTY_LICENSES.md")

View all files

## Repository files navigation

-   [README](#)
-   [License](#)

More items

[![MacParakeet app icon](/moona3k/macparakeet/raw/main/Assets/AppIcon-1024x1024.png)](/moona3k/macparakeet/blob/main/Assets/AppIcon-1024x1024.png)

# MacParakeet

[](#macparakeet)

Fast voice app for Mac with fully local speech and optional AI. Free and open-source.

*There are many voice transcription/dictation apps, but this one is mine.*

[macparakeet.com](https://macparakeet.com)

[![Download DMG](https://camo.githubusercontent.com/260ba230a549b64a949b36450a179011b108381365d791086b5c717631834392/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f776e6c6f61642d444d472d4538364233422e7376673f7374796c653d666f722d7468652d6261646765266c6f676f3d6170706c65266c6f676f436f6c6f723d7768697465)](https://downloads.macparakeet.com/MacParakeet.dmg)

[![Ask DeepWiki](https://camo.githubusercontent.com/0f5ae213ac378635adeb5d7f13cef055ad2f7d9a47b36de7b1c67dbe09f609ca/68747470733a2f2f6465657077696b692e636f6d2f62616467652e737667)](https://deepwiki.com/moona3k/macparakeet) [![GPL-3.0 License](https://camo.githubusercontent.com/8b59d97f09166dc0016167b7b0cf9a5830ee03c63f582ebd7ed5848ad497f1ef/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f6c6963656e73652d47504c2d2d332e302d626c75652e737667)](/moona3k/macparakeet/blob/main/LICENSE) [![macOS 14.2+](https://camo.githubusercontent.com/5f91d0e45d62fcb5c3439a987c0465ce79f5d62ea07c3694d804557492de8e2b/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f6d61634f532d31342e322532422d3030303030302e737667)](https://camo.githubusercontent.com/5f91d0e45d62fcb5c3439a987c0465ce79f5d62ea07c3694d804557492de8e2b/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f6d61634f532d31342e322532422d3030303030302e737667) [![Swift 6](https://camo.githubusercontent.com/9c07f130968269acc5ece3579025c6cb30c1983d5987786762a70928a59dc193/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f53776966742d362e302d4630353133382e737667)](https://camo.githubusercontent.com/9c07f130968269acc5ece3579025c6cb30c1983d5987786762a70928a59dc193/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f53776966742d362e302d4630353133382e737667) [![CI status](https://camo.githubusercontent.com/17530d23abc3117ca784b69f62781f3b96c7596a8ee471e7bc66db7f52e7eb75/68747470733a2f2f696d672e736869656c64732e696f2f6769746875622f616374696f6e732f776f726b666c6f772f7374617475732f6d6f6f6e61336b2f6d6163706172616b6565742f63692e796d6c3f6272616e63683d6d61696e266c6162656c3d4349)](https://github.com/moona3k/macparakeet/actions/workflows/ci.yml) [![Apple Silicon only](https://camo.githubusercontent.com/ca06967cbd8a85031738dd312ce0fb1bb90d039e920c46d7dfa6af2468e0a549/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f4170706c6525323053696c69636f6e2d6f6e6c792d3333333333332e737667)](https://camo.githubusercontent.com/ca06967cbd8a85031738dd312ce0fb1bb90d039e920c46d7dfa6af2468e0a549/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f4170706c6525323053696c69636f6e2d6f6e6c792d3333333333332e737667)

[![MacParakeet — Transcribe tab with YouTube, file drop, and Record Meeting tile](/moona3k/macparakeet/raw/main/Assets/screenshots/transcribe.png?v=4)](/moona3k/macparakeet/blob/main/Assets/screenshots/transcribe.png?v=4)

[![MacParakeet — Transcription library with thumbnails](/moona3k/macparakeet/raw/main/Assets/screenshots/library.png?v=4)](/moona3k/macparakeet/blob/main/Assets/screenshots/library.png?v=4)

[![MacParakeet — YouTube transcript with synced video playback and timestamped transcript, summary, and chat tabs](/moona3k/macparakeet/raw/main/Assets/screenshots/youtube-transcript.png?v=1)](/moona3k/macparakeet/blob/main/Assets/screenshots/youtube-transcript.png?v=1)

[![MacParakeet — Dictation Stats with streak heatmap and top apps](/moona3k/macparakeet/raw/main/Assets/screenshots/dictations.png?v=4)](/moona3k/macparakeet/blob/main/Assets/screenshots/dictations.png?v=4)

[![MacParakeet — Live meeting recording with floating pill and Notes/Transcript/Ask panel](/moona3k/macparakeet/raw/main/Assets/screenshots/meeting-recording.png?v=4)](/moona3k/macparakeet/blob/main/Assets/screenshots/meeting-recording.png?v=4)

[![MacParakeet — Ask tab summarizing a live meeting with quick-prompt starters](/moona3k/macparakeet/raw/main/Assets/screenshots/meeting-ask.png?v=4)](/moona3k/macparakeet/blob/main/Assets/screenshots/meeting-ask.png?v=4)

---

MacParakeet runs NVIDIA's Parakeet TDT on Apple's Neural Engine via [FluidAudio](https://github.com/FluidInference/FluidAudio) CoreML. The current stable release includes system-wide dictation, file/URL transcription, meeting recording with selectable microphone/system capture, meeting calendar support, Parakeet v3/v2/Unified model selection, optional local Nemotron Beta and WhisperKit recognition, and Transforms for selected-text rewrites. Current `main` adds opt-in Cohere Transcribe and other unreleased development work. All speech recognition happens on your Mac.

## Release status

[](#release-status)

The [notarized DMG](https://downloads.macparakeet.com/MacParakeet.dmg) is the stable release channel.

Channel

Status

Includes

Stable DMG

Recommended for normal use

Dictation, file/video/media URL and podcast transcription, meeting recording with selectable mic/system capture and audio-retention controls, meeting calendar reminders and opt-in auto-start, Transforms, VAD-guided meeting live-preview chunking, Parakeet v3/v2/Unified model selection, optional Nemotron Beta and WhisperKit, exports, vocabulary, AI features

`main` branch

Development

Latest stable release plus Cohere Transcribe, meeting echo-cancellation/cleaned-mic artifact work for the next release train, recognition-time custom vocabulary boosting, and developer-gated in-process MLX local LLM groundwork that is compiled/tested but hidden from normal users

Meeting calendar support is live in the stable DMG. MacParakeet reads upcoming meetings from the local macOS Calendar store through EventKit, can show reminders, and can optionally start a recording after a countdown. Auto-start defaults to `.off` and must be opted into; recordings still stop manually.

## What it does

[](#what-it-does)

**Dictation** — Press a hotkey in any app, speak, text gets pasted. Hold for push-to-talk, or tap the hands-free shortcut to start and stop longer dictations. Works system-wide. The default uses Fn, but Settings -> Dictation can bind external-keyboard-friendly keys such as F13/F19 or End, modifier+key shortcuts, or modifier-only chords like Control+Option. A beta setting can pause supported Now Playing media while you dictate and resume it when capture stops.

**File & URL transcription** — Drag one or many audio/video files, drop a folder, use the multi-select picker, or paste any video or podcast link. YouTube, X, Vimeo, TikTok, Instagram, Facebook, Apple Podcasts, and any other site `yt-dlp` supports all work — there's no fixed list; the card recognizes the platform and shows its mark as you paste. Apple Podcasts links resolve through the iTunes lookup API to the episode's audio enclosure (no scraping), then download and transcribe locally just like a YouTube video. The CLI also does **freetext podcast search** — `macparakeet-cli transcribe --podcast "Lex Fridman episode 400"` searches the iTunes directory, parses the show's RSS feed, picks the episode, and transcribes it. Local-file batches run sequentially, keep finished results in the Library, and can be cancelled as a group. Full transcript output includes word-level timestamps and speaker labels when the selected speech engine provides timings; Cohere produces plain text only. Completion chime/banner and export to 7 formats (TXT, Markdown, SRT, VTT, DOCX, PDF, JSON) are supported. Assign global hotkeys to trigger File or URL transcription from anywhere.

**Meeting recording** — Record system audio and microphone together, or pick microphone-only or system-only capture (microphone-only needs no Screen Recording permission). See a live local transcript preview, take notes during the call, then save the finalized transcript to the library with export, prompts, and chat. Choose how long to keep the source audio: keep it, auto-delete after a set number of days, or remove it right after transcription.

**Meeting calendar support** — Grant Calendar access to get local reminders for upcoming meetings or opt into auto-start. MacParakeet uses calendars already configured in macOS Calendar through EventKit; it does not add Google or Microsoft sign-ins, and recordings still stop manually.

**Text cleanup** — Filler word removal, custom word replacements, text snippets with triggers. Deterministic pipeline, no LLM needed.

**AI features** — Optional summaries, chat, AI formatter, and Transforms for rewriting selected text through your configured provider. Connect any cloud provider (OpenAI, Anthropic, Gemini, OpenRouter), local runtime (Ollama, LM Studio), OpenAI-compatible endpoint, or CLI tool (Claude Code, Codex). Entirely opt-in.

### Limitations

[](#limitations)

-   Apple Silicon only (M1/M2/M3/M4)
-   Parakeet is best for English and its 25 supported European languages (v3 auto-detects among them); the v3 default is not a CJK/Korean engine
-   Nemotron is Beta while real-world quality is benchmarked
-   Nemotron, WhisperKit, and Cohere Transcribe require separate local model downloads before first use
-   Cohere is batch-only: it can be used for dictation after recording stops, file transcription, and meeting finalization, but it does not show live dictation preview or meeting live-preview chunks and does not provide word timestamps/speaker labels

## ASR benchmarks

[](#asr-benchmarks)

The current ASR benchmark lives in [`benchmarks/asr/`](/moona3k/macparakeet/blob/main/benchmarks/asr). It scores every engine through the same normalizer, uses full LibriSpeech `test-clean` + `test-other` for English, uses capped FLEURS slices for multilingual coverage, and reports hardware-specific speed/memory on an Apple M4 Pro with 48 GB RAM on macOS 15. Run `benchmarks/asr/run_all.sh verify` to re-score the committed hypotheses and validate the benchmark contract.

English accuracy, full LibriSpeech sets:

Engine

Runtime

Macro WER

`test-clean` WER

`test-other` WER

Cohere Transcribe q8

FluidAudio CoreML

**2.07%**

1.49%

**2.65%**

Parakeet Unified

FluidAudio CoreML

2.38%

1.64%

3.13%

Parakeet v2

FluidAudio CoreML

2.57%

1.86%

3.27%

Whisper large-v3 turbo

WhisperKit

3.00%

1.96%

4.04%

Parakeet v3 default

FluidAudio CoreML

3.22%

2.31%

4.14%

Nemotron English Beta

FluidAudio CoreML

3.70%

2.40%

5.01%

Nemotron Multilingual Beta

FluidAudio CoreML

5.17%

3.17%

7.16%

Multilingual coverage, FLEURS first 150 utterances per language. English is WER; Korean, Japanese, and Chinese are CER:

Engine

en

ko

ja

zh

Notes

Cohere Transcribe q8

4.69

7.15

**5.56**

12.49

Best Japanese; clean English/Korean/Chinese are statistical ties with the best alternative

Whisper large-v3 turbo

5.71

**6.37**

13.42

**11.56**

Light broad-language fallback

Nemotron Multilingual Beta

7.08

9.32

15.29

19.47

Still Beta by quality evidence

Parakeet v3 default

**4.40**

171.2

159.2

124.1

Works for supported European languages; fails CJK/Korean here by romanizing output

Speed and memory, same Apple M4 Pro micro-benchmark:

Engine family

Cold start

Steady throughput

Peak RSS

Parakeet v2/v3/Unified

0.38-0.93 s

~81-93x realtime

115-131 MB

Nemotron EN/Multilingual Beta

0.70-0.87 s

~57-61x realtime

141-142 MB

Whisper large-v3 turbo

2.29 s

~14x realtime

274 MB

Cohere Transcribe q8

~73 s

~11x realtime

~11.6 GB

Cohere is the most accurate on-device engine in this benchmark, but its statistically clear wins are noisy English and Japanese. Clean English, Korean, and Chinese are ties with the best alternative under the paired-bootstrap test. Parakeet remains the default because it is fast, low-memory, timestamped, and strong on supported languages. Cohere is opt-in for accuracy-critical batch work on 16 GB+ Macs. The Cohere speed/memory row is a reference measurement; see [`benchmarks/asr/`](/moona3k/macparakeet/blob/main/benchmarks/asr) for method notes.

## Get it

[](#get-it)

**Download:** Grab the [notarized DMG](https://downloads.macparakeet.com/MacParakeet.dmg) or visit [macparakeet.com](https://macparakeet.com). Drag to Applications, done.

First launch downloads the default Parakeet CoreML build (~465 MB) plus speaker-detection assets (~130 MB) as needed. Parakeet v2 and v3 cache independently if you install both. Everything works fully offline after that.

The DMG is the stable release.

**Mac app (Homebrew cask):**

brew install --cask macparakeet

This is the official [`homebrew/cask`](https://github.com/Homebrew/homebrew-cask/blob/HEAD/Casks/m/macparakeet.rb) entry — no tap required. It installs the same notarized DMG as the direct download, and in-app updates continue through Sparkle.

**Standalone CLI (Homebrew):**

brew install moona3k/tap/macparakeet-cli
macparakeet-cli --version
macparakeet-cli health --json

The Homebrew formula installs the public `macparakeet-cli` surface plus Homebrew-managed `ffmpeg` and `yt-dlp`. It shares the same local database and model cache as the app.

**Build from source:**

git clone https://github.com/moona3k/macparakeet.git
cd macparakeet
swift test
scripts/dev/run\_app.sh    # build, sign, launch

The dev script creates a signed `.app` bundle so macOS grants mic and accessibility permissions. It disables target-level Xcode signing, then signs the finished bundle with the best available local identity. Override with `MACPARAKEET_CODESIGN_IDENTITY="Your Identity"` if needed.

## Command line and agent automation

[](#command-line-and-agent-automation)

`macparakeet-cli` is the public automation surface for MacParakeet: the canonical Swift-native interface to Parakeet TDT on Apple Silicon, plus the scriptable entry point for MacParakeet's local library, model cache, prompts, meetings, and JSON contracts. Use [`integrations/README.md`](/moona3k/macparakeet/blob/main/integrations/README.md) for the agent-facing automation guide and [`Sources/CLI/CHANGELOG.md`](/moona3k/macparakeet/blob/main/Sources/CLI/CHANGELOG.md) for compatibility notes.

Discover the current machine-readable command catalog:

macparakeet-cli spec --json
macparakeet-cli health --json

Transcribe files, folders, media URLs, or podcasts:

macparakeet-cli transcribe /path/to/audio.mp3
macparakeet-cli transcribe /path/to/audio.mp3 --format transcript --no-history
macparakeet-cli transcribe lecture1.m4a lecture2.m4a --output-dir Transcripts --format transcript
macparakeet-cli transcribe --podcast "Lex Fridman episode 400" --format json
macparakeet-cli transcribe /path/to/meeting.m4a --engine nemotron --language auto --format json
macparakeet-cli transcribe /path/to/japanese.m4a --engine cohere --language ja --format json
macparakeet-cli transcribe /path/to/korean.mp3 --engine whisper --language ko --format json

Manage local models and shared app/CLI defaults:

macparakeet-cli models download nemotron-multilingual-1120ms
macparakeet-cli models download cohere-transcribe
macparakeet-cli models download whisper-large-v3-v20240930-turbo-632MB
macparakeet-cli models list
macparakeet-cli models select parakeet-v3
macparakeet-cli config set parakeet-model v2
macparakeet-cli models status

Inspect and update local history, saved meetings, and agent-readable artifacts:

macparakeet-cli history transcriptions --json
macparakeet-cli retranscribe <id-or-prefix-or-title\> --update --json
macparakeet-cli meetings list --json
macparakeet-cli meetings show <meeting-id\> --json
macparakeet-cli meetings artifact <meeting-id\> --json
macparakeet-cli meetings export <meeting-id\> --stdout --format json

Use `--format transcript` for transcript-only stdout in shell pipelines. Add `--no-history` when you want a one-off transcription without saving a completed row to MacParakeet history. Multiple inputs or `--output-dir` write one transcript file per input. `models list` and `models select` inspect or update the shared speech default used by the app and `--engine app-default`; Parakeet rows are `parakeet-v3`, `parakeet-v2`, and `parakeet-unified`, Nemotron rows are `nemotron-multilingual-1120ms` and `nemotron-english-1120ms`, Cohere is `cohere-transcribe`, and Whisper rows use the configured `whisper-*` model id. The Nemotron, Cohere, and Whisper CLI commands above require their local models to be downloaded first. When developing from source, prefix the same commands with `swift run`.

## Tech stack

[](#tech-stack)

Layer

Choice

STT

Parakeet via [FluidAudio](https://github.com/FluidInference/FluidAudio) CoreML (`v3` multilingual default, `v2` English-only opt-in, `unified` English-only punctuated opt-in) + optional local Nemotron Beta, Cohere Transcribe, and WhisperKit engines

STT orchestration

Shared runtime + explicit scheduler with a reserved dictation slot and a shared meeting/file slot; speech-engine routing and meeting-session pinning

Language

Swift 6 language mode (package tools-version 5.9) + SwiftUI

Database

SQLite via GRDB

Auto-updates

Sparkle 2

Media URLs

yt-dlp

Podcasts

Apple Podcasts via iTunes lookup API + native enclosure downloader

Platform

macOS 14.2+, Apple Silicon

## Vocabulary

[](#vocabulary)

The Vocabulary panel controls how dictated text is cleaned up before pasting. No AI involved — it's a fast, deterministic pipeline that runs in under 1ms.

You choose between two **processing modes**:

-   **Raw** — Paste exactly what the speech engine produces, no changes
-   **Clean** (default) — Run the text through a multi-step pipeline before pasting

**The Clean pipeline** applies these steps in order:

1.  **Filler removal** — Strips "um", "uh", and sentence-start fillers like "so", "well", "like"
2.  **Custom words** — Applies your word replacement rules (e.g., "aye pee eye" becomes "API", or "kubernetes" gets capitalized to "Kubernetes"). Case-insensitive, whole-word matching. Words can be toggled on/off without deleting.
3.  **Voice Return** — If you've defined one or more trigger phrases (e.g., "press return" or "zatwierdź") and speak one at the end of a dictation, it's stripped from the output and a Return keypress is simulated after paste
4.  **Snippet expansion** — Replaces short trigger phrases with longer text (e.g., "my signature" expands to "Best regards, David"). Triggers are natural language phrases because that's what the speech engine outputs. Matched longest-first to prevent collisions.
5.  **Whitespace cleanup** — Collapses spaces, fixes punctuation spacing, capitalizes the first letter

Every dictation stores both the raw and clean transcript so you can always see what changed.

## AI Features

[](#ai-features)

AI features are entirely **opt-in** and separate from speech recognition — transcription is always local. The LLM only sees transcript text, never audio.

**What it does:**

-   **Summarize** — After a transcription finishes, click Summarize and pick a prompt ("Summary", "Action Items & Decisions", "Chapter Breakdown", etc.) or write your own. The LLM processes the transcript and streams back a summary. You can generate multiple summaries per transcript, each in its own tab. Prompts marked as auto-run generate summaries automatically for new transcriptions.
-   **Chat** — Ask questions about a transcript in a multi-turn chat interface. The LLM answers based on the transcript content.
-   **AI formatter** — Optionally run your dictation and file transcripts through your AI provider to clean up grammar, punctuation, and paragraphing. Toggle on/off, customize the prompt, or reset to default.
-   **Transforms** — Select text in any app and press a bound Transform hotkey, such as `Control-Option-1` for Polish, to rewrite the selection through your configured LLM provider.

**Supported providers:**

Type

Options

Cloud

Anthropic (Claude), OpenAI, Google Gemini, OpenRouter

Local

Ollama, LM Studio

Custom

OpenAI-Compatible (any API-shaped endpoint — vLLM, LocalAI, LiteLLM, llama.cpp server, third-party hosts)

CLI subprocess

Claude Code, Codex, or another configured command

**Setup:** In Settings → AI Provider, pick a provider, enter an API key (cloud) or confirm the local server/CLI command is available, select a model, and hit Test Connection. Cloud providers store keys in the macOS Keychain. Ollama and LM Studio can keep LLM inference on-device. CLI subprocess providers run the configured command locally, but that command may contact its own cloud service.

## Privacy

[](#privacy)

All speech recognition runs locally. Parakeet uses the Neural Engine; optional Nemotron Beta, Cohere Transcribe, and WhisperKit engines also run on-device. Your audio never leaves your Mac.

-   **No cloud STT.** The model runs on-device. No audio is transmitted.
-   **No accounts.** No login, no email, no registration.
-   **Opt-out telemetry.** Non-identifying usage analytics and crash reporting go to a self-hosted endpoint only when telemetry is enabled. No persistent IDs, no IP storage, and no transcript/audio content is transmitted. [Source code is right here](/moona3k/macparakeet/blob/main/Sources/MacParakeetCore/Services/Telemetry/TelemetryService.swift) — verify it yourself.
-   **Temp files cleaned up.** Audio deleted after transcription unless you save it. Saved meeting audio follows your retention setting (kept by default).

**What does use the network:** AI summaries, chat/Meeting Ask, AI Formatter, and Transforms connect to configured LLM providers, or to whatever service a configured CLI tool chooses to use, when you choose them. Sparkle checks for app updates. Media URL transcription downloads via yt-dlp; Apple Podcasts links query the public iTunes lookup API to find the episode audio, then download it. Telemetry and crash reports go to our self-hosted server unless you opt out. Core dictation and transcription stay fully offline.

**Note:** Builds from source also send telemetry by default. Opt out in Settings or set `MACPARAKEET_TELEMETRY_URL` to override.

## Contributing

[](#contributing)

-   **Report bugs** — [Open an issue](https://github.com/moona3k/macparakeet/issues) with steps to reproduce and relevant logs or screenshots.
-   **Discuss new work first** — For features or behavior changes, open an issue before starting a PR so we can agree on scope and product fit.
-   **Submit scoped PRs** — Once the issue direction is clear, fork, make the scoped changes, run `swift test`, and link the issue in the PR.
-   **Read the specs** — Architecture decisions and feature specs live in `spec/`
-   **Using a coding agent?** Point it at [`AGENTS.md`](/moona3k/macparakeet/blob/main/AGENTS.md) — the canonical build/test commands, code style, repo conventions, and links to deeper context for Claude Code, Codex, and friends.

## Support

[](#support)

MacParakeet is free and open source. If it's useful to you, consider [sponsoring](https://github.com/sponsors/moona3k).

## License

[](#license)

GPL-3.0. Free software. [Full license](/moona3k/macparakeet/blob/main/LICENSE).

## About

Fast, local voice app for Mac — system-wide dictation, file & YouTube transcription, and meeting recording. Powered by Parakeet TDT on Apple Silicon. Free and open-source.

[macparakeet.com](https://macparakeet.com "https://macparakeet.com")

### Topics

[macos](/topics/macos "Topic: macos") [swift](/topics/swift "Topic: swift") [open-source](/topics/open-source "Topic: open-source") [privacy](/topics/privacy "Topic: privacy") [speech-to-text](/topics/speech-to-text "Topic: speech-to-text") [transcription](/topics/transcription "Topic: transcription") [dictation](/topics/dictation "Topic: dictation") [parakeet](/topics/parakeet "Topic: parakeet") [local-first](/topics/local-first "Topic: local-first") [neural-engine](/topics/neural-engine "Topic: neural-engine") [apple-silicon](/topics/apple-silicon "Topic: apple-silicon") [meeting-recording](/topics/meeting-recording "Topic: meeting-recording")

### Resources

[Readme](#readme-ov-file)

### License

[View license](#License-1-ov-file)

### Uh oh!

There was an error while loading. Please reload this page.

[Activity](/moona3k/macparakeet/activity)

### Stars

**482** stars

### Watchers

**4** watching

### Forks

[**47** forks](/moona3k/macparakeet/forks)

[Report repository](/contact/report-content?content_url=https%3A%2F%2Fgithub.com%2Fmoona3k%2Fmacparakeet&report=moona3k+%28user%29)

## [Releases 42](/moona3k/macparakeet/releases)

[

MacParakeet 0.7.2 Latest

Jul 12, 2026



](/moona3k/macparakeet/releases/tag/v0.7.2)

[\+ 41 releases](/moona3k/macparakeet/releases)

## Sponsor this project

 Sponsor

### Uh oh!

There was an error while loading. Please reload this page.

[Learn more about GitHub Sponsors](/sponsors)

## [Packages 0](/users/moona3k/packages?repo_name=macparakeet)

### Uh oh!

There was an error while loading. Please reload this page.

### Uh oh!

There was an error while loading. Please reload this page.

## [Contributors](/moona3k/macparakeet/graphs/contributors)

### Uh oh!

There was an error while loading. Please reload this page.

## Languages

-   [Swift 98.0%](/moona3k/macparakeet/search?l=swift)
-   Other 2.0%

## Footer

[](https://github.com)© 2026 GitHub, Inc.

### Footer navigation

-   [Terms](https://docs.github.com/site-policy/github-terms/github-terms-of-service)
-   [Privacy](https://docs.github.com/site-policy/privacy-policies/github-privacy-statement)
-   [Security](https://github.com/security)
-   [Status](https://www.githubstatus.com/)
-   [Community](https://github.community/)
-   [Docs](https://docs.github.com/)
-   [Contact](https://support.github.com?tags=dotcom-footer)
-   Manage cookies
-   Do not share my personal information

You can’t perform that action at this time.
```

**Tool: read**

**Input:**
```json
{
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec"
}
```

**Output:**
```
<path>/Volumes/emile/PROJECTS/2026/whisptator/openspec</path>
<type>directory</type>
<entries>
changes/
config.yaml
specs/

(3 entries)
</entries>
```

---

## Assistant (Build · Big Pickle · 4.7s)

_Thinking:_

Now I have a good understanding of macparakeet. Let me explore the macparakeet source code structure to understand the architecture better, and also look at what the whisper-large-v3-turbo model requires.

Let me also check the openspec config and any existing specs.

**Tool: read**

**Input:**
```json
{
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/config.yaml"
}
```

**Output:**
```
<path>/Volumes/emile/PROJECTS/2026/whisptator/openspec/config.yaml</path>
<type>file</type>
<content>
1: schema: spec-driven
2: 
3: # Project context (optional)
4: # This is shown to AI when creating artifacts.
5: # Add your tech stack, conventions, style guides, domain knowledge, etc.
6: # Example:
7: #   context: |
8: #     Tech stack: TypeScript, React, Node.js
9: #     We use conventional commits
10: #     Domain: e-commerce platform
11: 
12: # Per-artifact rules (optional)
13: # Add custom rules for specific artifacts.
14: # Example:
15: #   rules:
16: #     proposal:
17: #       - Keep proposals under 500 words
18: #       - Always include a "Non-goals" section
19: #     tasks:
20: #       - Break tasks into chunks of max 2 hours

(End of file - total 20 lines)
</content>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/specs"
}
```

**Output:**
```
<path>/Volumes/emile/PROJECTS/2026/whisptator/openspec/specs</path>
<type>directory</type>
<entries>


(0 entries)
</entries>
```

**Tool: read**

**Input:**
```json
{
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes"
}
```

**Output:**
```
<path>/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes</path>
<type>directory</type>
<entries>
archive/

(1 entries)
</entries>
```

---

## Assistant (Build · Big Pickle · 5.8s)

_Thinking:_

Good - a clean OpenSpec store with no active changes and no specs yet. Now let me think deeply about this project.

Let me fetch the macparakeet Package.swift to understand its dependencies and structure better, and also check what WhisperKit offers for whisper-large-v3-turbo support.

**Tool: webfetch**

**Input:**
```json
{
  "format": "text",
  "url": "https://raw.githubusercontent.com/moona3k/macparakeet/main/Package.swift"
}
```

**Output:**
```
// swift-tools-version: 5.9

import PackageDescription
import Foundation

let skipWhisperKit = ProcessInfo.processInfo.environment["MACPARAKEET_SKIP_WHISPERKIT"] == "1"
let enableMLXLocalLLM = ProcessInfo.processInfo.environment["MACPARAKEET_ENABLE_MLX_LOCAL_LLM"] == "1"

let packageDependencies: [Package.Dependency] = [
    // GRDB for SQLite (dictation history + transcription records)
    .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
    // FluidAudio for Parakeet and Nemotron STT on CoreML/ANE
    .package(url: "https://github.com/FluidInference/FluidAudio", .upToNextMinor(from: "0.15.4")),
    // ArgumentParser for CLI
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    // Sparkle for auto-updates (non-App Store distribution)
    .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.0"),
    // FluidAudio's Swift module exposes yyjson under current Xcode/Swift.
    .package(url: "https://github.com/ibireme/yyjson.git", exact: "0.12.0"),
    // WhisperKit for multilingual STT fallback (Korean + 95 other languages).
    // Argmax is not Swift 6 language-mode clean yet, so CI can omit this package
    // as a target dependency for the first-party Swift 6 syntax/concurrency
    // compile check without removing its lockfile pins.
    .package(url: "https://github.com/argmaxinc/argmax-oss-swift", exact: "0.18.0")
] + (enableMLXLocalLLM ? [
    // Opt-in only. mlx-swift-lm currently needs Swift tools 6.1 and Xcode-built
    // Metal shaders, so plain `swift build` / `swift test` / CI must not resolve it.
    .package(url: "https://github.com/ml-explore/mlx-swift-lm", exact: "3.31.4"),
    // Direct pin holds mlx-swift-lm's transitive MLX dependency at 0.31.4; the
    // resolver would otherwise pick 0.31.6, which requires Swift tools 6.3.
    .package(url: "https://github.com/ml-explore/mlx-swift", exact: "0.31.4"),
    // Only the Tokenizers product is used (local-directory tokenizer loading).
    // Held to 1.1.x because argmax-oss-swift (WhisperKit) cannot resolve
    // alongside swift-transformers 1.3 in the gated dependency graph.
    .package(url: "https://github.com/huggingface/swift-transformers", "1.1.6" ..< "1.2.0"),
] : [])

let coreDependencies: [Target.Dependency] = [
    .product(name: "GRDB", package: "GRDB.swift"),
    .product(name: "FluidAudio", package: "FluidAudio"),
    .product(name: "yyjson", package: "yyjson"),
    "MacParakeetObjCShims"
] + (skipWhisperKit ? [] : [
    .product(name: "WhisperKit", package: "argmax-oss-swift")
])

let whisperKitSwiftSettings: [SwiftSetting] = skipWhisperKit ? [] : [
    .define("MACPARAKEET_HAS_WHISPERKIT")
]

let mlxLocalLLMSwiftSettings: [SwiftSetting] = enableMLXLocalLLM ? [
    .define("MACPARAKEET_HAS_MLX_LOCAL_LLM")
] : []

let appDependencies: [Target.Dependency] = [
    "MacParakeetCore",
    "MacParakeetViewModels",
    .product(name: "Sparkle", package: "Sparkle")
] + (enableMLXLocalLLM ? [
    "MacParakeetLocalLLM"
] : [])

let appTestDependencies: [Target.Dependency] = [
    "MacParakeet",
    "MacParakeetCore",
    "MacParakeetViewModels",
    "MacParakeetObjCShims"
] + (enableMLXLocalLLM ? [
    "MacParakeetLocalLLM"
] : [])

let mlxLocalLLMTargets: [Target] = enableMLXLocalLLM ? [
    .target(
        name: "MacParakeetLocalLLM",
        dependencies: [
            "MacParakeetCore",
            .product(name: "MLXLLM", package: "mlx-swift-lm"),
            .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
            .product(name: "MLXHuggingFace", package: "mlx-swift-lm"),
            .product(name: "Tokenizers", package: "swift-transformers"),
        ],
        path: "Sources/MacParakeetLocalLLM",
        swiftSettings: mlxLocalLLMSwiftSettings
    )
] : []

let package = Package(
    name: "MacParakeet",
    platforms: [
        // Note: SPM doesn't support patch-level versions for macOS 14, but the app
        // documents macOS 14.2+ and enforces it at runtime.
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacParakeet", targets: ["MacParakeet"]),
        .executable(name: "macparakeet-cli", targets: ["CLI"]),
        .library(name: "MacParakeetCore", targets: ["MacParakeetCore"]),
        .library(name: "MacParakeetViewModels", targets: ["MacParakeetViewModels"])
    ],
    dependencies: packageDependencies,
    targets: [
        // Main GUI app
        .executableTarget(
            name: "MacParakeet",
            dependencies: appDependencies,
            path: "Sources/MacParakeet",
            resources: [.process("Resources")],
            swiftSettings: mlxLocalLLMSwiftSettings
        ),
        // macparakeet-cli — versioned public surface (semver, Sources/CLI/CHANGELOG.md).
        // Consumed by the macOS app, scripted callers, and downstream agent skills
        // (see /AGENTS.md and integrations/README.md).
        .executableTarget(
            name: "CLI",
            dependencies: [
                "MacParakeetCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/CLI",
            exclude: ["CHANGELOG.md", "README.md"]
        ),
        // Objective-C shim target for catching NSException in Swift.
        // Swift's `do/try/catch` cannot catch Objective-C exceptions raised by
        // AppKit / AVFoundation / Core Audio — we need an @try/@catch trampoline
        // to convert them into Swift-throwable NSError values. See issue #91.
        .target(
            name: "MacParakeetObjCShims",
            path: "Sources/MacParakeetObjCShims",
            publicHeadersPath: "include"
        ),
        // Shared core library (no UI dependencies)
        .target(
            name: "MacParakeetCore",
            dependencies: coreDependencies,
            path: "Sources/MacParakeetCore",
            exclude: [
                "Audio/README.md",
                "Database/README.md",
                "Licensing/README.md",
                "Resources",
                "Services/System/README.md",
                "STT/README.md",
                "TextProcessing/README.md",
            ],
            swiftSettings: whisperKitSwiftSettings
        ),
        // ViewModels library (testable, depends on Core + AppKit/SwiftUI)
        .target(
            name: "MacParakeetViewModels",
            dependencies: ["MacParakeetCore"],
            path: "Sources/MacParakeetViewModels"
        ),
        // Tests
        .testTarget(
            name: "MacParakeetTests",
            dependencies: appTestDependencies,
            path: "Tests/MacParakeetTests",
            swiftSettings: whisperKitSwiftSettings + mlxLocalLLMSwiftSettings
        ),
        .testTarget(
            name: "CLITests",
            dependencies: ["CLI", "MacParakeetCore"],
            path: "Tests/CLITests"
        )
    ] + mlxLocalLLMTargets
)

```

**Tool: webfetch**

**Input:**
```json
{
  "format": "text",
  "url": "https://raw.githubusercontent.com/moona3k/macparakeet/main/AGENTS.md"
}
```

**Output:**
```
# AGENTS.md -- MacParakeet

> Canonical startup guide for coding agents working in this repo. Claude Code
> also reads [`CLAUDE.md`](./CLAUDE.md), which is a small Claude-specific
> overlay. Agents outside this repo that want to call `macparakeet-cli` should
> start with [`integrations/README.md`](./integrations/README.md).

## Project Shape

MacParakeet is a fast, private, local-first voice app for Apple Silicon Macs.
It ships three primary capture modes -- system-wide dictation, file/media URL
transcription, and meeting recording -- plus Transforms for selected-text
rewrites. Speech recognition runs locally by default through Parakeet via
FluidAudio CoreML/ANE, with optional Nemotron, WhisperKit, and Cohere Transcribe
engines.

The repo contains two products:

- `MacParakeet.app`: SwiftUI macOS app.
- `macparakeet-cli`: public automation surface in `Sources/CLI/`; compatibility
  notes live in `Sources/CLI/CHANGELOG.md`.

`main` is development. The notarized DMG is the user-facing stable channel.
For current release/flag state, read
[`spec/README.md`](./spec/README.md#release-channels-and-feature-flags) and the
relevant ADR/spec instead of copying release facts into new docs.

## Commands

```bash
swift build
swift test
swift test --filter TextProcessingPipelineTests
scripts/dev/check.sh [TestFilter]
scripts/dev/format.sh
scripts/dev/ci_local.sh
scripts/dev/greptile_review.sh [BaseBranch]
scripts/dev/run_app.sh
no-mistakes doctor
no-mistakes init
no-mistakes axi
swift run macparakeet-cli --help
swift run macparakeet-cli health
```

Iterate on focused tests ONLY (`swift test --filter <AreaTests>` for the
areas the diff touches). Run the full `swift test` suite AT MOST ONCE per
task, as the final gate before declaring code-change work complete — never
per iteration. The suite is 4,300+ tests including CPU-heavy AEC/DSP
simulations; full-suite-per-iteration turns a 10-minute review into an
hour. Exception only when the user explicitly scopes verification
differently.

## Worktrees

This repo often has many parallel worktrees.

- Base new branches/worktrees on `origin/main`, not local `main`.
- Fetch first: `git fetch origin`.
- Build and test from the worktree that owns the branch. SwiftPM/Xcode state can
  otherwise point at the wrong checkout.
- Treat `.build*`, `.claude/worktrees`, `dist`, and
  `journal/x-agent/node_modules` as generated or archival unless the task
  specifically asks about them.
- Default searches should avoid ignored/generated/private paths such as
  `.claude/`, `.build*`, `dist`, `diagnostics`, `logs`, `journal/`, local env
  files, and key material unless the task explicitly names them.

## Code Boundaries

- Swift package tools-version is 5.9; first-party code is kept Swift 6
  language-mode/concurrency clean.
- `MacParakeetCore` owns shared logic and has no SwiftUI view ownership. Small
  AppKit-backed adapter services are allowed when Foundation has no equivalent.
- `MacParakeetViewModels` contains `@Observable` view models that can be tested
  without the GUI.
- New I/O should use async/await. Avoid new completion-handler or Combine
  patterns.
- When ordering or a result matters, make the API async and await it instead of
  using fire-and-forget `Task`.
- Keep `@MainActor` work short; move long-running I/O, model, process, and
  audio work off the actor, then hop back for UI state.
- Database access uses GRDB repositories, roughly one repository per table.
- UI buttons use `.parakeetAction(...)`; do not tint whole hosting roots coral.

When editing a load-bearing Core subsystem, read its local README before code:
`Audio/`, `STT/`, `TextProcessing/`, `Database/`, `Licensing/`, and
`Services/System/` currently have subsystem rules.

## Product Rules

- Preserve the local-first posture. Audio/transcripts stay on-device for core
  dictation, transcription, and meeting recording. Cloud LLMs, media downloads,
  model/update flows, and telemetry are explicit product surfaces.
- Treat the user database and meeting artifacts as user data. Do not delete them
  outside explicit product recovery/discard flows.
- Keep the product focused. Prefer reliable capture, recovery, durable local
  artifacts, polished daily workflows, and simple UX over feature sprawl.
- North star ([ADR-027](./spec/adr/027-product-north-star.md)): MacParakeet is
  the private speech memory of your Mac. Features must capture speech better,
  make the local library more useful, or expose it safely to the user and
  their agents.
- ADRs in `spec/adr/` record accepted decisions. If reality has changed, update
  the relevant ADR/spec deliberately instead of silently coding around it.

## Working Method

- Start by finding the governing code, ADRs/specs, and tests for the task.
- Treat agent memory, old chat, and old plans as hints. Verify live state from
  code, tests, `git`, GitHub, release metadata, or the governing doc before
  relying on them.
- For behavior changes, define the intended scope and must-not-change
  invariants before editing.
- Plans are useful working memory for substantial or long-running tasks, but
  they are optional. Create or update one when it will keep the work coherent.
- Add tests proportional to risk. Shared flows, persistence, CLI contracts,
  privacy/telemetry, and concurrency need stronger coverage than copy edits.
- Update docs when user-visible behavior, public CLI behavior, persistence,
  privacy, or release framing changes.
- Boundary contract changes must update the matching
  [`spec/contracts/`](./spec/contracts/) document and focused tests in the same
  PR.

The old manual requirements/traceability workflow is retired. The legacy
requirements index is archived at
[`docs/historical/requirements-legacy.yaml`](./docs/historical/requirements-legacy.yaml)
for old references only; do not add new REQ IDs as part of normal work.

## Review And Commit

Use [`docs/pr-review-workflow.md`](./docs/pr-review-workflow.md) for substantial
changes. Scale review to risk: trivial edits can go straight in; small contained
fixes need focused verification; substantial changes benefit from branch-first
PRs, CI, local Greptile CLI review, and independent review until findings
converge. Greptile CLI reviews committed branch changes only; uncommitted
changes are ignored, so run it from the clean worktree/branch that owns the PR.

MacParakeet adopts `no-mistakes` as the preferred gate for non-trivial
agent-authored branches when it is installed. Initialize once per checkout with
`no-mistakes init`; it adds the local `no-mistakes` remote and installs the
user-level `/no-mistakes` skill for Claude Code and Codex. The committed
[`.no-mistakes.yaml`](./.no-mistakes.yaml) keeps the gate deterministic:
`swift test` is the baseline test command, `swift-format lint` is the lint
command, automatic review fixing is off by default, in-repo evidence artifacts
stay disabled, and transcript-based intent extraction is disabled so agents
should pass explicit intent. For substantial ready-to-review work, prefer
`/no-mistakes <task>` from the agent or `git push no-mistakes <branch>` from the
terminal over a direct `git push origin`. If the tool is unavailable, continue
with the documented PR workflow and say so in the handoff or PR notes.

Commit messages should help a future reader understand the change. The rich
format in [`docs/commit-guidelines.md`](./docs/commit-guidelines.md) is a tool
for significant work, not ceremony for every typo.

## Where To Look

- Spec index and roadmap: [`spec/README.md`](./spec/README.md)
- Architecture and product decisions: [`spec/adr/`](./spec/adr/)
- Feature behavior: [`spec/02-features.md`](./spec/02-features.md)
- System architecture: [`spec/03-architecture.md`](./spec/03-architecture.md)
- UI patterns: [`spec/04-ui-patterns.md`](./spec/04-ui-patterns.md)
- Testing strategy: [`spec/09-testing.md`](./spec/09-testing.md)
- Agent working method: [`spec/10-ai-coding-method.md`](./spec/10-ai-coding-method.md)
- Agent memory governance: [`docs/agent-memory-governance.md`](./docs/agent-memory-governance.md)
- Agent instruction research: [`docs/research/coding-agent-instructions-2026-06.md`](./docs/research/coding-agent-instructions-2026-06.md)
- Active/completed plans: [`plans/README.md`](./plans/README.md)
- Distribution/release steps: [`docs/distribution.md`](./docs/distribution.md)
- CLI automation contract: [`integrations/README.md`](./integrations/README.md)

```

---

## Assistant (Build · Big Pickle · 9.4s)

_Thinking:_

Now I have a very clear picture of macparakeet. Let me think deeply about what the user wants to build ("whisptator") and how it relates to macparakeet.

The user wants:
1. A macOS speech-to-text app2. Uses whisper-large-v3-turbo from HuggingFace (already cached locally)
3. Global push-to-talk and keyboard shortcuts
4. Text pasted into the active window
5. Configuration dialog for audio device, model, shortcuts
6. Meeting recording with system audio + microphone
7. Live transcript preview
8. Text cleanup (filler words, custom replacements)


9. Apple Silicon optimized
10. Native Swift (no Python/TypeScript)

This is very similar to macparakeet but with a different model focus (Whisper instead of Parakeet). Let me think about the key architectural questions and differences.

Key differences from macparakeet:
- Model: Whisper large v3 turbo (via WhisperKit or direct CoreML) vs Parakeet TDT (via FluidAudio)
- The user already has the model in HuggingFace cache
- Potentially simpler scope (no file/URL transcription, no YouTube, no AI features initially?)

Key architectural questions:
1. **WhisperKit vs FluidAudio**: macparakeet uses WhisperKit for Whisper support. WhisperKit is Argmax's framework for running Whisper on Apple Silicon with CoreML optimization. FluidAudio is for Parakeet/Nemotron. Since the user wants Whisper, WhisperKit is the natural choice.

2. **HuggingFace model format**: The user has `openai--whisper-large-v3-turbo` in `~/.cache/huggingface/hub`. WhisperKit can load models from local directories. Need to understand the exact format WhisperKit expects.

3. **Global hotkeys**: Need to use `CGEvent` tap or `NSEvent.addGlobalMonitorForEvents` for system-wide keyboard shortcuts. MacParakeet already does this.

4. **Text pasting**: Use `CGEvent` to simulate keyboard input at the cursor position of the frontmost app. MacParakeet does this.

5. **Audio recording**: AVFoundation for microphone, ScreenCaptureKit for system audio capture.

6. **Architecture**: SwiftUI app with a core library, similar to MacParakeet's structure.

Now I'm thinking through the key questions and tradeoffs to explore with the user.

This is a rich project. Let me dig into the key technical pieces before we think about architecture.

**Tool: webfetch**

**Input:**
```json
{
  "format": "text",
  "url": "https://raw.githubusercontent.com/argmaxinc/WhisperKit/main/README.md"
}
```

**Output:**
```

<div align="center">

<a href="https://github.com/argmaxinc/argmax-oss-swift#gh-light-mode-only">
  <img src="https://github.com/user-attachments/assets/2ef4d2b4-b4f1-4b9b-9590-4e57432633ed" alt="Argmax Logo" width="20%" />
</a>

<a href="https://github.com/argmaxinc/argmax-oss-swift#gh-dark-mode-only">
  <img src="https://github.com/user-attachments/assets/6f2c77c4-94b5-4ce5-8647-b177641e6f02" alt="Argmax Logo" width="20%" />
</a>

# Argmax Open-Source SDK

[![Tests](https://github.com/argmaxinc/argmax-oss-swift/actions/workflows/release-tests.yml/badge.svg)](https://github.com/argmaxinc/argmax-oss-swift/actions/workflows/release-tests.yml)
[![Supported Swift Version](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fargmaxinc%2Fargmax-oss-swift%2Fbadge%3Ftype%3Dswift-versions&labelColor=353a41&color=32d058)](https://swiftpackageindex.com/argmaxinc/argmax-oss-swift) [![Supported Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fargmaxinc%2Fargmax-oss-swift%2Fbadge%3Ftype%3Dplatforms&labelColor=353a41&color=32d058)](https://swiftpackageindex.com/argmaxinc/argmax-oss-swift)
[![License](https://img.shields.io/github/license/argmaxinc/argmax-oss-swift?logo=github&logoColor=969da4&label=License&labelColor=353a41&color=32d058)](LICENSE.md)
<br/>
[![Discord](https://img.shields.io/discord/1171912382512115722?style=flat&logo=discord&logoColor=969da4&label=Discord&labelColor=353a41&color=32d058&link=https%3A%2F%2Fdiscord.gg%2FG5F5GZGecC)](https://discord.gg/G5F5GZGecC)
[![Hugging Face](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fhuggingface.co%2Fapi%2Fmodels%2Fargmaxinc%2Fwhisperkit-coreml&query=%24.downloads&suffix=%2Fmonth&logo=huggingface&logoColor=969da4&label=Downloads&labelColor=353a41&color=32d058)](https://huggingface.co/argmaxinc/whisperkit-coreml)


</div>

[Argmax](https://argmaxinc.com/blog) Open-Source SDK Swift is a collection of turn-key on-device inference frameworks:
- **WhisperKit** for speech-to-text with OpenAI Whisper
- **SpeakerKit** for speaker diarization with Pyannote
- **TTSKit** for text-to-speech with Qwen-TTS

> [!IMPORTANT]
> [Argmax Pro SDK](https://www.argmaxinc.com/blog/argmax-sdk-2) supports additional models and advanced features such as:
> - Real-time transcription with speakers
> - Frontier accuracy for your use case with custom vocabulary
> - Argmax Local Server for non-native apps
> - Android support with Argmax Pro SDK Kotlin
> 
> Further resources:
> - [Open-source vs Pro SDK](https://app.argmaxinc.com/docs/wiki/open-source-vs-pro-sdk)
> - [Try Pro SDK on TestFlight](https://testflight.apple.com/join/Q1cywTJw)
> - [Model Gallery](https://app.argmaxinc.com/docs/models)

## Table of Contents

- [Installation](#installation)
  - [Swift Package Manager](#swift-package-manager)
  - [Prerequisites](#prerequisites)
  - [Xcode Steps](#xcode-steps)
  - [Package.swift](#packageswift)
  - [Homebrew](#homebrew)
- [WhisperKit](#whisperkit)
  - [Quick Example](#quick-example)
  - [Model Selection](#model-selection)
  - [Generating Models](#generating-models)
  - [Swift CLI](#swift-cli)
  - [Local Server](#local-server)
    - [Building the Server](#building-the-server)
    - [Starting the Server](#starting-the-server)
    - [API Endpoints](#api-endpoints)
    - [Supported Parameters](#supported-parameters)
    - [Client Examples](#client-examples)
    - [Generating the API Specification](#generating-the-api-specification)
    - [Client Generation](#client-generation)
    - [API Limitations](#api-limitations)
    - [Fully Supported Features](#fully-supported-features)
- [TTSKit](#ttskit)
  - [Quick Example](#quick-example-1)
  - [Model Selection](#model-selection-1)
    - [Custom Voices](#custom-voices)
    - [Real-Time Streaming Playback](#real-time-streaming-playback)
  - [Generation Options](#generation-options)
    - [Style Instructions (1.7B only)](#style-instructions-17b-only)
  - [Saving Audio](#saving-audio)
  - [Progress Callbacks](#progress-callbacks)
  - [Swift CLI](#swift-cli-1)
  - [Demo App](#demo-app)
- [SpeakerKit](#speakerkit)
  - [Quick Example](#quick-example-2)
  - [Diarization Options](#diarization-options)
  - [Combining with Transcription](#combining-with-transcription)
  - [RTTM Output](#rttm-output)
  - [Swift CLI](#swift-cli-2)
- [Contributing \& Roadmap](#contributing--roadmap)
- [License](#license)
- [Citation](#citation)

## Installation

### Swift Package Manager

WhisperKit, TTSKit, and SpeakerKit are separate library products in the same Swift package. Add the package once and pick the products you need. You can also use the `ArgmaxOSS` umbrella product to import everything at once.

### Prerequisites

- macOS 14.0 or later.
- Xcode 16.0 or later.

### Xcode Steps

1. Open your Swift project in Xcode.
2. Navigate to `File` > `Add Package Dependencies...`.
3. Enter the package repository URL: `https://github.com/argmaxinc/argmax-oss-swift`.
4. Choose the version range or specific version.
5. When prompted to choose library products, select **ArgmaxOSS** (all kits), or individual kits: **WhisperKit**, **TTSKit**, **SpeakerKit**.

### Package.swift

Add the package dependency:

```swift
dependencies: [
    .package(url: "https://github.com/argmaxinc/argmax-oss-swift.git", from: "0.9.0"),
],
```

Then add the products you need as target dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: [
        // Import everything at once:
        .product(name: "ArgmaxOSS", package: "argmax-oss-swift"),

        // Or pick individual kits:
        // .product(name: "WhisperKit", package: "argmax-oss-swift"),   // speech-to-text
        // .product(name: "TTSKit", package: "argmax-oss-swift"),       // text-to-speech
        // .product(name: "SpeakerKit", package: "argmax-oss-swift"),   // speaker diarization
    ]
),
```

### Homebrew

You can install the command line app using [Homebrew](https://brew.sh) by running the following command:

```bash
brew install whisperkit-cli
```  

## WhisperKit

To get started with WhisperKit, you need to initialize it in your project.

### Quick Example

This example demonstrates how to transcribe a local audio file:

```swift
import WhisperKit

// Initialize WhisperKit with default settings
Task {
   let pipe = try? await WhisperKit()
   let transcription = try? await pipe!.transcribe(audioPath: "path/to/your/audio.{wav,mp3,m4a,flac}")?.text
    print(transcription)
}
```

### Model Selection

> [!NOTE]
> Argmax recommends `large-v3-v20240930_626MB` for maximum multilingual accuracy and `tiny` for the fastest debugging workflow.

| Whisper Version                  | WhisperKit Variant                                                                                                 | Description                                                                      |
|----------------------------------|------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| Large v3 Turbo (compressed)      | [large-v3-v20240930_626MB](https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/openai_whisper-large-v3-v20240930_626MB) | Recommended across iOS and macOS for maximum accuracy                            |
| Large v3 Turbo                   | [large-v3-v20240930_turbo](https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/openai_whisper-large-v3-v20240930_turbo) | Recommended on macOS for maximum speed and accuracy                             |
| Base (multilingual)              | [base](https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/openai_whisper-base)                         |                                                                                  |
| Base (English-only)              | [base.en](https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/openai_whisper-base.en)                   |                                                                                  |
| Small (Multilingual)             | [small](https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/openai_whisper-small)                       |                                                                                  |
| Small (English-only)             | [small.en](https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/openai_whisper-small.en)                 |                                                                                  |
| Tiny (Multilingual)              | [tiny](https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/openai_whisper-tiny)                         |                                                                                  |
| Tiny (English-only)              | [tiny.en](https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/openai_whisper-tiny.en)                   | Smallest size, lowest accuracy. Only recommended for development & debugging.     |



WhisperKit automatically downloads the recommended model for the device if not specified. You can also select a specific model by passing in the model name:


```swift
let pipe = try? await WhisperKit(WhisperKitConfig(model: "large-v3-v20240930_626MB"))
```

This method also supports glob search, so you can use wildcards to select a model:

```swift
let pipe = try? await WhisperKit(WhisperKitConfig(model: "large-v3-v20240930_626MB"))
```

Note that the model search must return a single model from the source repo, otherwise an error will be thrown.

For a list of available models, see our [HuggingFace repo](https://huggingface.co/argmaxinc/whisperkit-coreml).

### Generating Models

WhisperKit also comes with the supporting repo [`whisperkittools`](https://github.com/argmaxinc/whisperkittools) which lets you create and deploy your own fine tuned versions of Whisper in CoreML format to HuggingFace. Once generated, they can be loaded by simply changing the repo name to the one used to upload the model:

```swift
let config = WhisperKitConfig(model: "large-v3-v20240930_626MB", modelRepo: "username/your-model-repo")
let pipe = try? await WhisperKit(config)
```

### Swift CLI

The Swift CLI allows for quick testing and debugging outside of an Xcode project. To install it, run the following:

```bash
git clone https://github.com/argmaxinc/argmax-oss-swift.git
cd argmax-oss-swift
```

Then, setup the environment and download your desired model.

```bash
make setup
make download-model MODEL=large-v3-v20240930_626MB
```

**Note**:

1. This will download only the model specified by `MODEL` (see what's available in our [HuggingFace repo](https://huggingface.co/argmaxinc/whisperkit-coreml), where we use the prefix `openai_whisper-{MODEL}`)
2. Before running `download-model`, make sure [git-lfs](https://git-lfs.com) is installed

If you would like download all available models to your local folder, use this command instead:

```bash
make download-models
```

You can then run them via the CLI with:

```bash
swift run argmax-cli transcribe --model-path "Models/whisperkit-coreml/openai_whisper-large-v3-v20240930_626MB" --audio-path "path/to/your/audio.{wav,mp3,m4a,flac}"
```

Which should print a transcription of the audio file. If you would like to stream the audio directly from a microphone, use:

```bash
swift run argmax-cli transcribe --model-path "Models/whisperkit-coreml/openai_whisper-large-v3-v20240930_626MB" --stream
```

### Local Server

The Argmax CLI includes a local server that implements the OpenAI Audio API, allowing you to use existing OpenAI SDK clients or generate new ones. The server supports transcription and translation with **output streaming** capabilities (real-time transcription results as they're generated).

> [!NOTE]
> [Argmax Pro Local Server](https://www.argmaxinc.com/blog/argmax-local-server) provides a real-time streaming transcription with a WebSocket local server that is API-compatible with cloud-based providers such as Deepgram.


#### Building the Server

```bash
# Build with server support
make build-local-server

# Or manually with the build flag
BUILD_ALL=1 swift build --product argmax-cli
```

#### Starting the Server

```bash
# Start server with default settings
BUILD_ALL=1 swift run argmax-cli serve

# Custom host and port
BUILD_ALL=1 swift run argmax-cli serve --host 0.0.0.0 --port 8080

# With specific model and verbose logging
BUILD_ALL=1 swift run argmax-cli serve --model tiny --verbose

# See all configurable parameters
BUILD_ALL=1 swift run argmax-cli serve --help
```

#### API Endpoints

- **POST** `/v1/audio/transcriptions` - Transcribe audio to text
- **POST** `/v1/audio/translations` - Translate audio to English

#### Supported Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `file` | Audio file (wav, mp3, m4a, flac) | Required |
| `model` | Model identifier | Server default |
| `language` | Source language code | Auto-detect |
| `prompt` | Text to guide transcription | None |
| `response_format` | Output format (json, verbose_json) | verbose_json |
| `temperature` | Sampling temperature (0.0-1.0) | 0.0 |
| `timestamp_granularities[]` | Timing detail (word, segment) | segment |
| `stream` | Enable streaming | false |

#### Client Examples

**Python Client (OpenAI SDK)**
```bash
cd Examples/ServeCLIClient/Python
uv sync
python whisperkit_client.py transcribe --file audio.wav --language en
python whisperkit_client.py translate --file audio.wav
```

Quick Python example:
```python
from openai import OpenAI
client = OpenAI(base_url="http://localhost:50060/v1")
result = client.audio.transcriptions.create(
    file=open("audio.wav", "rb"),
    model="tiny"  # Model parameter is required
)
print(result.text)
```

**Swift Client (Generated from OpenAPI Spec, see ServeCLIClient/Swift/updateClient.sh)**
```bash
cd Examples/ServeCLIClient/Swift
swift run whisperkit-client transcribe audio.wav --language en
swift run whisperkit-client translate audio.wav
```

**CurlClient (Shell Scripts)**
```bash
cd Examples/ServeCLIClient/Curl
chmod +x *.sh
./transcribe.sh audio.wav --language en
./translate.sh audio.wav --language es
./test.sh  # Run comprehensive test suite
```

#### Generating the API Specification

The server's OpenAPI specification and code are generated from the official OpenAI API:

```bash
# Generate latest spec and server code
make generate-server
```

#### Client Generation

You can generate clients for any language using the OpenAPI specification, for example:

```bash
# Generate Python client
swift run swift-openapi-generator generate scripts/specs/localserver_openapi.yaml \
  --output-directory python-client \
  --mode client \
  --mode types

# Generate TypeScript client
npx @openapitools/openapi-generator-cli generate \
  -i scripts/specs/localserver_openapi.yaml \
  -g typescript-fetch \
  -o typescript-client
```

#### API Limitations

Compared to the official OpenAI API, the local server has these limitations:

- **Response formats**: Only `json` and `verbose_json` supported (no plain text, SRT, VTT formats)
- **Model selection**: Client must launch server with desired model via `--model` flag

#### Fully Supported Features

The local server fully supports these OpenAI API features:

- **Include parameters**: `logprobs` parameter for detailed token-level log probabilities
- **Streaming responses**: Server-Sent Events (SSE) for real-time transcription
- **Timestamp granularities**: Both `word` and `segment` level timing
- **Language detection**: Automatic language detection or manual specification
- **Temperature control**: Sampling temperature for transcription randomness
- **Prompt text**: Text guidance for transcription style and context

## TTSKit

TTSKit is an on-device text-to-speech framework built on Core ML. It runs [Qwen3-TTS](https://github.com/QwenLM/Qwen3-TTS) models entirely on Apple silicon with real-time streaming playback, no server required.

- macOS 15.0 or later.
- iOS 18.0 or later.

### Quick Example

This example demonstrates how to generate speech from text:

```swift
import TTSKit

Task {
    let tts = try await TTSKit()
    let result = try await tts.generate(text: "Hello from TTSKit!")
    print("Generated \(result.audioDuration)s of audio at \(result.sampleRate)Hz")
}
```

`TTSKit()` automatically downloads the default 0.6B model on first run. The tokenizer and CoreML models are loaded lazily on the first `generate()` call.

### Model Selection

TTSKit ships two model sizes. You can select the model by passing a variant to `TTSKitConfig`:

```swift
// Fast, runs on all platforms (~1 GB download)
let tts = try await TTSKit(TTSKitConfig(model: .qwen3TTS_0_6b))

// Higher quality, macOS only (~2.2 GB download, supports style instructions)
let tts = try await TTSKit(TTSKitConfig(model: .qwen3TTS_1_7b))
```

Models are hosted on [HuggingFace](https://huggingface.co/argmaxinc/ttskit-coreml) and cached locally after the first download.

#### Custom Voices

You can choose from 9 built-in voices and 10 languages:

```swift
let result = try await tts.generate(
    text: "こんにちは世界",
    speaker: .onoAnna,
    language: .japanese
)
```

**Voices:** `.ryan`, `.aiden`, `.onoAnna`, `.sohee`, `.eric`, `.dylan`, `.serena`, `.vivian`, `.uncleFu`

**Languages:** `.english`, `.chinese`, `.japanese`, `.korean`, `.german`, `.french`, `.russian`, `.portuguese`, `.spanish`, `.italian`

#### Real-Time Streaming Playback

`play` streams audio to the device speakers frame-by-frame as it is generated:

```swift
try await tts.play(text: "This starts playing before generation finishes.")
```

You can control how much audio is buffered before playback begins. The default `.auto` strategy measures the first generation step and pre-buffers just enough to avoid underruns:

```swift
try await tts.play(
    text: "Long passage...",
    playbackStrategy: .auto
)
```

Other strategies include `.stream` (immediate, no buffer), `.buffered(seconds:)` (fixed pre-buffer), and `.generateFirst` (generate all audio first, then play).

### Speech Decoder Mode

TTSKit's default speech decoder bundles two functions, selectable via `TTSKitConfig.speechDecoderMode`:

| Mode | RVQ frames / call | Audio / call | Use case |
|------|-------------------|--------------|----------|
| `.latencyOptimized` (default) | 1 | ~80 ms | Lowest time-to-first-audio for streaming. |
| `.throughputOptimized` | 4 | ~320 ms | Amortizes decoder overhead for higher throughput, at the cost of a ~4× larger first-buffer latency. |

```swift
// Default: latency-optimized (lowest time-to-first-audio)
let tts = try await TTSKit()

// Opt into throughput-optimized generation
let config = TTSKitConfig(speechDecoderMode: .throughputOptimized)
let throughputTTS = try await TTSKit(config)
```

The mode is read once when models are loaded; set it before constructing `TTSKit` (or reload the model to switch at runtime).

### Generation Options

You can customize sampling, chunking, and concurrency via `GenerationOptions`:

```swift
// Defaults recommended by Qwen
var options = GenerationOptions()
options.temperature = 0.9
options.topK = 50
options.repetitionPenalty = 1.05
options.maxNewTokens = 245

// Long text is automatically split at sentence boundaries
options.chunkingStrategy = .sentence
options.concurrentWorkerCount = nil  // nil = all chunks run concurrently with a good default for the device

let result = try await tts.generate(text: longArticle, options: options)
```

#### Style Instructions (1.7B only)

The 1.7B model accepts a natural-language style instruction that controls prosody:

```swift
var options = GenerationOptions()
options.instruction = "Speak slowly and warmly, like a storyteller."

let result = try await tts.generate(
    text: "Once upon a time...",
    speaker: .ryan,
    options: options
)
```

### Saving Audio

Generated audio can be saved to WAV or M4A:

```swift
let result = try await tts.generate(text: "Save me!")
let outputDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

// Save as .wav or .m4a (AAC)
try await AudioOutput.saveAudio(result.audio, toFolder: outputDir, filename: "output", format: .m4a)
```

### Progress Callbacks

You can receive per-step audio during generation. Return `false` from the callback to cancel early:

```swift
let result = try await tts.generate(text: "Hello!") { progress in
    print("Audio chunk: \(progress.audio.count) samples")
    if let stepTime = progress.stepTime {
        print("First step took \(stepTime)s")
    }
    return true  // return false to cancel
}
```

### Swift CLI

The TTS command is available through the `argmax-cli` tool. You can generate speech and optionally play it back in real time:

```bash
swift run argmax-cli tts --text "Hello from the command line" --play
swift run argmax-cli tts --text "Save to file" --output-path output.wav
swift run argmax-cli tts --text "日本語テスト" --speaker ono-anna --language japanese
swift run argmax-cli tts --text-file article.txt --model 1.7b --instruction "Read cheerfully"
swift run argmax-cli tts --help
```

### Demo App

The [TTSKitExample](Examples/TTS/TTSKitExample/) example app showcases real-time streaming, model management, waveform visualization, and generation history on macOS and iOS. See the [TTSKitExample README](Examples/TTS/TTSKitExample/README.md) for build instructions.

## SpeakerKit

SpeakerKit is an on-device speaker diarization framework built on Core ML. It runs [Pyannote v4 (community-1)](https://huggingface.co/argmaxinc/speakerkit-coreml) on Apple silicon to label speakers in audio. Read the [blog post](https://www.argmaxinc.com/blog/speakerkit) for architecture details and benchmarks.

- macOS 13.0 or later.
- iOS 16.0 or later.

### Quick Example

This example demonstrates how to diarize an audio file:

```swift
import SpeakerKit

Task {
    let speakerKit = try await SpeakerKit()

    let audioArray = try AudioProcessor.loadAudioAsFloatArray(fromPath: "audio.wav")
    let result = try await speakerKit.diarize(audioArray: audioArray)

    print("Detected \(result.speakerCount) speakers")
    for segment in result.segments {
        print(segment)
    }
}
```

`SpeakerKit()` uses `PyannoteConfig()` defaults, automatically downloading models from [HuggingFace](https://huggingface.co/argmaxinc/speakerkit-coreml) on first run. The segmenter and embedder CoreML models are loaded lazily (unless `load` is set on config) on the first `diarize()` call.

### Diarization Options

You can control speaker detection via `PyannoteDiarizationOptions`:

```swift
let audioArray = try AudioProcessor.loadAudioAsFloatArray(fromPath: "audio.wav")
let options = PyannoteDiarizationOptions(
    numberOfSpeakers: 2,               // nil = automatic detection
    clusterDistanceThreshold: 0.6,     // clustering threshold
    useExclusiveReconciliation: false   // exclusive speaker assignment per frame
)
let result = try await speakerKit.diarize(audioArray: audioArray, options: options)
```

For local models, skip the download step:

```swift
let config = PyannoteConfig(modelFolder: "/path/to/models")
let speakerKit = try await SpeakerKit(config)
```

### Combining with Transcription

SpeakerKit can merge diarization results with WhisperKit transcriptions to produce speaker-attributed segments:

```swift
import WhisperKit
import SpeakerKit

let whisperKit = try await WhisperKit()
let speakerKit = try await SpeakerKit()

let audioArray = try AudioProcessor.loadAudioAsFloatArray(fromPath: "audio.wav")
let transcription = try await whisperKit.transcribe(audioArray: audioArray)
let diarization = try await speakerKit.diarize(audioArray: audioArray)

let speakerSegments = diarization.addSpeakerInfo(to: transcription)

for group in speakerSegments {
    for segment in group {
        print("\(segment.speaker): \(segment.text)")
    }
}
```

Two strategies are available for matching speakers to transcription:
- `.subsegment` (default) -- splits segments at word gaps, then assigns speakers
- `.segment` -- assigns a speaker to each transcription segment as a whole

### RTTM Output

Generate RTTM output:

```swift
let speakerKit = try await SpeakerKit()

let audioArray = try AudioProcessor.loadAudioAsFloatArray(fromPath: "meeting.wav")
let diarization = try await speakerKit.diarize(audioArray: audioArray)

let rttmLines = SpeakerKit.generateRTTM(from: diarization, fileName: "meeting")
for line in rttmLines {
    print(line)
}
```

### Swift CLI

The diarization commands are available through the `argmax-cli` tool:

```bash
# Standalone diarization
swift run argmax-cli diarize --audio-path audio.wav --verbose

# Save RTTM output
swift run argmax-cli diarize --audio-path audio.wav --rttm-path output.rttm

# Specify number of speakers
swift run argmax-cli diarize --audio-path audio.wav --num-speakers 3

# Transcription with diarization
swift run argmax-cli transcribe --audio-path audio.wav --diarization

# See all options
swift run argmax-cli diarize --help
```

## Contributing & Roadmap

Our goal is to make this SDK better and better over time and we'd love your help! Just search the code for "TODO" for a variety of features that are yet to be built. Please refer to our [contribution guidelines](CONTRIBUTING.md) for submitting issues, pull requests, and coding standards, where we also have a public roadmap of features we are looking forward to building in the future.

**External dependencies:** `Sources/ArgmaxCore/External/` contains a copy of [swift-transformers](https://github.com/huggingface/swift-transformers) (Hub and Tokenizers modules, v1.1.6) with Jinja-dependent code removed. When updating to a newer version, copy the fresh sources over that directory and re-apply the patches marked with `// Argmax-modification:` (`grep -r "Argmax-modification:" Sources/ArgmaxCore/External/`). The matching upstream tests are vendored under `Tests/ArgmaxCoreTests/External/` using the same convention.

## License

Argmax OSS is released under the MIT License. See [LICENSE](LICENSE) for more details.

This project incorporates third-party software under their own license terms. See [NOTICES](NOTICES) for attributions.

## Citation

If you use this SDK for something cool or just find it useful, please drop us a note at [info@argmaxinc.com](mailto:info@argmaxinc.com)!

If you use WhisperKit, SpeakerKit or TTSKit for academic work, please cite the project using the following BibTeX:

```bibtex
@misc{whisperkit-argmax,
   title = {Argmax OSS: On-device Speech AI with WhisperKit, SpeakerKit and TTSKit},
   author = {Argmax, Inc.},
   year = {2024},
   URL = {https://github.com/argmaxinc/argmax-oss-swift}
}
```

```

**Tool: bash**

**Input:**
```json
{
  "command": "ls -la ~/.cache/huggingface/hub/ 2>/dev/null | grep -i whisper | head -20",
  "description": "Check local Whisper model cache"
}
```

**Output:**
```
drwxr-xr-x@  6 emile.bassil  staff  192 15 Jul 12:59 models--openai--whisper-base
drwxr-xr-x@  6 emile.bassil  staff  192 15 Jul 12:40 models--openai--whisper-large-v3-turbo
drwxr-xr-x   5 emile.bassil  staff  160 18 May 21:00 models--Systran--faster-whisper-large-v3

```

---

## Assistant (Build · Big Pickle · 39.2s)

_Thinking:_

Interesting! The user has:
- `models--openai--whisper-large-v3-turbo` (the one they want)
- `models--openai--whisper-base`
- `models--Systran--faster-whisper-large-v3`

The whisper-large-v3-turbo is in the HuggingFace cache. But WhisperKit uses its own model format (CoreML converted). The user's HuggingFace cache has the original PyTorch/ONNX weights, not the CoreML format that WhisperKit needs.

Wait, let me re-read. The user says "openai--whisper-large-v3-turbo which I already have in my huggingface cache locally." The directory is `models--openai--whisper-large-v3-turbo`.


So there's a mismatch here—WhisperKit expects CoreML-converted models from argmaxinc's repository, but the user has the original OpenAI weights in their cache. I need to figure out if WhisperKit can actually load from the standard HuggingFace cache format, or if the user needs to download the CoreML version instead.

Looking at the architecture, WhisperKit supports a `modelRepo` parameter, so it could theoretically pull from `openai/whisper-large-v3-turbo`, but the real issue is that the PyTorch weights aren't directly usable—they need to be in CoreML format. The user would either need to download the pre-converted CoreML models from argmaxinc or use a conversion tool. This is a critical detail to clarify with them.

Now I'm thinking through the core design questions: whether to use WhisperKit for native CoreML support or wrap the Python Whisper model via a subprocess (which goes against their efficiency goals), how to structure the app itself, how to capture system audio for meetings, and how to handle global hotkeys.

I should also consider the text cleanup pipeline and figure out what's actually feasible given their constraints. Let me organize this into a clear thinking framework to walk through with them.

Good — I can see the landscape now. Let me lay out what I've found and the interesting tensions in this design.

---

## The Model Situation — First Critical Decision

You have `models--openai--whisper-large-v3-turbo` in your HuggingFace cache. But there's a catch:

```
~/.cache/huggingface/hub/
├── models--openai--whisper-large-v3-turbo    ← You have this (PyTorch weights)
└── models--openai--whisper-base
```

**WhisperKit** (Argmax's framework — used by macparakeet) needs **CoreML-converted** models, which live in a *different* HuggingFace repo:

```
argmaxinc/whisperkit-coreml/
├── openai_whisper-large-v3-v20240930_turbo    ← What WhisperKit actually loads
└── openai_whisper-large-v3-v20240930_626MB    ← Compressed variant
```

This is the central design fork:

```
┌─────────────────────────────────────────────────────────┐
│              HOW TO RUN WHISPER ON MAC?                  │
├──────────────────────┬──────────────────────────────────┤
│                      │                                  │
│   Option A           │   Option B                       │
│   WhisperKit         │   Direct CoreML                  │
│   (Argmax OSS)       │   (DIY pipeline)                 │
│                      │                                  │
│   ✅ Proven path     │   ✅ Full control                │
│   ✅ Used by         │   ✅ No WhisperKit dependency     │
│      macparakeet     │   ⚠️  Must convert model         │
│   ✅ CoreML optimized│      yourself                     │
│   ⚠️  Downloads its  │   ⚠️  More audio pipeline work   │
│      own model copy  │                                  │
│   ⚠️  Heavy dep      │                                  │
│      (swift-trans-   │                                  │
│       formers, etc)  │                                  │
└──────────────────────┴──────────────────────────────────┘
```

**Key question:** Do you want WhisperKit (standards-based, macparakeet-like, but adds ~600MB of its own model on top of yours), or do you want to convert the model to CoreML yourself and load it directly?

---

## Architecture Sketch — What "Whisptator" Needs

Here's the system I see:

```
┌──────────────────────────────────────────────────────────────────┐
│                        WHISPTATOR                                 │
│                                                                   │
│  ┌─────────────┐    ┌──────────────┐    ┌────────────────────┐   │
│  │  Global      │    │  Audio       │    │  STT Engine        │   │
│  │  Hotkey      │───▶│  Capture     │───▶│  (WhisperKit or    │   │
│  │  Monitor     │    │  (AVFoundation│    │   direct CoreML)   │   │
│  │  (CGEvent)   │    │   + Screen-  │    │                    │   │
│  └──────┬───────┘    │   CaptureKit)│    └────────┬───────────┘   │
│         │            └──────────────┘             │               │
│         │                                          │               │
│         ▼                                          ▼               │
│  ┌─────────────┐    ┌──────────────┐    ┌────────────────────┐   │
│  │  Paste into  │    │  Text        │    │  Transcript        │   │
│  │  frontmost   │◀──│  Cleanup     │◀───│  (raw text)        │   │
│  │  app (CGKey) │    │  Pipeline    │    │                    │   │
│  └──────────────┘    └──────────────┘    └────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  Settings Window (SwiftUI)                                │    │
│  │  • Audio device picker                                    │    │
│  │  • Model selector (scan ~/.cache/huggingface/hub)        │    │
│  │  • Shortcut recorder (push-to-talk + hands-free)         │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  Meeting Mode (optional, later)                           │    │
│  │  • System audio (ScreenCaptureKit) + Mic                  │    │
│  │  • Live transcript preview                                │    │
│  │  • Notes during recording                                 │    │
│  │  • Save/export finalized transcript                       │    │
│  └──────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
```

---

## The Hard Technical Problems

Let me map the tricky bits:

### 1. Global Hotkeys on macOS

This is well-trodden ground. MacParakeet uses `CGEvent` taps. The pattern:

```
┌────────────────────────────────────────────────────┐
│  CGEvent Tap (requires Accessibility permission)    │
│                                                     │
│  Keyboard event ──▶ Match against saved shortcut     │
│                       │                              │
│                 ┌─────┴─────┐                        │
│                 │ Push-to-  │  Hands-free             │
│                 │ talk      │  (toggle)               │
│                 │ (hold)    │  (tap)                  │
│                 └─────┬─────┘                        │
│                       │                              │
│              Start/stop audio capture                │
└────────────────────────────────────────────────────┘
```

**Push-to-talk** = key down → record, key up → stop + transcribe + paste
**Hands-free** = tap → start recording, tap again → stop + transcribe + paste

### 2. Pasting into the Frontmost App

```
  Current frontmost app
         │
         ▼
  AXIsProcessTrusted? ──No──▶ Prompt for Accessibility
         │
        Yes
         │
         ▼
  Save current pasteboard
         │
         ▼
  CGEvent: Cmd+V (or type text via CGEvent keyboard events)
         │
         ▼
  Restore pasteboard
```

This is the "magic" moment — user speaks, text appears where they're typing. Requires Accessibility permission.

### 3. Meeting Recording — System Audio

This is the hardest part. macOS doesn't let you capture system audio without ScreenCaptureKit (macOS 13+). The permission model:

```
┌──────────────────────────────────────────────────┐
│  Audio Capture Sources                            │
├────────────────────┬─────────────────────────────┤
│  Microphone-only   │  System audio                │
│  (AVFoundation)    │  (ScreenCaptureKit)          │
│                    │                              │
│  ✅ Simple         │  ⚠️  Requires user to         │
│  ✅ No special     │     select a window/screen   │
│     permission     │  ⚠️  Shows macOS picker       │
│                    │  ⚠️  SCContentSharingPicker   │
└────────────────────┴─────────────────────────────┘

  Combined: Mix mic stream + system audio stream
            before feeding to Whisper
```

### 4. Text Cleanup Pipeline

MacParakeet has a good model for this — deterministic, no LLM:

```
  Raw transcript
       │
       ▼
  ┌─────────────┐
  │ Filler       │  "um", "uh", sentence-start "so", "well", "like"
  │ removal      │
  └──────┬──────┘
         ▼
  ┌─────────────┐
  │ Custom       │  "aye pee eye" → "API"
  │ word rules   │  Case-insensitive, whole-word
  └──────┬──────┘
         ▼
  ┌─────────────┐
  │ Voice return │  "press return" at end → strip + simulate Return
  └──────┬──────┘
         ▼
  ┌─────────────┐
  │ Snippet      │  "my signature" → "Best regards, Emile"
  │ expansion    │  Longest-first matching
  └──────┬──────┘
         ▼
  ┌─────────────┐
  │ Whitespace   │  Collapse spaces, fix punct spacing, capitalize
  │ cleanup      │
  └──────┬──────┘
         ▼
  Clean text → paste
```

---

## What I'd Recommend Exploring

Here's where the interesting design tension lives:

**Scope decision:** MacParakeet is a *huge* app (2,000+ commits, file/URL transcription, meeting recording, AI features, calendar integration, CLI). Do you want to build all of that, or is the core value:

```
┌─────────────────────────────────────────────────────┐
│  SCOPE SPECTRUM                                      │
│                                                      │
│  Minimal ◀─────────────────────────────────▶ Full    │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │ Dictation│  │ +Meeting │  │ +File/URL│          │
│  │ only     │  │ recording│  │ +AI      │          │
│  │          │  │          │  │ +CLI     │          │
│  │ Hotkey → │  │ +Live    │  │ +Calendar│          │
│  │ record → │  │ preview  │  │ +Transforms│        │
│  │ transcribe│ │ +Notes   │  │          │          │
│  │ → paste  │  │ +Export  │  │          │          │
│  └──────────┘  └──────────┘  └──────────┘          │
│                                                      │
│  MVP ──────────▶ V1 ──────────────▶ V2              │
└─────────────────────────────────────────────────────┘
```

**The "just works" dictation loop is the hardest part to get right and the most valuable.** Meeting recording is a separate feature with its own complex permission model.

---

## Questions I'm Sitting With

1. **Model format** — Do you want to use WhisperKit (which downloads its own CoreML model), or do you want to convert `openai/whisper-large-v3-turbo` to CoreML yourself and load it directly? The latter keeps your existing cache, the former is less work.

2. **Scope for V1** — Dictation only (hotkey → record → transcribe → paste)? Or do you want meeting recording in V1 too?

3. **UI approach** — MacParakeet has a full window with tabs (Transcribe, Library, Dictation stats). Your spec says "simple UI." Do you want a menu bar app with a settings popover? Or a small floating panel?

4. **The "paste" mechanism** — When you say "pasted in the window that is highlighted at the time of triggering," do you mean the text literally appears as if typed (CGEvent key simulation), or pasted from clipboard (Cmd+V)? CGEvent typing is more reliable but slower for large text. Clipboard paste is instant but clobbers whatever was in the pasteboard.

5. **HuggingFace cache scanning** — For the model selector in settings, should it scan `~/.cache/huggingface/hub/` and show all `models--*whisper*` directories? Or do you want a fixed list of known models?

What's pulling you right now? Want to dig into any of these threads?

---

## User

Model format: convert openai/whisper-large-v3-turbo to CoreML. Scope for V1: both. UI approach: Menu bar app. The "paste" mechanism: text literally appears as if typed and or pasted from clipboard (Cmd+V). Both options configurable from the app settings. Default to clipboard Cmd+V. HuggingFace cache scanning: I want a fixed list of known models.

---

## Assistant (Build · Big Pickle · 7.6s)

_Thinking:_

The user has made clear decisions on all the questions I raised. Let me now dig deeper into the technical implications and explore the architecture more thoroughly.

Key decisions:
1. Convert whisper-large-v3-turbo to CoreML directly (not WhisperKit)
2. V1 includes both dictation AND meeting recording
3. Menu bar app
4. Both paste mechanisms (CGEvent typing + clipboard Cmd+V), configurable, default to clipboard
5. Fixed list of known models

Let me think about what this means architecturally and explore the harder technical problems.

Let me look at how to convert Whisper to CoreML, and understand the ScreenCaptureKit approach for system audio.

Good — those are clean decisions. Let me dig into the implications.

**Tool: websearch**

**Input:**
```json
{
  "query": "convert openai whisper large v3 turbo to CoreML format Swift 2025 2026",
  "numResults": 5
}
```

**Output:**
```
{
  "search_id": "search_6565a57b27c141d9b25ddd6da907fecf",
  "results": [
    {
      "url": "https://github.com/gurpreetsaini/WhisperToCoreMLConversion",
      "title": "GitHub - gurpreetsaini/WhisperToCoreMLConversion: Whisper to ...",
      "publish_date": null,
      "excerpts": [
        "Skip to content\nYou signed in with another tab or window. Reload to refresh your session. You signed out in another tab or window. Reload to refresh your session. You switched accounts on another tab or window. Reload to refresh your session.\nDismiss alert\ngurpreetsaini / WhisperToCoreMLConversion Public\n    * Notifications\nYou must be signed in to change notification settings\n    * Fork 0\n    * Star 0\n\nWhisper to CoreML conversion\n0 stars 0 forks Branches Tags Activity\nStar\nNotifications\nYou must be signed in to change notification settings gurpreetsaini/WhisperToCoreMLConversion\n main Branches Tags\nGo to file\nCode Open more actions menu\nFolders and files\n\n\n\n\n\nRepository files navigation\n    * README\n\nWhisper to CoreML Converter\nConvert OpenAI Whisper models to Apple CoreML format with optional Apple Neural Engine (ANE) optimizations for better performance on Apple devices.\nFeatures\n    * Convert Whisper models (tiny, base, small, medium, large) to CoreML\n* Support for encoder-only conversion for efficient audio feature extraction\n    * Complete pipeline : Both encoder and decoder conversion for full speech-to-text\n    * Tokenizer extraction : Extract and save Whisper tokenizer for text processing\n    * Apple Neural Engine (ANE) optimizations available\n    * 16-bit quantization support for smaller model sizes\n    * SSL certificate issue handling for macOS\n    * Full compatibility with iOS and macOS applications\n    * End-to-end pipeline demo with beam search support\n\nRequirements\n    * Python 3.10+ (tested with Python 3.12)\n    * macOS (for CoreML tools)\n    * At least 4GB free disk space (models can be large)\n\nInstallation\n    * Clone this repository:\n\ngit clone < repository-url > cd WhisperConversion\n    * Create a virtual environment:\n\npython3 -m venv whisper_env source whisper_env/bin/activate # On Windows: whisper_env\\Scripts\\activate\n    * Install dependencies:\n\npip install -r requirements.txt\nUsage\nComplete Pipeline (Encoder + Decoder + Tokenizer)\nConvert both encoder and decoder for full speech-to-text capability:\n# Convert complete pipeline for small model python whisper_coreml_fixed.py --model small --output-dir ./converted_models # Extract tokenizer python extract_tokenizer.py --model small --output-dir ./tokenizer # Test complete pipeline python complete_pipeline_demo.py\nBasic Usage\nConvert individual components:\n# Convert base model encoder only python whisper_coreml_fixed.py --model base --encoder-only --output-dir ./converted_models # Convert small model with both encoder and decoder python whisper_coreml_fixed.py --model small --output-dir ./converted_models # Convert with quantization for smaller size python whisper_coreml_fixed.py --model base --encoder-only --quantize --output-dir ./converted_models # Convert with ANE optimization python whisper_coreml_fixed.py --model base --encoder-only --optimize-ane --output-dir ./converted_models\nAvailable Models"
      ]
    },
    {
      "url": "https://soniqo.audio/ru/guides/whisper",
      "title": "Whisper Large-v3 Turbo — Native CoreML Speech-to-Text — Документация Soniqo",
      "publish_date": null,
      "excerpts": [
        "# Whisper Large-v3 Turbo\n\nЭта страница Soniqo описывает Whisper Large-v3 Turbo из локальной реализации speech-swift / speech-core. Ссылки на Hugging Face находятся ниже после заметок по интеграции.\n\nСначала внутренняя страница\n\nКарточки и меню документации сначала ведут сюда; ссылки на исходную модель и бандлы остаются на этой странице.\n\n## Кратко\n\n|Модель |Whisper Large-v3 Turbo |\n| --- | --- |\n|Роль |General multilingual speech-to-text |\n|Backend |CoreML fp16 on CPU and Neural Engine |\n|Вывод |Text transcript |\n|Языки |Whisper multilingual set, about 100 languages |\n|Лицензия |MIT weights from OpenAI |\n|Статус |Ready through speech transcribe --engine whisper and the WhisperASR Swift product |\n|Источник |[openai/whisper-large-v3-turbo](https://huggingface.co/openai/whisper-large-v3-turbo) |\n|Swift-продукт |`WhisperASR` |\n|CLI / runtime |`speech transcribe --engine whisper` |\n## Использование\n\nФрагмент ниже соответствует текущему API или команде из speech-swift.\n\n```\n# Transcribe with the native CoreML Whisper runtime.\n.build/release/speech transcribe recording.wav --engine whisper\n.build/release/speech transcribe recording.wav --engine whisper --language en\n```\n\n## Ссылки модели\n\n* [CoreML bundle](https://huggingface.co/aufklarer/Whisper-Large-v3-Turbo-CoreML)\n* [speech-swift model docs](https://github.com/soniqo/speech-swift/blob/main/docs/models/whisper-asr.md)\n* [speech-swift inference docs](https://github.com/soniqo/speech-swift/blob/main/docs/inference/whisper-asr-inference.md)\n\n## Заметки реализации\n\n* LibriSpeech test-clean slice on an M5 Pro: 1.40% WER, mean RTF 0.089, 6.1 s model load, 384 MB peak RSS — versus 1.53% / 0.085 / 100.2 s / 507 MB for a direct WhisperKit run of the same model.\n* The bundle splits into four CoreML models — mel spectrogram, audio encoder, decoder context prefill, and a KV-cached text decoder — with the encoder and decoder on the Neural Engine.\n* Greedy no-timestamp decoding with automatic language detection or a --language hint; audio is processed in 30 s chunks with a repeated-word guard against greedy hallucination loops.\n* Word timestamps, temperature fallback, and VAD-guided long-form seeking are not implemented yet; --model accepts turbo, large-v3-turbo, or any Hugging Face repo ID."
      ]
    },
    {
      "url": "https://soniqo.audio/guides/whisper",
      "title": "Whisper Large-v3 Turbo — Native CoreML Speech-to-Text ...",
      "publish_date": null,
      "excerpts": [
        "# Whisper Large-v3 Turbo\n\nThis first-party Soniqo page documents Whisper Large-v3 Turbo from the local speech-swift / speech-core implementation. Hugging Face bundles are linked below after the integration notes.\n\nInternal Page First\n\nLanding cards and docs menus now point here first; source model and bundle links remain available from this page.\n\n## At a Glance\n\n|Model |Whisper Large-v3 Turbo |\n| --- | --- |\n|Role |General multilingual speech-to-text |\n|Backend |CoreML fp16 on CPU and Neural Engine |\n|Output |Text transcript |\n|Languages |Whisper multilingual set, about 100 languages |\n|License |MIT weights from OpenAI |\n|Status |Ready through speech transcribe --engine whisper and the WhisperASR Swift product |\n|Source |[openai/whisper-large-v3-turbo](https://huggingface.co/openai/whisper-large-v3-turbo) |\n|Swift product |`WhisperASR` |\n|CLI / runtime |`speech transcribe --engine whisper` |\n\n## Use\n\nThe snippet below mirrors the current speech-swift API or command exposed by the repo.\n```\n# Transcribe with the native CoreML Whisper runtime.\n.build/release/speech transcribe recording.wav --engine whisper\n.build/release/speech transcribe recording.wav --engine whisper --language en\n```\n\n## Model Links\n\n* [CoreML bundle](https://huggingface.co/aufklarer/Whisper-Large-v3-Turbo-CoreML)\n* [speech-swift model docs](https://github.com/soniqo/speech-swift/blob/main/docs/models/whisper-asr.md)\n* [speech-swift inference docs](https://github.com/soniqo/speech-swift/blob/main/docs/inference/whisper-asr-inference.md)\n\n## Implementation Notes\n\n* LibriSpeech test-clean slice on an M5 Pro: 1.40% WER, mean RTF 0.089, 6.1 s model load, 384 MB peak RSS — versus 1.53% / 0.085 / 100.2 s / 507 MB for a direct WhisperKit run of the same model.\n* The bundle splits into four CoreML models — mel spectrogram, audio encoder, decoder context prefill, and a KV-cached text decoder — with the encoder and decoder on the Neural Engine.\n* Greedy no-timestamp decoding with automatic language detection or a --language hint; audio is processed in 30 s chunks with a repeated-word guard against greedy hallucination loops.\n* Word timestamps, temperature fallback, and VAD-guided long-form seeking are not implemented yet; --model accepts turbo, large-v3-turbo, or any Hugging Face repo ID."
      ]
    },
    {
      "url": "https://github.com/soniqo/speech-swift",
      "title": "GitHub - soniqo/speech-swift: AI speech toolkit for Apple Silicon — ASR, TTS, speech-to-speech, VAD, and diarization powered by MLX and CoreML · GitHub",
      "publish_date": null,
      "excerpts": [
        "Available SPM products: `Qwen3ASR` , `WhisperASR` , `Qwen3TTS` , `Qwen3TTSCoreML` , `ParakeetASR` , `ParakeetStreamingASR` , `NemotronStreamingASR` , `OmnilingualASR` , `KokoroTTS` , `SupertonicTTS` , `VibeVoiceTTS` , `CosyVoiceTTS` , `VoxCPM2TTS` , `IndexTTS2TTS` , `F5TTS` , `HiggsTTS` , `ChatterboxTTS` , `OmniVoiceTTS` , `IndicMioTTS` , `FishAudioTTS` , `MagpieTTS` , `MagpieTTSCoreML` , `MAGNeTMusicGen` , `StableAudio3MusicGen` , `FlashSR` , `PersonaPlex` , `Audio2Face3D` , `HibikiTranslate` , `MADLADTranslation` , `SpeechVAD` , `SpeechWakeWord` , `SpeechEnhancement` , `SpeechRestoration` , `SourceSeparation` , `Qwen3Chat` , `FunctionGemma` , `SpeechCore` , `SpeechUI` , `AudioCommon` .\n\n## Models\n\nCompact view below. **[Full model catalogue with sizes, quantisations, download URLs, and memory tables → soniqo.audio/architecture](https://soniqo.audio/architecture)** .\n\n|Model |Task |Backends |Sizes |Languages |\n| --- | --- | --- | --- | --- |\n|[Qwen3-ASR](https://soniqo.\naudio/guides/transcribe) |Speech → Text |MLX, CoreML (hybrid) |0\\.6B, 1.7B |52 |\n|[WhisperASR](https://github.com/soniqo/speech-swift/blob/main/docs/models/whisper-asr.md) |Speech → Text |CoreML (ANE) |Large-v3 Turbo |Multi |\n|[Parakeet TDT](https://soniqo.audio/guides/parakeet) |Speech → Text |CoreML (ANE) |0\\.6B |25 European |\n|[Parakeet EOU](https://soniqo.audio/guides/dictate) |Speech → Text (streaming) |CoreML (ANE) |120M |25 European |\n|[Nemotron Streaming (Multilingual)](https://soniqo.audio/guides/nemotron) |Speech → Text (streaming, punctuated) |CoreML (ANE), MLX |0\\.6B |**40** |\n|[Nemotron Streaming (English)](https://soniqo.audio/guides/nemotron) |Speech → Text (streaming, punctuated) |CoreML (ANE) |0\\.6B |EN |\n|[Omnilingual ASR](https://soniqo.audio/guides/omnilingual) |Speech → Text |CoreML (ANE), MLX |300M / 1B / 3B / 7B |**[1,672](https://github.com/facebookresearch/omnilingual-asr/blob/main/src/omnilingual_asr/models/wav2vec2_llama/lang_ids.py)** |\n|[Qwen3-ForcedAligner](https://soniqo.audio/guides/align) |Audio + Text → Timestamps |MLX, CoreML |0\\.6B |Multi |\n|[Qwen3-TTS](https://soniqo.audio/guides/speak) |Text → Speech |MLX, CoreML |0\\.6B, 1.7B |10 |\n|[CosyVoice3](https://soniqo.audio/guides/cosyvoice) |Text → Speech |MLX |0\\.5B |9 |\n|[VoxCPM2](https://soniqo.audio/speech-generation) |Text → Speech (48 kHz, voice design + cloning) |MLX |2B (bf16/int8) |30 |\n|[IndexTTS2](https://github.com/soniqo/speech-swift/blob/main/docs/models/indextts2.md) |Text → Speech (zero-shot voice cloning) |MLX |1\\.5B-class (fp16) |EN/ZH |\n|[F5-TTS](https://github.com/soniqo/speech-swift/blob/main/docs/models/f5-tts.md) |Text → Speech (zero-shot voice cloning) |MLX |336M (fp16) |EN/ZH |\n|[Higgs TTS 3](https://github.com/soniqo/speech-swift/blob/main/docs/models/higgs-tts.md) |Text → Speech (conversational, zero-shot voice cloning) |MLX |4B (bf16) |100+ |\n|[Kokoro-82M](https://soniqo.audio/guides/kokoro) |Text → Speech |CoreML (ANE) |82M |10 |"
      ]
    },
    {
      "url": "https://deepwiki.com/vade/OpenAI-Whisper-CoreML",
      "title": "vade/OpenAI-Whisper-CoreML | DeepWiki",
      "publish_date": "2025-07-03",
      "excerpts": [
        "Loading...\n\nIndex your code with Devin\n\nDeepWiki\n\nDeepWiki\n\n[vade/OpenAI-Whisper-CoreML](https://github.com/vade/OpenAI-Whisper-CoreML \"Open repository\")\n\nIndex your code with\n\nDevin Edit Wiki Share\n\nLoading...\n\nMenu\n\n# Overview\n\nRelevant source files\n\n* [README.md](https://github.com/vade/OpenAI-Whisper-CoreML/blob/2c60f5cb/README.md?plain=1)\n* [Whisper/Whisper.xcodeproj/project.pbxproj](https://github.com/vade/OpenAI-Whisper-CoreML/blob/2c60f5cb/Whisper/Whisper.xcodeproj/project.pbxproj)\n\nThis document provides a high-level overview of the OpenAI Whisper CoreML repository, a native Swift implementation of OpenAI's Whisper automatic speech recognition model optimized for Apple Silicon and the Apple Neural Engine. The system provides both asset-based and real-time speech-to-text transcription capabilities through a unified API.\n\nFor detailed information about specific components, see Core Architecture , User Interface , Audio Input , and Development Guide .\n\n## Purpose and Scope\nThe OpenAI Whisper CoreML project is a complete port of the Whisper speech recognition model to Apple's CoreML framework. It replaces the original PyTorch implementation with native Swift code that leverages Apple's hardware acceleration features, including the Apple Neural Engine, Accelerate framework, and platform-specific audio processing APIs.\n\nThe system supports both iOS and macOS platforms, providing live microphone recording on iOS through `AudioRecorder` and file-based transcription on macOS through `AudioLoader` . All transcription is performed locally on-device without requiring network connectivity.\n\n## System Architecture\n\nThe following diagram shows the main system components and their relationships:\n\n**Sources:** [Whisper/Whisper.xcodeproj/project.pbxproj 1-512](https://github.com/vade/OpenAI-Whisper-CoreML/blob/2c60f5cb/Whisper/Whisper.xcodeproj/project.pbxproj) [README.md 1-48](https://github.com/vade/OpenAI-Whisper-CoreML/blob/2c60f5cb/README.md?plain=1)\n## Core Components\n\n### Whisper Engine\n\nThe `Whisper` class serves as the main orchestrator, providing two primary APIs:\n\n* `transcribe(assetURL:URL, options:WhisperOptions)` \\- Asset-based transcription\n* `startWhisperSession(options:WhisperOptions)` and `accrueSamplesFromSampleBuffer(sampleBuffer:CMSampleBuffer)` \\- Real-time transcription\n\nThe engine coordinates between audio processing, CoreML inference, and text generation phases.\n\n### Audio Processing Pipeline\n\nThe audio processing chain converts raw audio samples into mel spectrograms suitable for the CoreML encoder:\n\n|Component |File |Purpose |\n| --- | --- | --- |\n|FFT |`FFT.swift` |Time-domain to frequency-domain conversion |\n|STFT |`STFT.swift` |Short-time windowed analysis |\n|MelSpectrogram |`MelSpectrogram.swift` |Perceptual frequency scaling |\n\n### CoreML Models\n\nTwo CoreML models perform the core inference:\n\n* `encoder_base.mlpackage` \\- Converts mel spectrograms to audio features\n* `decoder_base."
      ]
    },
    {
      "url": "https://huggingface.co/openai/whisper-large-v3-turbo",
      "title": "openai/whisper-large-v3-turbo · Hugging Face",
      "publish_date": null,
      "excerpts": [
        "How to use openai/whisper-large-v3-turbo with Transformers:\n  \n  ```\n  # Use a pipeline as a high-level helper\n  from transformers import pipeline\n  \n  pipe = pipeline(\"automatic-speech-recognition\", model=\"openai/whisper-large-v3-turbo\")\n  ```\n  \n  ```\n  # Load model directly\n  from transformers import AutoProcessor, AutoModelForSpeechSeq2Seq\n  \n  processor = AutoProcessor.from_pretrained(\"openai/whisper-large-v3-turbo\")\n  model = AutoModelForSpeechSeq2Seq.from_pretrained(\"openai/whisper-large-v3-turbo\")\n  ```\n* Inference\n* Inference Providers\n* Notebooks\n* Google Colab\n* Kaggle\n* AMD Developer Cloud\n\n* Whisper\n  \n    + Usage\n    + Additional Speed & Memory Improvements\n        \n        - Chunked Long-Form\n    + Model details\n    + Fine-Tuning\n        \n        - Evaluated Use\n    + Training Data\n    + Performance and Limitations\n    + Broader Implications\n        \n        - BibTeX entry and citation info\n\n#  Whisper\nWhisper is a state-of-the-art model for automatic speech recognition (ASR) and speech translation, proposed in the paper [Robust Speech Recognition via Large-Scale Weak Supervision](https://huggingface.co/papers/2212.04356) by Alec Radford et al. from OpenAI. Trained on >5M hours of labeled data, Whisper demonstrates a strong ability to generalise to many datasets and domains in a zero-shot setting.\n\nWhisper large-v3-turbo is a finetuned version of a pruned [Whisper large-v3](https://huggingface.co/openai/whisper-large-v3) . In other words, it's the exact same model, except that the number of decoding layers have reduced from 32 to 4.\nAs a result, the model is way faster, at the expense of a minor quality degradation. You can find more details about it [in this GitHub discussion](https://github.com/openai/whisper/discussions/2363) .\n**Disclaimer** : Content for this model card has partly been written by the 🤗 Hugging Face team, and partly copied and pasted from the original model card.\n\n##  Usage\n\nWhisper large-v3-turbo is supported in Hugging Face 🤗 Transformers. To run the model, first install the Transformers library. For this example, we'll also install 🤗 Datasets to load toy audio dataset from the Hugging Face Hub, and 🤗 Accelerate to reduce the model loading time:\n\n```\npip install --upgrade pip\npip install --upgrade transformers datasets[audio] accelerate\n```\n\nThe model can be used with the [`pipeline`](https://huggingface.co/docs/transformers/main_classes/pipelines.AutomaticSpeechRecognitionPipeline) class to transcribe audios of arbitrary length:\n\n```\nimport  torch\n from  transformers  import  AutoModelForSpeechSeq2Seq, AutoProcessor, pipeline\n from  datasets  import  load_dataset\n\ndevice =  \"cuda:0\" if  torch.cuda.is_available()  else \"cpu\" \ntorch_dtype = torch.float16  if  torch.cuda."
      ]
    },
    {
      "url": "https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/openai_whisper-large-v3_turbo",
      "title": "argmaxinc/whisperkit-coreml at main - Hugging Face",
      "publish_date": null,
      "excerpts": [
        "# \n\nargmaxinc\n\n/\n\nwhisperkit-coreml\n\nlike 197\n\nFollow\n\nArgmax 215\n\n[Automatic Speech Recognition](https://huggingface.co/models?pipeline_tag=automatic-speech-recognition) [WhisperKit](https://huggingface.co/models?library=whisperkit) [Core ML](https://huggingface.co/models?library=coreml) [whisper](https://huggingface.co/models?other=whisper) [asr](https://huggingface.co/models?other=asr) [quantized](https://huggingface.co/models?other=quantized)\n\nModel card Files Files and versions xet [Community 23](https://huggingface.co/argmaxinc/whisperkit-coreml/discussions)\n\nCopy to bucket new\n\nUse this model\n\n### Instructions to use argmaxinc/whisperkit-coreml with libraries, inference providers, notebooks, and local apps. Follow these links to get started.\n\n* Libraries\n* [WhisperKit](https://huggingface.co/argmaxinc/whisperkit-coreml?library=whisperkit)\n  \n  How to use argmaxinc/whisperkit-coreml with WhisperKit:\n  \n  ```\n  # Install CLI with Homebrew on macOS device\nbrew install whisperkit-cli\n  \n  # View all available inference options\n  whisperkit-cli transcribe --help\n  \n  # Download and run inference using whisper base model\n  whisperkit-cli transcribe --audio-path /path/to/audio.mp3\n  \n  # Or use your preferred model variant\n  whisperkit-cli transcribe --model \"large-v3\" --model-prefix \"distil\" --audio-path /path/to/audio.mp3 --verbose\n  ```\n* Notebooks\n* Google Colab\n* Kaggle\n\nmain\n\nwhisperkit-coreml / openai\\_whisper-large-v3\\_turbo\n\n3\\.2 GB\n\n`Ctrl+K`\n\n`Ctrl+K`\n\n[* * * * * * 9 contributors](https://huggingface.co/argmaxinc/whisperkit-coreml/commits/main/openai_whisper-large-v3_turbo) [History: 3 commits](https://huggingface.co/argmaxinc/whisperkit-coreml/commits/main/openai_whisper-large-v3_turbo)\n\nb-argmax's picture\n\nb-argmax\n\nupdate protobufs - noncompressed ( [\\#7](https://huggingface.co/argmaxinc/whisperkit-coreml/discussions/7) )\n\n[3388c46](https://huggingface.\nco/argmaxinc/whisperkit-coreml/commit/3388c46a312ab1e9f46fe4c9f6697f948d59e03e) verified almost 2 years ago\n\n* AudioEncoder.mlmodelc [pr-2 ()](https://huggingface.co/argmaxinc/whisperkit-coreml/commit/eaab173308732dd4450d15ef16b354e2d616762d) [almost 2 years ago](https://huggingface.co/argmaxinc/whisperkit-coreml/commit/eaab173308732dd4450d15ef16b354e2d616762d)\n* MelSpectrogram.mlmodelc [whisperkittools-f6bc74140b8889f920ed56a9670c0676f69f9c9a generated files: openai\\_whisper-large-v3\\_turbo](https://huggingface.co/argmaxinc/whisperkit-coreml/commit/2dfe64621d97c2013ee4e5f4cc3e332f85e36011) [over 2 years ago](https://huggingface.co/argmaxinc/whisperkit-coreml/commit/2dfe64621d97c2013ee4e5f4cc3e332f85e36011)\n* TextDecoder.mlmodelc [update protobufs - noncompressed ()](https://huggingface.co/argmaxinc/whisperkit-coreml/commit/3388c46a312ab1e9f46fe4c9f6697f948d59e03e) [almost 2 years ago](https://huggingface.co/argmaxinc/whisperkit-coreml/commit/3388c46a312ab1e9f46fe4c9f6697f948d59e03e)\n\n...\n\nco/argmaxinc/whisperkit-coreml/resolve/main/openai_whisper-large-v3_turbo/generation_config.json?download=true \"Download file\") [whisperkittools-f6bc74140b8889f920ed56a9670c0676f69f9c9a generated files: openai\\_whisper-large-v3\\_turbo](https://huggingface.co/argmaxinc/whisperkit-coreml/commit/2dfe64621d97c2013ee4e5f4cc3e332f85e36011) [over 2 years ago](https://huggingface.co/argmaxinc/whisperkit-coreml/commit/2dfe64621d97c2013ee4e5f4cc3e332f85e36011"
      ]
    },
    {
      "url": "https://github.com/vade/OpenAI-Whisper-CoreML",
      "title": "GitHub - vade/OpenAI-Whisper-CoreML: OpenAI's Whisper ported to CoreML · GitHub",
      "publish_date": null,
      "excerpts": [
        "# vade/OpenAI-Whisper-CoreML\n\n- Page: GitHub repository\n- URL: https://github.com/vade/OpenAI-Whisper-CoreML\n- Description: OpenAI's Whisper ported to CoreML\n- Stars: 152\n- Forks: 5\n- Default branch: feature/RosaKit\n- Created: 2023-01-02T17:39:36.000Z\n- Commits: 80\n\n## Top-level files\n\n- Whisper/\n- .gitignore\n- README.md\n- export_m80.py\n- whisper_to_cml.py\n\n## README.md\n\n# Whisper CoreML\n\nA port of OpenAI's Whisper Speech Transcription model to CoreML\n\nThe goal of this project is to natively port, and optimize Whisper for use on Apple Silicon including optimization for the Apple Neural Engine, and match the incredible WhisperCPP project on features.\n\n* * *\n\n_**Please note this repo is currently under development, so there will be bumps in the road.**_\n\n_**Community input is welcome!**_\n\n* * *\n\nYou can:\n\nCreate a Whipser instance `whisper = try Whisper()`\n\nAnd run transcription on a Quicktime compatible asset via: `await whisper.transcribe(assetURL:URL, options:WhisperOptions)`\nYou can choose options via the `WhisperOptions` struct.\n\nWhipser CoreML will load an asset using AVFoundation and convert the audio to the appropriate format for transcription.\n\nAlternatively, for realtime usage, you can call start a whisper session via `startWhisperSession(options:WhisperOptions)` , and then send sample buffers to `accrueSamplesFromSampleBuffer(sampleBuffer:CMSampleBuffer)` from say an AVCaptureSession or AVAudioSession, or any other source.\n\nNote, we accrue a 30 second sample for now as that is the expected number of samples required.\n\n## Status\n\n* Working Multi Lingual Transcription\n* [Optimize the CoreML models for ANE](https://machinelearning.apple.com/research/neural-engine-transformers) using [Apples ANE Transformers sample code found at this repository](https://github.com/apple/ml-ane-transformers)\n* Port Log Mel Spectrogram to native vDSP and ditch RosaKit package dependency.\n* Decode Special Tokens for time stamps.\n* Decide on API design\n\n## Performance\n* Base model gets roughly 4x realtime using a single core on an M1 Mac Book Pro.\n\n## Getting Models:\n\n[For ease of use, you can use this Google Colab to convert models](https://colab.research.google.com/drive/1IiBx6-hipt3ER3VjkjuUEAObwipHy1mL) . Note that if you convert Medium or larger models you may run into memory issues on Google Colab.\n\nThis repository assumes youre converting multilingual models. If you need 'en' models you'll need to adjust the special token values by negative 1."
      ]
    },
    {
      "url": "https://github.com/argmaxinc/argmax-oss-swift",
      "title": "GitHub - argmaxinc/argmax-oss-swift: On-device Speech AI for Apple Silicon · GitHub",
      "publish_date": null,
      "excerpts": [
        "|Base (multilingual) |[base](https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/openai_whisper-base) | |\n|Base (English-only) |[base.en](https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/openai_whisper-base.en) | |\n|Small (Multilingual) |[small](https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/openai_whisper-small) | |\n|Small (English-only) |[small.en](https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/openai_whisper-small.en) | |\n|Tiny (Multilingual) |[tiny](https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/openai_whisper-tiny) | |\n|Tiny (English-only) |[tiny.en](https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/openai_whisper-tiny.en) |Smallest size, lowest accuracy. Only recommended for development & debugging. |\n\nWhisperKit automatically downloads the recommended model for the device if not specified. You can also select a specific model by passing in the model name:\n\n```\nlet pipe = try ?\nawait WhisperKit ( WhisperKitConfig ( model : \" large-v3-v20240930_626MB \" ) )\n```\n\nThis method also supports glob search, so you can use wildcards to select a model:\n\n```\nlet pipe = try ? await WhisperKit ( WhisperKitConfig ( model : \" large-v3-v20240930_626MB \" ) )\n```\n\nNote that the model search must return a single model from the source repo, otherwise an error will be thrown.\n\nFor a list of available models, see our [HuggingFace repo](https://huggingface.co/argmaxinc/whisperkit-coreml) .\n\n### Generating Models\n\nWhisperKit also comes with the supporting repo [`whisperkittools`](https://github.com/argmaxinc/whisperkittools) which lets you create and deploy your own fine tuned versions of Whisper in CoreML format to HuggingFace. Once generated, they can be loaded by simply changing the repo name to the one used to upload the model:\n\n```\nlet config = WhisperKitConfig ( model : \" large-v3-v20240930_626MB \" , modelRepo : \" username/your-model-repo \" ) \n let pipe = try ?\nawait WhisperKit ( config )\n```\n\n### Swift CLI\n\nThe Swift CLI allows for quick testing and debugging outside of an Xcode project. To install it, run the following:\n\n```\ngit clone https://github.com/argmaxinc/argmax-oss-swift.git\n cd argmax-oss-swift\n```\n\nThen, setup the environment and download your desired model.\n\n```\nmake setup\nmake download-model MODEL=large-v3-v20240930_626MB\n```\n\n**Note** :\n\n1. This will download only the model specified by `MODEL` (see what's available in our [HuggingFace repo](https://huggingface.co/argmaxinc/whisperkit-coreml) , where we use the prefix `openai_whisper-{MODEL}` )\n2. Before running `download-model` , make sure [git-lfs](https://git-lfs.com) is installed\n\nIf you would like download all available models to your local folder, use this command instead:\n\n```\nmake download-models\n```\n\nYou can then run them via the CLI with:\n\n```"
      ]
    },
    {
      "url": "https://huggingface.co/aufklarer/Whisper-Large-v3-Turbo-CoreML",
      "title": "aufklarer/Whisper-Large-v3-Turbo-CoreML",
      "publish_date": "2026-07-10",
      "excerpts": [
        "aufklarer/Whisper-Large-v3-Turbo-CoreML\n3 days ago — The bundle splits Whisper into CoreML programs for mel extraction, audio encoding, context prefill, and token decoding. speech- swift loads"
      ]
    }
  ],
  "warnings": null,
  "usage": [
    {
      "name": "sku_search",
      "count": 1
    }
  ],
  "session_id": "ses_09bf56a63ffe6WwLYNXEvmuaZl"
}
```

**Tool: websearch**

**Input:**
```json
{
  "query": "ScreenCaptureKit capture system audio macOS Swift mixing microphone 2025",
  "numResults": 5
}
```

**Output:**
```
{
  "search_id": "search_af7793cb9fd84f80898652f0d4896365",
  "results": [
    {
      "url": "https://useraven.ai/blog/dual-stream-audio-capture-on-macos-with-screencapturekit",
      "title": "title: Dual-Stream Audio Capture on macOS with ScreenCaptureKit - Raven description: Raven is an open-source AI meeting copilot with real-time transcription, echo cancellation, and a stealth overlay invisible to screen sharing. Download free for macOS and Windows. published: \"May 19, 2026, 4:30 PM UTC\"",
      "publish_date": null,
      "excerpts": [
        "---\ntitle: Dual-Stream Audio Capture on macOS with ScreenCaptureKit - Raven\ndescription: Raven is an open-source AI meeting copilot with real-time transcription, echo cancellation, and a stealth overlay invisible to screen sharing. Download free for macOS and Windows.\npublished: \"May 19, 2026, 4:30 PM UTC\"\n---\n\n[Pricing](../pricing)\n\n[Docs](https://docs.useraven.ai)\n\n[Blog](../blog)\n\n[Changelog](../changelog)\n\n[View on Github](https://github.com/Laxcorp-Research/project-raven)\n\n[Pricing](../pricing)\n\n[Docs](https://docs.useraven.ai)\n\n[Blog](../blog)\n\n[Changelog](../changelog)\n\n[View on Github](https://github.com/Laxcorp-Research/project-raven)\n\n[Blog](../blog)\n\nEngineering\n\n# Dual-Stream Audio Capture on macOS with ScreenCaptureKit\n\nCapturing system audio on macOS used to require kernel extensions. With ScreenCaptureKit, Apple gave us a supported API - here's how Raven uses it alongside CoreAudio to capture both sides of a conversation.\n\nChaitanya Laxman\n\nProduct\n\nMar 2, 2026\nBefore macOS 12 Monterey, capturing system audio on a Mac was a hack. You needed a virtual audio device driver — Soundflower, BlackHole, Loopback - that installed a kernel extension to route audio. It worked, but it was fragile, required administrator access, broke with OS updates, and was a significant barrier for any app that needed system audio capture.\n\nWith macOS 12, Apple introduced ScreenCaptureKit, a high-level framework for capturing screen content and audio. For the first time, apps could capture system audio without any third-party drivers, using a supported API that works reliably across OS updates.\n\nRaven uses ScreenCaptureKit for system audio capture and CoreAudio for microphone capture, running simultaneously in a dedicated Swift process.\n\n**Why a separate Swift process?**\n\nRaven is an Electron app (TypeScript/JavaScript), but audio capture on macOS is best done from native code.\nScreenCaptureKit is a Swift/Objective-C framework that requires specific entitlements and works most reliably from a native macOS context. Rather than building a complex native Node.js module, we created a lightweight Swift command-line tool that handles audio capture and streams the results to the Electron main process via standard I/O pipes.\n\nThe Swift binary lives in `src/native/swift/AudioCapture/` and is built with `swift build -c release`. When Raven starts recording, the Electron main process spawns this binary as a child process and reads its output.\n\n**System audio capture with ScreenCaptureKit**\n\nScreenCaptureKit provides the `SCStream` class for capturing screen content. To capture system audio:\n1. We create an `SCStreamConfiguration` with `capturesAudio` set to `true` and `excludesCurrentProcessAudio` set to `true` (so Raven doesn't capture its own UI sounds).\n1. We create an `SCContentFilter` that specifies what to capture.\n\n...\n\n**The result**\n\nBoth platform implementations produce the same output: two clean PCM audio streams - system audio and microphone audio - ready for echo cancellation and transcription. The rest of Raven's pipeline (GStreamer AEC, Deepgram transcription, AI assistance) is platform-independent and works identically on both macOS and Windows.\n\nThe native audio capture code is about 600 lines of Swift on macOS and 900 lines of Rust on Windows. Both are open source and available in the Raven repository.\n\nChaitanya Laxman\n\nProduct\n\n[Tutorial Getting Started with Raven in Under 5 Minutes Mar 6, 2026](./getting-started-with-raven-in-under-5-minutes)\n\n[Engineering How We Built Echo Cancellation with WebRTC AEC3 Mar 3, 2026](./how-we-built-echo-cancellation-with-webrtc-aec3)\n\n[Tutorial Using Raven for Technical Interviews, A Step-by-Step Guide Mar 3, 2026](./using-raven-for-technical-interviews-a-step-by-step-guide)\n\n[Buy template](https://buy.polar."
      ]
    },
    {
      "url": "https://stackoverflow.com/questions/79807199/screencapturekit-recording-output-is-corrupted-when-capturemicrophone-is-true",
      "title": "swift - ScreenCaptureKit recording output is corrupted when captureMicrophone is true - Stack Overflow",
      "publish_date": "2025-11-02",
      "excerpts": [
        "stream = SCStream(filter: filter, configuration: configuration, delegate: streamOutput)\n            \n            // Add outputs for raw buffers (not used for file recording)\n            try stream?.addStreamOutput(streamOutput, type: .screen, sampleHandlerQueue: videoSampleBufferQueue)\n            try stream?.addStreamOutput(streamOutput, type: .audio, sampleHandlerQueue: audioSampleBufferQueue)\n            try stream?.addStreamOutput(streamOutput, type: .microphone, sampleHandlerQueue: micSampleBufferQueue)\n            \n            // Add the file recording output\n            try stream?.addRecordingOutput(recordingOutput)\n            \n            try await stream?.startCapture()\n            \n        } catch {\n            logger.error(\"Failed to start capture: \\(error.localizedDescription)\")\n            throw error\n        }\n    }\n    \n    // ... (stopCapture, etc.) ...\n}\n```\n\nWhen I had the `.captureMicrophone` value to be false, I get a perfect `.\nmp4` video playable everywhere, however, when its `true` , I am getting corrupted video which doesn't play at all :-\n\n[enter image description here](https://i.sstatic.net/jQhXD5Fd.png)\n\nPS :- Here is the corrupted video link ( google drive ) :- [https://drive.google.com/file/d/1E\\_EAWiaXGRcAHCEhL5GeBQXoRbhCzFoN/view?usp=sharing](https://drive.google.com/file/d/1E_EAWiaXGRcAHCEhL5GeBQXoRbhCzFoN/view?usp=sharing)\n\nAnother PS:- After multiple tries, the main problem is because of the .captureAudio to be true, this is causing mixing problem. When I had the .captureAudio to be false and the .captureMicrophone to be true, everything is working fine, I get the mp4 video with microhphone audio, however, if the audio capture is also true, than only the video breaks. Now the question is how to record both the audio?\n\n* swift\n* macos\n* audio\n* microphone\n* screencapturekit\n\nShare\n\nImprove this question\n\nFollow\n\nedited Nov 3, 2025 at 12:01\n\nasked Nov 2, 2025 at 14:45\n\nZaid's user avatar\n\nZaid\n521 1 1 silver badge 10 10 bronze badges\n\n10\n\n* Hello, I found SCRecordingOutput does not support microphone audio reliably → causes corrupted MP4s. Use AVAssetWriter + your SCStreamOutput delegate to manually write video + mic audio. This approach seems more robust and gives you full control over encoding.\n  \n  nseaprotector\n  \n  – nseaprotector\n  \n  2025-11-02 19:12:10 +00:00\n  \n  Commented Nov 2, 2025 at 19:12\n* \n* @nseaprotector I wonder why they even add that if its not working properly. Does that mean I have to rewrite the entire screen recording code from scratch using the previous screen recording libraries by apple? Do you have any docs to guide here?\n  \n  Zaid\n  \n  – Zaid\n  \n  2025-11-02 20:36:54 +00:00\n  \n  Commented Nov 2, 2025 at 20:36\n* @Zaid Can you share (upload) the `recording-display-0.mp4` file for our checking? The problem should be obvious from the bytes of the MP4.\n  \n  VC.One\n  \n  – VC.One\n  \n  2025-11-03 08:56:21 +00:00\n  \n  Commented Nov 3, 2025 at 8:56\n\n...\n\n### Post as a guest\n\nName\n\nEmail\n\nRequired, but never shown\n\nPost Your Answer Discard\n\nBy clicking “Post Your Answer”, you agree to our [terms of service](https://stackoverflow.com/legal/terms-of-service/public) and acknowledge you have read our [privacy policy](https://stackoverflow.com/legal/privacy-policy) .\n\nStart asking to get answers\n\nFind the answer to your question by asking.\n\nAsk question\n\nExplore related questions\n\n* swift\n* macos\n* audio\n* microphone\n* screencapturekit\n\nSee similar questions with these tags.\n\nlang-swift"
      ]
    },
    {
      "url": "https://deepwiki.com/simonmesmith/agent-skills/2.2-swift-helper-audio-capture-(screencapturekit)",
      "title": "Swift Helper — Audio Capture (ScreenCaptureKit)",
      "publish_date": "2026-05-28",
      "excerpts": [
        "Loading..."
      ]
    },
    {
      "url": "https://stackoverflow.com/questions/79384952/capturing-microphone-input-on-macos-using-screencapturekit",
      "title": "swift - Capturing microphone input on macOS using ScreenCaptureKit - Stack Overflow",
      "publish_date": "2025-01-24",
      "excerpts": [
        "The 2026 Annual Developer Survey is live— [take the Survey today!](https://take.survey.stackoverflow.co/jfe/form/SV_4GHunpL3IfJ3rRc?utm_medium=referral&utm_source=stackoverflow-community&utm_campaign=dev-survey-2026&utm_content=announcement-banner)\n\n1. 1. Home\n    2. Questions\n    3. [AI Assist](https://stackoverflow.com/ai-assist)\n    4. Tags\n    5. \n    6. [Stack Overflow for Agents](http://agents.stackoverflow.com)\n    7. \n    8. Challenges\n    9. [Chat](https://chat.stackoverflow.com/?tab=explore)\n    10. [Articles](https://stackoverflow.blog/contributed?utm_medium=referral&utm_source=stackoverflow-community&utm_campaign=so-blog&utm_content=experiment-articles)\n    11. Users\n    12. \n    13. [Companies](https://stackoverflow.com/jobs/companies?so_medium=stackoverflow&so_source=SiteNav)\n    14. Collectives\n    15. Communities for your favorite technologies. Explore all Collectives\n2. Stack Internal\n   \n   Stack Overflow for Teams is now called **Stack Internal** .\n\n...\n\nSearching SO brought only this question: [Synchronizing ScreenCaptureKit with microphone audio](https://stackoverflow.com/questions/78235302/synchronizing-screencapturekit-with-microphone-audio) but seems like no-one still replied for months.\n4. Googling for anything even closely related brings no luck as well.\n\nBoth `Info.plist` privacy settings and Resource Access ( `Audio Input` ) have been set.\n\nIf anyone has suggestions or perhaps short sample code, it would be greatly appreciated.\n\n* swift\n* macos\n* audio\n* microphone\n* screencapturekit\n\nShare\n\nImprove this question\n\nFollow\n\nedited Jan 27, 2025 at 21:27\n\nasked Jan 24, 2025 at 16:16\n\nVëx's user avatar\n\nVëx\n\n1,408 1 1 gold badge 13 13 silver badges 22 22 bronze badges\n\n7\n\n* According to Apple's docs, MacOS has a number of frameworks to work with audio, such as [AVFoundation](https://developer.apple.com/documentation/avfoundation/) and [AVAudioEngine](https://developer.apple.\n\n...\n\n**Reminder:** Answers generated by AI tools are not allowed due to Stack Overflow's artificial intelligence policy\n\nThanks for contributing an answer to Stack Overflow!\n\n* Please be sure to _answer the question_ . Provide details and share your research!\n\nBut _avoid_ …\n\n* Asking for help, clarification, or responding to other answers.\n* Making statements based on opinion; back them up with references or personal experience.\n\nTo learn more, see our tips on writing great answers .\n\nDraft saved\n\nDraft discarded\n\n### Sign up or \n\nSign up using Google\n\nSign up using Email and Password\n\nSubmit\n\n### Post as a guest\n\nName\n\nEmail\n\nRequired, but never shown\n\nPost Your Answer Discard\n\nBy clicking “Post Your Answer”, you agree to our [terms of service](https://stackoverflow.com/legal/terms-of-service/public) and acknowledge you have read our [privacy policy](https://stackoverflow.com/legal/privacy-policy) .\n\nStart asking to get answers\n\nFind the answer to your question by asking.\n\nAsk question\nExplore related questions\n\n* swift\n* macos\n* audio\n* microphone\n* screencapturekit\n\nSee similar questions with these tags.\n\nlang-swift"
      ]
    },
    {
      "url": "https://stackoverflow.com/questions/78235302/synchronizing-screencapturekit-with-microphone-audio",
      "title": "swift - Synchronizing ScreenCaptureKit with microphone audio ...",
      "publish_date": "2024-03-28",
      "excerpts": [
        "utm_medium=referral&utm_source=stackoverflow-community&utm_campaign=side-bar&utm_content=explore-teams)\n3. Stack Internal\n4. Bring the best of human thought and AI automation together at your work. [Learn more](https://stackoverflow.co/internal/?utm_medium=referral&utm_source=stackoverflow-community&utm_campaign=side-bar&utm_content=explore-teams-compact)\n\n##### Collectives™ on Stack Overflow\n\nFind centralized, trusted content and collaborate around the technologies you use most.\n\nLearn more about Collectives\n\n**Stack Internal**\n\nKnowledge at work\n\nBring the best of human thought and AI automation together at your work.\n\n[Explore Stack Internal](https://stackoverflow.co/internal/?utm_medium=referral&utm_source=stackoverflow-community&utm_campaign=side-bar&utm_content=explore-teams-compact-popover)\n\n# Synchronizing ScreenCaptureKit with microphone audio\n\nAsk Question\n\nAsked 2 years, 1 month ago\n\nModified [1 year, 3 months ago](https://stackoverflow.\ncom/questions/78235302/synchronizing-screencapturekit-with-microphone-audio?lastactivity \"2025-01-27 09:32:46Z\")\n\nViewed 830 times\n\n4\n\nI'm capturing system audio using ScreenCaptureKit, and combining it with microphone audio to produce a single stream.\n\nHowever, I'm having trouble synchronizing the two streams.\n\nHere's what my AVAudioEngine graph looks like:\n\n```\n                                                           muted\ninputNode --> converterNode --> mixerNode --> mainMixerNode --> outputNode\n                                  |   |\nplayerNode ---------------------> +   +--> tap --> file\n```\n\nWhen ScreenCaptureKit outputs an audio buffer, I convert it to `AVAudioPCMBuffer` and feed that to my `AVPlayerNode` :\n\n```\n// SCStreamOutput\nfunc stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {\n    let pcmBuffer = convertToPCM(sampleBuffer)\n    playerNode.scheduleBuffer(pcmBuffer, completionCallbackType: .\ndataConsumed, completionHandler: nil)\n}\n```\n\nThe problem is that the two streams easily get out of sync, because each requires a processing step before they arrive at `mixerNode` (converting buffer format for system audio, and converting sample rate for microphone audio). The delay is noticeable due to the microphone picking up system audio, leading to an echo effect.\n\nHow can I synchronize the two audio streams? ScreenCaptureKit has its own `synchronizationClock` , but it's not clear how this might interface with AVAudioEngine.\n\n* swift\n* macos\n* audio\n* avaudioengine\n* screencapturekit\n\nShare\n\nImprove this question\n\nFollow\n\nasked Mar 28, 2024 at 0:43\n\nHundley's user avatar\n\nHundley\n\n3,617 5 5 gold badges 30 30 silver badges 48 48 bronze badges\n\n1\n\n* Hi have you found a solution to sync the two audio streams?\n  \n  espc\n  \n  – espc\n  \n  2024-10-31 18:15:13 +00:00\n  \n  Commented Oct 31, 2024 at 18:15\n\nAdd a comment | \n\n## 1 Answer\n\nSorted by: [Reset to default](https://stackoverflow.\n\n...\n\nYou could instead try the new macOS 15 microphone addition to `ScreenCaptureKit` which gives you 1, 2 (not 3, formats differ) and you could mix the streams yourself (it's just addition) or use an offline `AVAudioEngine` . Update: `ScreenCaptureKit` on macOS 10.15/Sequoia does **NOT** echo cancel the microphone stream.\n\nOr you could discard all this and use the `CATap` API (macOS 13 and up), which can capture both mic and system audio in such a way that the formats match, the streams are synchronized and even drift corrected, leaving you only to mix down and echo cancel. It's the only API that even considers drift correction (desynchronization due to different capture devices using different clocks).\n\nNotes:"
      ]
    },
    {
      "url": "https://github.com/moonshine-ai/MoonshineNoteTaker",
      "title": "GitHub - moonshine-ai/MoonshineNoteTaker: Open source audio recorder and transcriber for MacOS · GitHub",
      "publish_date": null,
      "excerpts": [
        "* **Edit while transcribing** — Fix mistakes and add formatting as text streams in.\n* **Playback with sync** — Play back recorded audio and see the corresponding text highlighted as it plays.\n* **Export** — Save your work as:\n  \n    + A **Moonshine Note Taker document** (transcript + audio)\n    + **Formatted text** (RTF) for use in other apps\n    + **Audio** (WAV)\n    + **Captions** (SRT) with timings\n\nEverything runs **on your Mac** ; no data is sent to the internet.\n\n* * *\n\n## Getting started\n\n1. **System audio (optional)** — To transcribe Zoom, browser audio, or other system sound, grant **Screen Recording** (or system audio) permission when prompted. You may need to **quit and reopen** the app for it to take effect.\n2. **Microphone (for voice)** — When you tap **Record** , allow microphone access if asked.\n3. **Record** — Start recording; speech is transcribed in real time. You can keep editing and formatting while it runs.\n4.\n**Playback** — Use playback to hear the recording and see the text sync.\n5. **Save / export** — Use **File → Save** for the full document, or the export options for text, audio, or SRT.\n\n* * *\n\n## Requirements\n\n* **macOS 15.0** or later\n* Apple Silicon or Intel Mac\n\n* * *\n\n## For developers\n\n### Build from source\n\n1. Clone the repo and open `MoonshineNoteTaker.xcodeproj` in Xcode.\n2. The app depends on the **Moonshine** Swift package (Moonshine Voice) for on-device transcription. Resolve package dependencies in Xcode.\n3. The app expects a **models** directory (e.g. `MoonshineNoteTaker/models` ) with the Moonshine Voice model assets. Ensure the model files are present and referenced correctly for your setup.\n4. Build and run the **Moonshine Note Taker** target.\n\n### Tech overview\n\n* **Transcription:** [Moonshine Voice](https://github.com/moonshineai/moonshine-voice) (on-device, no cloud).\n* **System audio capture:** ScreenCaptureKit (macOS).\n* **App:** Swift/SwiftUI, document-based ( `.transcript` bundle), with export to RTF, WAV, and SRT.\n\n### License\n\nThis project is licensed under the MIT License. See [LICENSE.txt](https://github.com/moonshine-ai/MoonshineNoteTaker/blob/main/LICENSE.txt) for the full text.\n\n* * *"
      ]
    },
    {
      "url": "https://creavit.studio/blog/screencapturekit-audio-recording-mac-guide",
      "title": "How to Record System Audio on Mac with ScreenCaptureKit (Easy ...",
      "publish_date": "2026-03-06",
      "excerpts": [
        "Creavit Studio\n\nProduct\n\nSolutions\n\nPricing Find License\n\nTry for free\n\nGet License\n\n← Blog\n\nTutorials · Mar 6, 2026 · 7 min read\n\n# How to Record System Audio on Mac with ScreenCaptureKit (Easy Guide)\n\nLearn how ScreenCaptureKit handles audio capture, microphone input, and system sound recording on macOS. Practical guide for developers and power users.\n\n## What Is ScreenCaptureKit?\n\nScreenCaptureKit is Apple's native framework for capturing screen content on macOS (introduced in macOS 12.3). It replaced the older CGWindowList and AVCaptureScreenInput APIs with a modern, high-performance alternative.\n\nFor developers building screen recording apps — or power users curious about how Mac screen recorders work — ScreenCaptureKit is the foundation that makes features like system audio capture, per-app audio, and low-latency recording possible.\nWatch how a Mac recorder built on ScreenCaptureKit turns screen capture, camera layout, zoom effects, and system audio into a polished recording workflow.\n\n* * *\n\n## ScreenCaptureKit Audio Capture\n\nOne of the biggest improvements ScreenCaptureKit brought is **native system audio capture** . Before ScreenCaptureKit, recording system audio on macOS required third-party audio drivers (like Soundflower or BlackHole) or kernel extensions.\n\n### How Audio Capture Works\n\nScreenCaptureKit provides audio capture through **SCStreamConfiguration** :\n\n* **System audio** — Captures all audio output from macOS, or audio from specific apps\n* **Microphone audio** — Captures input from any connected microphone\n* **Both simultaneously** — Record system audio and microphone at the same time\n\n### Key Audio Configuration Options\n\n* **capturesAudio** — Enable or disable audio capture\n* **excludesCurrentProcessAudio** — Prevent the recording app's own audio from being captured\n* **sampleRate** — Set audio sample rate (default 48000 Hz)\n* **channelCount** — Mono or stereo capture\n\n### Per-App Audio Filtering\n\nScreenCaptureKit can capture audio from specific applications only. This means you can:\n\n* Record a video call without capturing your music player\n* Capture a game's audio without system notifications\n* Record a browser tab's audio while excluding everything else\n\nThis is done by specifying an **SCContentFilter** with the desired windows or applications.\n\n* * *\n\n## ScreenCaptureKit Microphone Recording\n\nMicrophone capture in ScreenCaptureKit works alongside screen and system audio capture:\n\n* Select any available audio input device\n* Mix microphone audio with system audio in a single stream\n* Apply separate volume controls to mic and system audio\n* Record at configurable sample rates and channel counts\n\n### Common Microphone Setup\n\nFor tutorial and demo recording, the typical configuration is:\n\n1. Enable system audio capture (to record app sounds)\n2."
      ]
    },
    {
      "url": "https://github.com/GlennWong/SwiftCapture",
      "title": "GitHub - GlennWong/SwiftCapture: A professional screen ...",
      "publish_date": "2025-08-12",
      "excerpts": [
        "# GlennWong/SwiftCapture\n\n- Page: GitHub repository\n- URL: https://github.com/GlennWong/SwiftCapture\n- Description: A professional screen recording tool for macOS built with ScreenCaptureKit, featuring comprehensive CLI interface, multi-screen support, application window recording, and advanced audio/video contr...\n- Stars: 8\n- Forks: 1\n- Default branch: main\n- Created: 2025-08-12T13:10:23.000Z\n- Commits: 60\n\n## Top-level files\n\n- .github/workflows/\n- Sources/SwiftCapture/\n- Tests/SwiftCaptureTests/\n- scripts/\n- .gitignore\n- CHANGELOG.md\n- Package.resolved\n- Package.swift\n- README_zh.md\n- SPECS.md\n- readme.md\n- release-config.json\n\n## readme.md\n\n# SwiftCapture\n\n[English](https://github.com/GlennWong/SwiftCapture/blob/main/README.md) | [中文](https://github.com/GlennWong/SwiftCapture/blob/main/README_zh.md)\nA professional screen recording tool for macOS built with ScreenCaptureKit, featuring comprehensive CLI interface, multi-screen support, application window recording, and advanced audio/video controls.\n\n## Features\n\n* **Professional CLI Interface** : Built with Swift ArgumentParser for robust command-line experience\n* **Multi-Screen Support** : Record from any connected display with automatic detection\n* **Application Window Recording** : Record specific applications instead of entire screens\n* **Advanced Audio Control** : System audio recording with optional microphone input\n* **Flexible Area Selection** : Record full screen, custom areas, or centered regions\n* **Quality Controls** : Configurable frame rates (15/30/60 fps) and quality presets\n* **High-Quality Output** : Professional MOV format with optimized encoding\n* **Preset Management** : Save and reuse recording configurations\n* **Countdown Timer** : Optional countdown before recording starts\n* **Cursor Control** : Show or hide cursor in recordings\n* **Comprehensive Help** : Detailed usage examples and troubleshooting guide\n\n## System Requirements\n\n* **macOS 12.3 or later** (required for ScreenCaptureKit)\n* **Xcode 14.3 or later** (for building from source)\n* **Screen Recording permission** in System Preferences\n* **Microphone permission** (only when using `--enable-microphone` )\n\n## Installation\n\n### Brew\n\n```shell\nbrew tap GlennWong/swiftcapture\nbrew install swiftcapture\n```\n\n### From Source\n\n```shell\n# Clone the repository\ngit clone https://github.com/GlennWong/SwiftCapture.git\ncd SwiftCapture\n\n# Build release version\nswift build -c release\n\n# The executable will be available at:\n.build/release/SwiftCapture\n```\n\n## Quick Start\n\n```shell\n# Continuous recording (default) - press Ctrl+C to stop\nscap\n\n# Continuous recording with custom output\nscap --output ~/Desktop/demo.mov\n\n# Timed recording for 30 seconds\nscap --duration 30000\n\n# Record with microphone audio (continuous)"
      ]
    },
    {
      "url": "https://github.com/acmerfight/audiomixer",
      "title": "GitHub - acmerfight/audiomixer: Record system audio ...",
      "publish_date": null,
      "excerpts": [
        "AudioMixer A macOS command-line tool that records system audio and microphone input simultaneously into a single WAV file. Built with Apple's ScreenCaptureKit (macOS 15+). No virtual audio drivers, no third-party dependencies."
      ]
    },
    {
      "url": "https://developer.apple.com/documentation/screencapturekit",
      "title": "ScreenCaptureKit | Apple Developer Documentation",
      "publish_date": null,
      "excerpts": [
        "Skip Navigation\n\nDocumentation\n\nOpen Menu\n\n* Swift Language: Swift Objective-C\n  \n  Language:\n  \n    + Swift\n    + Objective-C\n\nAll Technologies\n\n## ScreenCaptureKit\n\nEssentials\n\nScreenCaptureKit updates\n\nPersistent Content Capture\n\nCapturing screen content in macOS\n\nShareable content\n\nSCShareableContent\n\nSCShareableContentInfo\n\nSCShareableContentStyle\n\nSCDisplay\n\nSCRunningApplication\n\nSCWindow\n\nContent capture\n\nSCStream\n\nSCStreamConfiguration\n\nSCContentFilter\n\nSCStreamDelegate\n\nSCScreenshotManager\n\nSCScreenshotConfiguration\n\nSCScreenshotOutput\n\nSCVideoEffectOutput Beta\n\nOutput processing\n\nSCStreamOutput\n\nSCStreamOutputType\n\nSCStreamFrameInfo\n\nSCFrameStatus\n\nSCClipBufferingOutput Beta\n\nSystem content-sharing picker\n\nSCContentSharingPicker\n\nSCContentSharingPickerConfiguration\n\nSCContentSharingPickerMode\n\nSCContentSharingPickerObserver\n\nStream errors (Swift)\n\nlet SCStreamErrorDomain: String\n\nSCStreamError\n\nClasses\n\nSCRecordingEditor Beta\n\nProtocols\n\nSCClipBufferingOutputDelegate Beta\nSCRecordingEditorDelegate Beta\n\n39 items were found. Tab back to navigate through them.\n\n/\n\nNavigator is ready\n\nFramework\n\n# ScreenCaptureKit\n\nStream screen content and audio to your app with fine-grained control over what you capture.\n\niOS 27.0+ Beta iPadOS 27.0+ Beta Mac Catalyst 18.2+ macOS 12.3+ tvOS 27.0+ Beta visionOS 27.0+ Beta\n\n## Overview\n\nUse ScreenCaptureKit to capture high-performance video and audio across iOS, iPadOS, macOS, tvOS, and visionOS. The framework gives you fine-grained control to select and stream only the content you want to capture, delivering media to your app as `CMSample Buffer` objects with the associated metadata.\n\nImportant\n\nScreenCaptureKit replaces ReplayKit for screen streaming and mirroring. A broadcast extension is no longer necessary.\n\nUse `SCContent Sharing Picker` , the system screen-sharing control, as the recommended approach for letting people select content sources and manage active streams, rather than building your own selection UI.\nTo capture content while your app is in the background, configure the appropriate Configuring background execution modes in the Signing & Capabilities pane in Xcode.\n\nRequest screen recording permission from the person before capturing content. In the Info pane of the Xcode target editor, add a `NSScreen Capture Usage Description` key with a description of why your app requires screen recording access.\n\nNote\n\nFor related WWDC sessions, see [Meet ScreenCaptureKit](https://developer.apple.com/wwdc22/10156) (WWDC22 Session 10156), [Take ScreenCaptureKit to the next level](https://developer.apple.com/wwdc22/10155) (WWDC22 Session 10155), and [What’s new in ScreenCaptureKit](https://developer.apple.com/videos/play/wwdc2023/10136/) (WWDC23 Session 10136).\n\n## Topics\n\n### Essentials\n\nScreen Capture Kit updates\n\nLearn about important changes to ScreenCaptureKit.\n\n`Persistent Content Capture`"
      ]
    }
  ],
  "warnings": null,
  "usage": [
    {
      "name": "sku_search",
      "count": 1
    }
  ],
  "session_id": "ses_09bf56a63ffe6WwLYNXEvmuaZl"
}
```

---

## Assistant (Build · Big Pickle · 8.3s)

_Thinking:_

Excellent findings. Let me now look at the CoreML-converted Whisper model that already exists, and the speech-swift project which has a working CoreML Whisper implementation.

Key discoveries:
1. `aufklarer/Whisper-Large-v3-Turbo-CoreML` - A pre-converted CoreML bundle exists on HuggingFace!
2. `soniqo/speech-swift` - A Swift package that already has WhisperASR as a product, using CoreML ANE
3. `vade/OpenAI-Whisper-CoreML` - Another CoreML port4. ScreenCaptureKit supports simultaneous system audio and microphone capture, though synchronization needs careful handling

The pre-converted CoreML bundle on HuggingFace splits the model into four separate pieces: mel spectrogram, audio encoder, decoder context prefill, and KV-cached text decoder. Now I'm thinking through the core architectural decisions—whether to leverage the existing speech-swift package or build from scratch, how to handle audio capture with ScreenCaptureKit, and how to structure the paste mechanism.

The key insight is that `aufklarer/Whisper-Large-v3-Turbo-CoreML` already has a working CoreML conversion ready to use. This could be a direct dependency or bundled with the app. Let me dig deeper into the speech-swift project to understand how it's structured.

Found something important. Let me dig into it.

**Tool: webfetch**

**Input:**
```json
{
  "format": "text",
  "url": "https://huggingface.co/aufklarer/Whisper-Large-v3-Turbo-CoreML"
}
```

**Output:**
```
aufklarer/Whisper-Large-v3-Turbo-CoreML · Hugging Face

		

		

		
		 
	
	
		    Hugging Face        Models  Datasets  Spaces  Buckets new Docs  Enterprise  Pricing     Website  Tasks  HuggingChat  Collections  Languages  Organizations  Community  Blog  Posts  Daily Papers  Hardware  Learn  Discord  Forum  GitHub  Solutions  Team & Enterprise  Hugging Face PRO  Enterprise Support  Inference Providers  Inference Endpoints  Storage Buckets     Log In Sign Up              aufklarer  / Whisper-Large-v3-Turbo-CoreML       like  0      Automatic Speech Recognition    Core ML    multilingual    whisper    asr    speech    neural-engine    soniqo   License: mit         Model card   Files Files and versions   xet  Community                  Copy to bucket new                    Whisper Large v3 Turbo - CoreML Model Files Reference Benchmarks Usage Links    
	
		
	
	
		Whisper Large v3 Turbo - CoreML
	

Compiled CoreML bundle for OpenAI Whisper large-v3-turbo, staged for Apple-platform ASR in speech-swift.

Part of the soniqo.audio speech toolkit. This is the Apple CoreML bundle used by the native WhisperASR runtime in speech-swift. Browse Apple bundles in the CoreML Speech Models collection.


	
		
	
	
		Model
	


	
		




		
Base model
openai/whisper-large-v3-turbo


Bundle source
argmaxinc CoreML bundle


Format
Compiled CoreML .mlmodelc


Runtime
speech-swift WhisperASR / CoreML


Total artifact size
1562.56 MiB


Conversion
Precompiled upstream CoreML bundle, staged for soniqo runtimes


	

The bundle splits Whisper into CoreML programs for mel extraction, audio encoding, context prefill, and token decoding. speech-swift loads these programs through its native WhisperASR runtime for Apple Silicon and iOS/macOS deployment.

	
		
	
	
		Files
	


	
		
File
Size
Description


		
AudioEncoder.mlmodelc/analytics/coremldata.bin
0.0 MB
Audio encoder CoreML program


AudioEncoder.mlmodelc/coremldata.bin
0.0 MB
Audio encoder CoreML program


AudioEncoder.mlmodelc/metadata.json
0.0 MB
Audio encoder CoreML program


AudioEncoder.mlmodelc/model.mil
6.84 MB
Audio encoder CoreML program


AudioEncoder.mlmodelc/model.mlmodel
0.42 MB
Audio encoder CoreML program


AudioEncoder.mlmodelc/weights/weight.bin
1214.96 MB
Audio encoder CoreML program


MelSpectrogram.mlmodelc/analytics/coremldata.bin
0.0 MB
Mel spectrogram CoreML program


MelSpectrogram.mlmodelc/coremldata.bin
0.0 MB
Mel spectrogram CoreML program


MelSpectrogram.mlmodelc/metadata.json
0.0 MB
Mel spectrogram CoreML program


MelSpectrogram.mlmodelc/model.mil
0.01 MB
Mel spectrogram CoreML program


MelSpectrogram.mlmodelc/weights/weight.bin
0.36 MB
Mel spectrogram CoreML program


TextDecoder.mlmodelc/analytics/coremldata.bin
0.0 MB
Token decoder CoreML program


TextDecoder.mlmodelc/coremldata.bin
0.0 MB
Token decoder CoreML program


TextDecoder.mlmodelc/metadata.json
0.0 MB
Token decoder CoreML program


TextDecoder.mlmodelc/model.mil
0.13 MB
Token decoder CoreML program


TextDecoder.mlmodelc/model.mlmodel
0.11 MB
Token decoder CoreML program


TextDecoder.mlmodelc/weights/weight.bin
328.0 MB
Token decoder CoreML program


TextDecoderContextPrefill.mlmodelc/analytics/coremldata.bin
0.0 MB
Token decoder CoreML program


TextDecoderContextPrefill.mlmodelc/coremldata.bin
0.0 MB
Token decoder CoreML program


TextDecoderContextPrefill.mlmodelc/metadata.json
0.0 MB
Token decoder CoreML program


TextDecoderContextPrefill.mlmodelc/model.mil
0.0 MB
Token decoder CoreML program


TextDecoderContextPrefill.mlmodelc/weights/weight.bin
11.72 MB
Token decoder CoreML program


config.json
0.0 MB
Whisper / generation configuration


generation_config.json
0.0 MB
Whisper / generation configuration


	


	
		
	
	
		Reference Benchmarks
	

M5 Pro, speech-swift native WhisperASR benchmark, full local FLEURS test split:

	
		
Dataset
WER
CER
Mean RTF
Overall throughput


		
fleurs-en_us
5.55%
2.72%
0.065
16.7x


fleurs-fr_fr
6.28%
2.70%
0.075
14.0x


fleurs-ar_eg
16.60%
5.63%
0.082
12.8x


	


	
		
	
	
		Usage
	

Used by speech-swift through the native WhisperASR runtime:
speech transcribe /path/to/audio.wav \
  --engine whisper \
  --model aufklarer/Whisper-Large-v3-Turbo-CoreML \
  --language en


	
		
	
	
		Links
	


Website: soniqo.audio
Docs: soniqo.audio/getting-started
Speech Swift: github.com/soniqo/speech-swift
Speech Core: github.com/soniqo/speech-core
Blog: soniqo.audio/blog

  Downloads last month 438  
			
				
					
						
						
					
				
				
			
			
		
			
		      Inference Providers NEW    Automatic Speech Recognition     This model isn't deployed by any Inference Provider. 🙋  Ask for provider support     Model tree for aufklarer/Whisper-Large-v3-Turbo-CoreML  Base model  openai/whisper-large-v3  Finetuned   openai/whisper-large-v3-turbo  Quantized (219)  this model      Collection including aufklarer/Whisper-Large-v3-Turbo-CoreML CoreML Speech Models  Collection Speech AI models for Apple Neural Engine via CoreML. iOS/macOS ready. ASR, TTS, VAD, diarization. • 36 items • Updated about 14 hours ago •  4       System theme     Company TOS Privacy About Careers  Website Models Datasets Spaces Pricing Docs
```

**Tool: webfetch**

**Input:**
```json
{
  "format": "markdown",
  "url": "https://github.com/soniqo/speech-swift"
}
```

**Output:**
```
                        GitHub - soniqo/speech-swift: AI speech toolkit for Apple Silicon — ASR, TTS, speech-to-speech, VAD, and diarization powered by MLX and CoreML · GitHub                                             

[Skip to content](#start-of-content)   

## Navigation Menu

Toggle navigation

[](/)

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fsoniqo%2Fspeech-swift)

Appearance settings

  

-   Platform
    
    -   AI CODE CREATION
        
        -   [
            
            GitHub CopilotWrite better code with AI
            
            ](https://github.com/features/copilot)
        -   [
            
            GitHub Copilot appDirect agents from issue to merge
            
            ](https://github.com/features/ai/github-app)
        -   [
            
            MCP RegistryNewIntegrate external tools
            
            ](https://github.com/mcp)
        
    -   DEVELOPER WORKFLOWS
        
        -   [
            
            ActionsAutomate any workflow
            
            ](https://github.com/features/actions)
        -   [
            
            CodespacesInstant dev environments
            
            ](https://github.com/features/codespaces)
        -   [
            
            IssuesPlan and track work
            
            ](https://github.com/features/issues)
        -   [
            
            Code ReviewManage code changes
            
            ](https://github.com/features/code-review)
        
    -   APPLICATION SECURITY
        
        -   [
            
            GitHub Advanced SecurityFind and fix vulnerabilities
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Code securitySecure your code as you build
            
            ](https://github.com/security/advanced-security/code-security)
        -   [
            
            Secret protectionStop leaks before they start
            
            ](https://github.com/security/advanced-security/secret-protection)
        
    -   EXPLORE
        
        -   [Why GitHub](https://github.com/why-github)
        -   [Documentation](https://docs.github.com)
        -   [Blog](https://github.blog)
        -   [Changelog](https://github.blog/changelog)
        -   [Marketplace](https://github.com/marketplace)
        
    
    [View all features](https://github.com/features)
    
-   Solutions
    
    -   BY COMPANY SIZE
        
        -   [Enterprises](https://github.com/enterprise)
        -   [Small and medium teams](https://github.com/team)
        -   [Startups](https://github.com/enterprise/startups)
        -   [Nonprofits](https://github.com/solutions/industry/nonprofits)
        
    -   BY USE CASE
        
        -   [App Modernization](https://github.com/solutions/use-case/app-modernization)
        -   [DevSecOps](https://github.com/solutions/use-case/devsecops)
        -   [DevOps](https://github.com/solutions/use-case/devops)
        -   [CI/CD](https://github.com/solutions/use-case/ci-cd)
        -   [View all use cases](https://github.com/solutions/use-case)
        
    -   BY INDUSTRY
        
        -   [Healthcare](https://github.com/solutions/industry/healthcare)
        -   [Financial services](https://github.com/solutions/industry/financial-services)
        -   [Manufacturing](https://github.com/solutions/industry/manufacturing)
        -   [Government](https://github.com/solutions/industry/government)
        -   [View all industries](https://github.com/solutions/industry)
        
    
    [View all solutions](https://github.com/solutions)
    
-   Resources
    
    -   EXPLORE BY TOPIC
        
        -   [AI](https://github.com/resources/articles?topic=ai)
        -   [Software Development](https://github.com/resources/articles?topic=software-development)
        -   [DevOps](https://github.com/resources/articles?topic=devops)
        -   [Security](https://github.com/resources/articles?topic=security)
        -   [View all topics](https://github.com/resources/articles)
        
    -   EXPLORE BY TYPE
        
        -   [Customer stories](https://github.com/customer-stories)
        -   [Events & webinars](https://github.com/resources/events)
        -   [Ebooks & reports](https://github.com/resources/whitepapers)
        -   [Business insights](https://github.com/solutions/executive-insights)
        -   [GitHub Skills](https://skills.github.com)
        
    -   SUPPORT & SERVICES
        
        -   [Documentation](https://docs.github.com)
        -   [Customer support](https://support.github.com)
        -   [Community forum](https://github.com/orgs/community/discussions)
        -   [Trust center](https://github.com/trust-center)
        -   [Partners](https://github.com/partners)
        
    
    [View all resources](https://github.com/resources)
    
-   Open Source
    
    -   COMMUNITY
        
        -   [
            
            GitHub SponsorsFund open source developers
            
            ](https://github.com/open-source/sponsors)
        
    -   PROGRAMS
        
        -   [Security Lab](https://securitylab.github.com)
        -   [Maintainer Community](https://maintainers.github.com)
        -   [Accelerator](https://github.com/open-source/accelerator)
        -   [GitHub Stars](https://stars.github.com)
        -   [Archive Program](https://archiveprogram.github.com)
        
    -   REPOSITORIES
        
        -   [Topics](https://github.com/topics)
        -   [Trending](https://github.com/trending)
        -   [Collections](https://github.com/collections)
        
    
-   Enterprise
    
    -   ENTERPRISE SOLUTIONS
        
        -   [
            
            Enterprise platformAI-powered developer platform
            
            ](https://github.com/enterprise)
        
    -   AVAILABLE ADD-ONS
        
        -   [
            
            GitHub Advanced SecurityEnterprise-grade security features
            
            ](https://github.com/security/advanced-security)
        -   [
            
            Copilot for BusinessEnterprise-grade AI features
            
            ](https://github.com/features/copilot/copilot-business)
        -   [
            
            Premium SupportEnterprise-grade 24/7 support
            
            ](https://github.com/enterprise/premium-support)
        
    
-   [Pricing](https://github.com/pricing)

Search or jump to...

# Search code, repositories, users, issues, pull requests...

Search

Clear

[Search syntax tips](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax)

# Provide feedback

We read every piece of feedback, and take your input very seriously.

 Include my email address so I can be contacted

Cancel Submit feedback

# Saved searches

## Use saved searches to filter your results more quickly

Name  

Query 

To see all available qualifiers, see our [documentation](https://docs.github.com/search-github/github-code-search/understanding-github-code-search-syntax).

Cancel Create saved search

[Sign in](/login?return_to=https%3A%2F%2Fgithub.com%2Fsoniqo%2Fspeech-swift)

[Sign up](/signup?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F%3Cuser-name%3E%2F%3Crepo-name%3E&source=header-repo&source_repo=soniqo%2Fspeech-swift)

Appearance settings

Resetting focus

You signed in with another tab or window. Reload to refresh your session. You signed out in another tab or window. Reload to refresh your session. You switched accounts on another tab or window. Reload to refresh your session. Dismiss alert

### Uh oh!

There was an error while loading. Please reload this page.

[soniqo](/soniqo) / **[speech-swift](/soniqo/speech-swift)** Public

-   ### Uh oh!
    
    There was an error while loading. Please reload this page.
    
-   [Notifications](/login?return_to=%2Fsoniqo%2Fspeech-swift) You must be signed in to change notification settings
-   [Fork 127](/login?return_to=%2Fsoniqo%2Fspeech-swift)
-   [Star 1k](/login?return_to=%2Fsoniqo%2Fspeech-swift)
    

-   [Code](/soniqo/speech-swift)
-   [Issues 3](/soniqo/speech-swift/issues)
-   [Pull requests 0](/soniqo/speech-swift/pulls)
-   [Discussions](/soniqo/speech-swift/discussions)
-   [Actions](/soniqo/speech-swift/actions)
-   [Projects](/soniqo/speech-swift/projects)
-   [Security and quality 0](/soniqo/speech-swift/security)
-   [Insights](/soniqo/speech-swift/pulse)

Additional navigation options

-   [Code](/soniqo/speech-swift)
-   [Issues](/soniqo/speech-swift/issues)
-   [Pull requests](/soniqo/speech-swift/pulls)
-   [Discussions](/soniqo/speech-swift/discussions)
-   [Actions](/soniqo/speech-swift/actions)
-   [Projects](/soniqo/speech-swift/projects)
-   [Security and quality](/soniqo/speech-swift/security)
-   [Insights](/soniqo/speech-swift/pulse)

 [](/soniqo/speech-swift)

# soniqo/speech-swift

 main

[Branches](/soniqo/speech-swift/branches)[Tags](/soniqo/speech-swift/tags)

[](/soniqo/speech-swift/branches)[](/soniqo/speech-swift/tags)

Go to file

Code

Open more actions menu

## Folders and files

Name

Name

Last commit message

Last commit date

## Latest commit

## History

[783 Commits](/soniqo/speech-swift/commits/main/)

[](/soniqo/speech-swift/commits/main/)783 Commits

[.claude/skills](/soniqo/speech-swift/tree/main/.claude/skills "This path skips through empty directories")

[.claude/skills](/soniqo/speech-swift/tree/main/.claude/skills "This path skips through empty directories")

[.codex/skills](/soniqo/speech-swift/tree/main/.codex/skills "This path skips through empty directories")

[.codex/skills](/soniqo/speech-swift/tree/main/.codex/skills "This path skips through empty directories")

[.github](/soniqo/speech-swift/tree/main/.github ".github")

[.github](/soniqo/speech-swift/tree/main/.github ".github")

[Examples](/soniqo/speech-swift/tree/main/Examples "Examples")

[Examples](/soniqo/speech-swift/tree/main/Examples "Examples")

[Sources](/soniqo/speech-swift/tree/main/Sources "Sources")

[Sources](/soniqo/speech-swift/tree/main/Sources "Sources")

[Tests](/soniqo/speech-swift/tree/main/Tests "Tests")

[Tests](/soniqo/speech-swift/tree/main/Tests "Tests")

[docs](/soniqo/speech-swift/tree/main/docs "docs")

[docs](/soniqo/speech-swift/tree/main/docs "docs")

[scripts](/soniqo/speech-swift/tree/main/scripts "scripts")

[scripts](/soniqo/speech-swift/tree/main/scripts "scripts")

[.gitignore](/soniqo/speech-swift/blob/main/.gitignore ".gitignore")

[.gitignore](/soniqo/speech-swift/blob/main/.gitignore ".gitignore")

[.spi.yml](/soniqo/speech-swift/blob/main/.spi.yml ".spi.yml")

[.spi.yml](/soniqo/speech-swift/blob/main/.spi.yml ".spi.yml")

[AGENTS.md](/soniqo/speech-swift/blob/main/AGENTS.md "AGENTS.md")

[AGENTS.md](/soniqo/speech-swift/blob/main/AGENTS.md "AGENTS.md")

[CLAUDE.md](/soniqo/speech-swift/blob/main/CLAUDE.md "CLAUDE.md")

[CLAUDE.md](/soniqo/speech-swift/blob/main/CLAUDE.md "CLAUDE.md")

[CODEX.md](/soniqo/speech-swift/blob/main/CODEX.md "CODEX.md")

[CODEX.md](/soniqo/speech-swift/blob/main/CODEX.md "CODEX.md")

[CONTRIBUTING.md](/soniqo/speech-swift/blob/main/CONTRIBUTING.md "CONTRIBUTING.md")

[CONTRIBUTING.md](/soniqo/speech-swift/blob/main/CONTRIBUTING.md "CONTRIBUTING.md")

[LICENSE](/soniqo/speech-swift/blob/main/LICENSE "LICENSE")

[LICENSE](/soniqo/speech-swift/blob/main/LICENSE "LICENSE")

[Makefile](/soniqo/speech-swift/blob/main/Makefile "Makefile")

[Makefile](/soniqo/speech-swift/blob/main/Makefile "Makefile")

[Package.swift](/soniqo/speech-swift/blob/main/Package.swift "Package.swift")

[Package.swift](/soniqo/speech-swift/blob/main/Package.swift "Package.swift")

[README.md](/soniqo/speech-swift/blob/main/README.md "README.md")

[README.md](/soniqo/speech-swift/blob/main/README.md "README.md")

[README\_ar.md](/soniqo/speech-swift/blob/main/README_ar.md "README_ar.md")

[README\_ar.md](/soniqo/speech-swift/blob/main/README_ar.md "README_ar.md")

[README\_de.md](/soniqo/speech-swift/blob/main/README_de.md "README_de.md")

[README\_de.md](/soniqo/speech-swift/blob/main/README_de.md "README_de.md")

[README\_es.md](/soniqo/speech-swift/blob/main/README_es.md "README_es.md")

[README\_es.md](/soniqo/speech-swift/blob/main/README_es.md "README_es.md")

[README\_fr.md](/soniqo/speech-swift/blob/main/README_fr.md "README_fr.md")

[README\_fr.md](/soniqo/speech-swift/blob/main/README_fr.md "README_fr.md")

[README\_hi.md](/soniqo/speech-swift/blob/main/README_hi.md "README_hi.md")

[README\_hi.md](/soniqo/speech-swift/blob/main/README_hi.md "README_hi.md")

[README\_ja.md](/soniqo/speech-swift/blob/main/README_ja.md "README_ja.md")

[README\_ja.md](/soniqo/speech-swift/blob/main/README_ja.md "README_ja.md")

[README\_ko.md](/soniqo/speech-swift/blob/main/README_ko.md "README_ko.md")

[README\_ko.md](/soniqo/speech-swift/blob/main/README_ko.md "README_ko.md")

[README\_pt.md](/soniqo/speech-swift/blob/main/README_pt.md "README_pt.md")

[README\_pt.md](/soniqo/speech-swift/blob/main/README_pt.md "README_pt.md")

[README\_ru.md](/soniqo/speech-swift/blob/main/README_ru.md "README_ru.md")

[README\_ru.md](/soniqo/speech-swift/blob/main/README_ru.md "README_ru.md")

[README\_th.md](/soniqo/speech-swift/blob/main/README_th.md "README_th.md")

[README\_th.md](/soniqo/speech-swift/blob/main/README_th.md "README_th.md")

[README\_tr.md](/soniqo/speech-swift/blob/main/README_tr.md "README_tr.md")

[README\_tr.md](/soniqo/speech-swift/blob/main/README_tr.md "README_tr.md")

[README\_vi.md](/soniqo/speech-swift/blob/main/README_vi.md "README_vi.md")

[README\_vi.md](/soniqo/speech-swift/blob/main/README_vi.md "README_vi.md")

[README\_zh.md](/soniqo/speech-swift/blob/main/README_zh.md "README_zh.md")

[README\_zh.md](/soniqo/speech-swift/blob/main/README_zh.md "README_zh.md")

[transcript.txt](/soniqo/speech-swift/blob/main/transcript.txt "transcript.txt")

[transcript.txt](/soniqo/speech-swift/blob/main/transcript.txt "transcript.txt")

View all files

## Repository files navigation

-   [README](#)
-   [Contributing](#)
-   [Apache-2.0 license](#)

More items

# Speech Swift

[](#speech-swift)

AI speech models for Apple Silicon, powered by MLX Swift and CoreML.

📖 Read in: [English](/soniqo/speech-swift/blob/main/README.md) · [中文](/soniqo/speech-swift/blob/main/README_zh.md) · [日本語](/soniqo/speech-swift/blob/main/README_ja.md) · [한국어](/soniqo/speech-swift/blob/main/README_ko.md) · [Español](/soniqo/speech-swift/blob/main/README_es.md) · [Deutsch](/soniqo/speech-swift/blob/main/README_de.md) · [Français](/soniqo/speech-swift/blob/main/README_fr.md) · [हिन्दी](/soniqo/speech-swift/blob/main/README_hi.md) · [Português](/soniqo/speech-swift/blob/main/README_pt.md) · [Русский](/soniqo/speech-swift/blob/main/README_ru.md) · [العربية](/soniqo/speech-swift/blob/main/README_ar.md) · [Tiếng Việt](/soniqo/speech-swift/blob/main/README_vi.md) · [Türkçe](/soniqo/speech-swift/blob/main/README_tr.md) · [ไทย](/soniqo/speech-swift/blob/main/README_th.md)

On-device speech recognition, synthesis, and understanding for Mac and iOS. Runs locally on Apple Silicon — no cloud, no API keys, no data leaves your device.

**[📚 Full Documentation →](https://soniqo.audio)** · **[🤗 HuggingFace Models](https://huggingface.co/aufklarer)** · **[📝 Blog](https://blog.ivan.digital)** · **[💬 Discord](https://discord.gg/TnCryqEMgu)**

[![soniqo%2Fspeech-swift | Trendshift](https://camo.githubusercontent.com/28c514ec5dab5c1576f5c326b150deaa926592613398e1b7e637a1d5d3fb3e53/68747470733a2f2f7472656e6473686966742e696f2f6170692f62616467652f7472656e6473686966742f7265706f7369746f726965732f32343139362f6461696c793f6c616e67756167653d5377696674)](https://trendshift.io/repositories/24196?utm_source=trendshift-badge&utm_medium=badge&utm_campaign=badge-trendshift-24196)

[![Local Speech AI on a MacBook — watch the 4-minute open-source library tour on YouTube](https://camo.githubusercontent.com/999c1f2043037b504b0a45d30b86134795089bf5e1d791ad19fa7edb53668679/68747470733a2f2f696d672e796f75747562652e636f6d2f76692f78397a676361573067556b2f6d617872657364656661756c742e6a7067)](https://youtu.be/x9zgcaW0gUk)

*Local Speech AI on a MacBook — watch the 4-minute open-source library tour on YouTube*

**Use cases:** [Voice Agents](https://soniqo.audio/voice-agents) · [Transcription](https://soniqo.audio/transcription) · [Speech Generation](https://soniqo.audio/speech-generation)

**Capability groups:** STT / ASR · Alignment · TTS · LLMs & translation · Speech-to-speech · Enhancement/restoration · Source separation · Music/audio generation · Wake word, VAD, diarization & speaker identity

**STT / ASR**

-   **[Qwen3-ASR](https://soniqo.audio/guides/transcribe)** — Speech-to-text (automatic speech recognition, 52 languages, MLX + CoreML)
-   **[WhisperASR](/soniqo/speech-swift/blob/main/docs/models/whisper-asr.md)** — Whisper Large-v3 Turbo speech-to-text via native CoreML runtime (ANE, multilingual)
-   **[Parakeet TDT](https://soniqo.audio/guides/parakeet)** — Speech-to-text via CoreML (Neural Engine, NVIDIA FastConformer + TDT decoder, 25 languages)
-   **[Omnilingual ASR](https://soniqo.audio/guides/omnilingual)** — Speech-to-text (Meta wav2vec2 + CTC, **1,672 languages** across 32 scripts, CoreML 300M + MLX 300M/1B/3B/7B) — 0.28 RTF on iPhone 16 Pro
-   **[Streaming Dictation](https://soniqo.audio/guides/dictate)** — Real-time dictation with partials and end-of-utterance detection (Parakeet-EOU-120M) — 0.04 RTF on iPhone 16 Pro
-   **[Nemotron Streaming (Multilingual)](https://soniqo.audio/guides/nemotron)** — Low-latency streaming ASR with native punctuation and capitalization (NVIDIA Nemotron-3.5-ASR-Streaming-0.6B, CoreML + MLX, **40 language-locales**)
-   **[Nemotron Streaming (English)](https://soniqo.audio/guides/nemotron)** — Low-latency streaming ASR with native punctuation and capitalization (NVIDIA Nemotron-Speech-Streaming-0.6B, CoreML, English-only, smaller and faster than the multilingual variant)

**Alignment**

-   **[Qwen3-ForcedAligner](https://soniqo.audio/guides/align)** — Word-level timestamp alignment (audio + text → timestamps)

**TTS / Speech Generation**

-   **[Qwen3-TTS](https://soniqo.audio/guides/speak)** — Text-to-speech (highest quality, streaming, custom speakers, 10 languages)
-   **[CosyVoice TTS](https://soniqo.audio/guides/cosyvoice)** — Streaming TTS with voice cloning, multi-speaker dialogue, emotion tags (9 languages)
-   **[VoxCPM2](https://soniqo.audio/speech-generation)** — 48 kHz studio-quality TTS with voice cloning + instruction-driven voice design (2B, MLX bf16/int8, 30 languages)
-   **[IndexTTS2](/soniqo/speech-swift/blob/main/docs/models/indextts2.md)** — Native MLX voice cloning from a reference voice (IndexTeam IndexTTS-2, 1.5B-class fp16 bundle, speaker/emotion/pause controls)
-   **[F5-TTS](/soniqo/speech-swift/blob/main/docs/models/f5-tts.md)** — Zero-shot voice cloning from a short reference clip + transcript (SWivid F5-TTS v1 Base, DiT flow matching + Vocos, MLX fp16, 24 kHz, English + Mandarin; non-commercial license)
-   **[Higgs TTS 3](/soniqo/speech-swift/blob/main/docs/models/higgs-tts.md)** — Conversational TTS with zero-shot voice cloning and inline emotion/style/SFX/prosody tags (Boson Higgs TTS 3, Qwen3-4B backbone, MLX bf16, 24 kHz, 100+ languages; research/non-commercial license)
-   **[Kokoro TTS](https://soniqo.audio/guides/kokoro)** — On-device TTS (82M, CoreML/Neural Engine, 54 voices, iOS-ready, 10 languages) — 0.08 RTF on iPhone 16 Pro
-   **[VibeVoice TTS](https://soniqo.audio/guides/vibevoice)** — Long-form / multi-speaker TTS (Microsoft VibeVoice Realtime-0.5B + 1.5B, MLX, up to 90-min podcast/audiobook synthesis, EN/ZH)
-   **[Magpie TTS](https://soniqo.audio/guides/magpie)** — Multilingual TTS (NVIDIA Magpie-TTS Multilingual 357M, MLX INT8 411 MB or CoreML INT8 342 MB, 9 languages, 5 baked speakers, streaming on MLX)
-   **[Supertonic TTS](https://soniqo.audio/guides/supertonic)** — On-device flow-matching TTS (Supertone Supertonic-3 99M, CoreML/Neural Engine, 31 languages, 10 voices, G2P-free, 44.1 kHz) — 0.15 RTF on iPhone 16 Pro
-   **[Chatterbox TTS](/soniqo/speech-swift/blob/main/docs/models/chatterbox-tts.md)** — Multilingual TTS with zero-shot voice cloning (Resemble AI Chatterbox Multilingual, MLX fp16 ~1.3 GB, 23 runtime languages; Hebrew requires niqqud, MIT) plus Chatterbox Flash Core ML text-to-waveform from precomputed reference conditioning.
-   **[OmniVoice TTS](https://huggingface.co/aufklarer/OmniVoice-MLX-fp16)** — Non-autoregressive diffusion TTS with zero-shot voice cloning (k2-fsa OmniVoice, Qwen3 backbone, MLX fp16 default / int8 available, 600+ languages, Apache-2.0)
-   **[Indic-Mio](/soniqo/speech-swift/blob/main/docs/models/indic-mio-tts.md)** — Hindi/Indic TTS with inline emotion markers and optional reference-voice cloning (MLX, 24 kHz)

**LLMs & Translation**

-   **[Qwen3Chat](https://soniqo.audio/guides/chat)** — On-device LLM chat (Qwen3.5-0.8B MLX/CoreML plus dense Qwen3 4B and Gemma 4 E2B/E4B MLX backends, streaming tokens)
-   **[FunctionGemma](https://soniqo.audio/guides/function-calls)** — On-device LLM for structured function / tool calls (Gemma 3 270M, CoreML 8-bit palettized, Neural Engine, ~252 tok/s on M5 Pro · 128 tok/s on iPhone 16 Pro)
-   **[MADLAD-400](https://soniqo.audio/guides/translate)** — Many-to-many translation across 400+ languages (3B, MLX INT4 + INT8, T5 v1.1, Apache 2.0)

**Speech-to-Speech & Voice Agents**

-   **[Hibiki Zero-3B](https://soniqo.audio/guides/audio-translate)** — Streaming speech-to-speech translation (FR/ES/PT/DE → EN, MLX INT4 + INT8, Kyutai Moshi/Mimi stack, CC-BY-4.0)
-   **[PersonaPlex](https://soniqo.audio/guides/respond)** — Full-duplex speech-to-speech (7B, audio in → audio out, 18 voice presets)
-   **[Audio2Face-3D](/soniqo/speech-swift/blob/main/docs/models/audio2face3d.md)** — Speech-driven facial animation for avatars (NVIDIA Audio2Face-3D v2.3 Mark, 301 facial coefficients, MLX)

**Enhancement, Separation & Audio Generation**

-   **[DeepFilterNet3](https://soniqo.audio/guides/denoise)** — Real-time noise suppression (2.1M params, 48 kHz). Long-form audio above the 60 s single-shot cap is auto-chunked with crossfade — see `enhanceChunked(...)`
-   **[Source Separation](https://soniqo.audio/guides/separate)** — Music source separation via HTDemucs (Demucs v4) + Open-Unmix (UMX-HQ / UMX-L, 4 stems: vocals/drums/bass/other, 44.1 kHz stereo)
-   **[MAGNeT](https://soniqo.audio/guides/compose)** — Text-to-music generation (Meta MAGNeT Small 300M / Medium 1.5B, MLX INT8, 30 s clips at 32 kHz mono, masked parallel decoding)
-   **[Stable Audio 3](/soniqo/speech-swift/blob/main/docs/models/stable-audio-3.md)** — Text-to-audio/music generation (Stable Audio 3 Medium, MLX INT8/INT4, 44.1 kHz stereo, variable length)
-   **[FlashSR](https://soniqo.audio/guides/upsample)** — Audio super-resolution (FlashSR ICASSP 2025, MLX, 48 kHz mono, 1-step distilled diffusion, INT4 363 MB / INT8 720 MB)

**Turn Detection, Diarization & Speaker Identity**

-   **[Wake-word](https://soniqo.audio/guides/wake-word)** — On-device keyword spotting (KWS Zipformer 3M, CoreML, 26× real-time, configurable keyword list)
-   **[VAD](https://soniqo.audio/guides/vad)** — Voice activity detection (Silero streaming, Pyannote offline, FireRedVAD 100+ languages)
-   **[Speaker Diarization](https://soniqo.audio/guides/diarize)** — Who spoke when (Pyannote pipeline, Sortformer end-to-end on Neural Engine)
-   **[Speaker Embeddings](https://soniqo.audio/guides/embed-speaker)** — WeSpeaker ResNet34 (256-dim), CAM++ (192-dim)

Papers: [Qwen3-ASR](https://arxiv.org/abs/2601.21337) (Alibaba) · [Qwen3-TTS](https://arxiv.org/abs/2601.15621) (Alibaba) · [Omnilingual ASR](https://arxiv.org/abs/2511.09690) (Meta) · [Parakeet TDT](https://arxiv.org/abs/2304.06795) (NVIDIA) · [CosyVoice 3](https://arxiv.org/abs/2505.17589) (Alibaba) · [Kokoro](https://arxiv.org/abs/2301.01695) (StyleTTS 2) · [PersonaPlex](https://arxiv.org/abs/2602.06053) (NVIDIA) · [Mimi](https://arxiv.org/abs/2410.00037) (Kyutai) · [Hibiki](https://arxiv.org/abs/2502.03382) (Kyutai) · [Sortformer](https://arxiv.org/abs/2409.06656) (NVIDIA)

On-device iPhone 16 Pro CoreML benchmarks (RTF, tokens/s, peak memory): [docs/benchmarks/ios-coreml.md](/soniqo/speech-swift/blob/main/docs/benchmarks/ios-coreml.md).

## News

[](#news)

-   **19 Apr 2026** — [MLX vs CoreML on Apple Silicon — A Practical Guide to Picking the Right Backend](https://blog.ivan.digital/mlx-vs-coreml-on-apple-silicon-a-practical-guide-to-picking-the-right-backend-and-why-you-should-f77ddea7b27a)
-   **20 Mar 2026** — [We Beat Whisper Large v3 with a 600M Model Running Entirely on Your Mac](https://blog.ivan.digital/we-beat-whisper-large-v3-with-a-600m-model-running-entirely-on-your-mac-20e6ce191174)
-   **26 Feb 2026** — [Speaker Diarization and Voice Activity Detection on Apple Silicon — Native Swift with MLX](https://blog.ivan.digital/speaker-diarization-and-voice-activity-detection-on-apple-silicon-native-swift-with-mlx-92ea0c9aca0f)
-   **23 Feb 2026** — [NVIDIA PersonaPlex 7B on Apple Silicon — Full-Duplex Speech-to-Speech in Native Swift with MLX](https://blog.ivan.digital/nvidia-personaplex-7b-on-apple-silicon-full-duplex-speech-to-speech-in-native-swift-with-mlx-0aa5276f2e23)
-   **12 Feb 2026** — [Qwen3-ASR Swift: On-Device ASR + TTS for Apple Silicon — Architecture and Benchmarks](https://blog.ivan.digital/qwen3-asr-swift-on-device-asr-tts-for-apple-silicon-architecture-and-benchmarks-27cbf1e4463f)

## Quick start

[](#quick-start)

Add the package to your `Package.swift`:

.package(url: "https://github.com/soniqo/speech-swift", branch: "main")

Import only the modules you need — every model is its own SPM library, so you don't pay for what you don't use:

.product(name: "ParakeetStreamingASR", package: "speech-swift"),
.product(name: "SpeechUI",             package: "speech-swift"),  // optional SwiftUI views

**Transcribe an audio buffer in 3 lines:**

import ParakeetStreamingASR

let model \= try await ParakeetStreamingASRModel.fromPretrained()
let text \= try model.transcribeAudio(audioSamples, sampleRate: 16000)

**Live streaming with partials:**

for await partial in model.transcribeStream(audio: samples, sampleRate: 16000) {
    print(partial.isFinal ? "FINAL: \\(partial.text)" : "... \\(partial.text)")
}

**SwiftUI dictation view in ~10 lines:**

import SwiftUI
import ParakeetStreamingASR
import SpeechUI

@MainActor
struct DictateView: View {
    @State private var store \= TranscriptionStore()

    var body: some View {
        TranscriptionView(finals: store.finalLines, currentPartial: store.currentPartial)
            .task {
                let model \= try? await ParakeetStreamingASRModel.fromPretrained()
                guard let model else { return }
                for await p in model.transcribeStream(audio: samples, sampleRate: 16000) {
                    store.apply(text: p.text, isFinal: p.isFinal)
                }
            }
    }
}

`SpeechUI` ships only `TranscriptionView` (finals + partials) and `TranscriptionStore` (streaming ASR adapter). Use AVFoundation for audio visualization and playback.

Available SPM products: `Qwen3ASR`, `WhisperASR`, `Qwen3TTS`, `Qwen3TTSCoreML`, `ParakeetASR`, `ParakeetStreamingASR`, `NemotronStreamingASR`, `OmnilingualASR`, `KokoroTTS`, `SupertonicTTS`, `VibeVoiceTTS`, `CosyVoiceTTS`, `VoxCPM2TTS`, `IndexTTS2TTS`, `F5TTS`, `HiggsTTS`, `ChatterboxTTS`, `OmniVoiceTTS`, `IndicMioTTS`, `FishAudioTTS`, `MagpieTTS`, `MagpieTTSCoreML`, `MAGNeTMusicGen`, `StableAudio3MusicGen`, `FlashSR`, `PersonaPlex`, `Audio2Face3D`, `HibikiTranslate`, `MADLADTranslation`, `SpeechVAD`, `SpeechWakeWord`, `SpeechEnhancement`, `SpeechRestoration`, `SourceSeparation`, `Qwen3Chat`, `FunctionGemma`, `SpeechCore`, `SpeechUI`, `AudioCommon`.

## Models

[](#models)

Compact view below. **[Full model catalogue with sizes, quantisations, download URLs, and memory tables → soniqo.audio/architecture](https://soniqo.audio/architecture)**.

Model

Task

Backends

Sizes

Languages

[Qwen3-ASR](https://soniqo.audio/guides/transcribe)

Speech → Text

MLX, CoreML (hybrid)

0.6B, 1.7B

52

[WhisperASR](/soniqo/speech-swift/blob/main/docs/models/whisper-asr.md)

Speech → Text

CoreML (ANE)

Large-v3 Turbo

Multi

[Parakeet TDT](https://soniqo.audio/guides/parakeet)

Speech → Text

CoreML (ANE)

0.6B

25 European

[Parakeet EOU](https://soniqo.audio/guides/dictate)

Speech → Text (streaming)

CoreML (ANE)

120M

25 European

[Nemotron Streaming (Multilingual)](https://soniqo.audio/guides/nemotron)

Speech → Text (streaming, punctuated)

CoreML (ANE), MLX

0.6B

**40**

[Nemotron Streaming (English)](https://soniqo.audio/guides/nemotron)

Speech → Text (streaming, punctuated)

CoreML (ANE)

0.6B

EN

[Omnilingual ASR](https://soniqo.audio/guides/omnilingual)

Speech → Text

CoreML (ANE), MLX

300M / 1B / 3B / 7B

**[1,672](https://github.com/facebookresearch/omnilingual-asr/blob/main/src/omnilingual_asr/models/wav2vec2_llama/lang_ids.py)**

[Qwen3-ForcedAligner](https://soniqo.audio/guides/align)

Audio + Text → Timestamps

MLX, CoreML

0.6B

Multi

[Qwen3-TTS](https://soniqo.audio/guides/speak)

Text → Speech

MLX, CoreML

0.6B, 1.7B

10

[CosyVoice3](https://soniqo.audio/guides/cosyvoice)

Text → Speech

MLX

0.5B

9

[VoxCPM2](https://soniqo.audio/speech-generation)

Text → Speech (48 kHz, voice design + cloning)

MLX

2B (bf16/int8)

30

[IndexTTS2](/soniqo/speech-swift/blob/main/docs/models/indextts2.md)

Text → Speech (zero-shot voice cloning)

MLX

1.5B-class (fp16)

EN/ZH

[F5-TTS](/soniqo/speech-swift/blob/main/docs/models/f5-tts.md)

Text → Speech (zero-shot voice cloning)

MLX

336M (fp16)

EN/ZH

[Higgs TTS 3](/soniqo/speech-swift/blob/main/docs/models/higgs-tts.md)

Text → Speech (conversational, zero-shot voice cloning)

MLX

4B (bf16)

100+

[Kokoro-82M](https://soniqo.audio/guides/kokoro)

Text → Speech

CoreML (ANE)

82M

10

[Supertonic-3](https://soniqo.audio/guides/supertonic)

Text → Speech (44.1 kHz, flow-matching, G2P-free)

CoreML (ANE)

99M

31

[VibeVoice Realtime-0.5B](https://soniqo.audio/guides/vibevoice)

Text → Speech (long-form, multi-speaker)

MLX

0.5B

EN/ZH

[VibeVoice 1.5B](https://soniqo.audio/guides/vibevoice)

Text → Speech (up to 90-min podcast)

MLX

1.5B

EN/ZH

[Magpie-TTS Multilingual](https://soniqo.audio/guides/magpie)

Text → Speech (5 baked speakers, streaming)

MLX / CoreML

357M (MLX INT8, CoreML INT8)

9 (CoreML excludes JA)

[Chatterbox Multilingual](/soniqo/speech-swift/blob/main/docs/models/chatterbox-tts.md)

Text → Speech (zero-shot cloning)

MLX

0.8B (fp16)

23 (HE requires niqqud)

[Chatterbox Flash](/soniqo/speech-swift/blob/main/docs/models/chatterbox-tts.md#chatterbox-flash-core-ml)

Text → Speech (voice cloning with external reference conditioning)

CoreML + MLX conditioning bridge

0.8B (fp16 Core ML)

EN

[OmniVoice](https://huggingface.co/aufklarer/OmniVoice-MLX-fp16)

Text → Speech (NAR diffusion, zero-shot cloning)

MLX

0.8B (fp16 default / int8)

**600+**

[Indic-Mio](/soniqo/speech-swift/blob/main/docs/models/indic-mio-tts.md)

Text → Speech (Hindi/Indic, emotion tags, voice cloning)

MLX

fp16

Hindi / Indic

[Fish Audio S2 Pro](/soniqo/speech-swift/blob/main/docs/models/fish-audio-s2-pro.md)

Text → Speech (zero-shot cloning, explicit style markers)

MLX

0.5B-class (fp16)

Multilingual

[Qwen3.5 Chat](/soniqo/speech-swift/blob/main/docs/models/qwen35-chat.md)

Text → Text (LLM)

MLX, CoreML

0.8B

Multi

[Qwen3 Dense Chat](/soniqo/speech-swift/blob/main/docs/models/qwen3-dense-chat.md)

Text → Text (LLM)

MLX

4B

Multi

[Gemma 4 Chat](/soniqo/speech-swift/blob/main/docs/models/gemma4-chat.md)

Text → Text (LLM)

MLX

E2B / E4B (4-bit)

Multi

[FunctionGemma](/soniqo/speech-swift/blob/main/docs/models/function-gemma.md)

Text → Tool calls (LLM)

CoreML

270M

EN-tuned

[MADLAD-400](https://soniqo.audio/guides/translate)

Text → Text (Translation)

MLX

3B

**400+**

[Hibiki Zero-3B](https://soniqo.audio/guides/audio-translate)

Speech → Speech (Translation)

MLX

3B

FR/ES/PT/DE → EN

[PersonaPlex](https://soniqo.audio/guides/respond)

Speech → Speech

MLX

7B

EN

[Audio2Face-3D](/soniqo/speech-swift/blob/main/docs/models/audio2face3d.md)

Speech → Facial animation

MLX

v2.3 Mark

Agnostic

[Silero VAD](https://soniqo.audio/guides/vad)

Voice Activity Detection

MLX, CoreML

309K

Agnostic

[KWS Zipformer](/soniqo/speech-swift/blob/main/docs/models/kws-zipformer.md)

Audio → Wake word

CoreML (ANE)

3M

EN/custom keywords

[Pyannote](https://soniqo.audio/guides/diarize)

VAD + Diarization

MLX

1.5M

Agnostic

[Pyannote Community-1](https://huggingface.co/aufklarer/Pyannote-Community-1-CoreML)

Diarization + speaker embeddings

CoreML (ANE) + Swift VBx

8.35M

Agnostic

[Sortformer](https://soniqo.audio/guides/diarize)

Diarization (E2E)

CoreML (ANE)

—

Agnostic

[DeepFilterNet3](https://soniqo.audio/guides/denoise)

Speech Enhancement

CoreML

2.1M

Agnostic

[Sidon](https://soniqo.audio/guides/restore)

Speech Restoration (denoise + dereverb, 48 kHz)

CoreML

w2v-BERT 2.0 + DAC (fp16/int8)

Agnostic

[HTDemucs (Demucs v4)](https://soniqo.audio/guides/separate)

Source Separation

MLX

168M

Agnostic

[Open-Unmix](https://soniqo.audio/guides/separate)

Source Separation

MLX

8.6M

Agnostic

[MAGNeT](https://soniqo.audio/guides/compose)

Text → Music (30s @ 32 kHz)

MLX

300M / 1.5B (int4/int8)

EN prompts

[Stable Audio 3](/soniqo/speech-swift/blob/main/docs/models/stable-audio-3.md)

Text → Music/audio (44.1 kHz stereo)

MLX

Medium 1.4B (int4/int8)

EN prompts

[FlashSR](https://soniqo.audio/guides/upsample)

Audio super-resolution (48 kHz)

MLX

363 MB / 720 MB (int4/int8)

Agnostic

[WeSpeaker](https://soniqo.audio/guides/embed-speaker)

Speaker Embedding

MLX, CoreML

6.6M

Agnostic

## Installation

[](#installation)

### Homebrew

[](#homebrew)

Requires native ARM Homebrew (`/opt/homebrew`). Rosetta/x86\_64 Homebrew is not supported.

brew install speech

Then:

speech transcribe recording.wav
speech speak "Hello world"
speech translate "Hello, how are you?" --to es
speech respond --input question.wav --transcript
speech-server --port 8080            # local HTTP / WebSocket server (OpenAI-compatible /v1/realtime + /v1/audio/transcriptions)

**[Full CLI reference →](https://soniqo.audio/cli)**

### Swift Package Manager

[](#swift-package-manager)

dependencies: \[
    .package(url: "https://github.com/soniqo/speech-swift", branch: "main")
\]

Import only what you need — every model is its own SPM target:

import Qwen3ASR             // Speech recognition (MLX)
import WhisperASR           // Whisper Large-v3 Turbo (CoreML)
import ParakeetASR          // Speech recognition (CoreML, batch)
import ParakeetStreamingASR // Streaming dictation with partials + EOU
import NemotronStreamingASR // Multilingual streaming ASR with native punctuation (0.6B, 40 langs)
import OmnilingualASR       // 1,672 languages (CoreML + MLX)
import Qwen3TTS             // Text-to-speech
import CosyVoiceTTS         // Text-to-speech with voice cloning
import VoxCPM2TTS           // 48 kHz TTS with voice cloning + voice design (2B)
import IndexTTS2TTS         // Native MLX voice cloning from reference audio
import F5TTS                // Zero-shot voice cloning (DiT flow matching + Vocos)
import HiggsTTS             // Conversational TTS + cloning (Qwen3 backbone, control tags)
import KokoroTTS            // Text-to-speech (iOS-ready)
import VibeVoiceTTS         // Long-form / multi-speaker TTS (EN/ZH)
import MagpieTTS            // Multilingual TTS (NVIDIA Magpie 357M, MLX, 9 langs)
import MagpieTTSCoreML      // Magpie CoreML backend (hybrid CoreML + MLX, 8 langs)
import FishAudioTTS         // Experimental Fish Audio S2 Pro runtime with voice cloning
import IndicMioTTS          // Hindi/Indic TTS with emotion markers
import Qwen3Chat            // On-device LLM chat
import FunctionGemma    // On-device tool-call LLM
import MADLADTranslation    // Many-to-many translation across 400+ languages
import HibikiTranslate      // Streaming speech-to-speech translation (FR/ES/PT/DE → EN)
import PersonaPlex          // Full-duplex speech-to-speech
import SpeechVAD            // VAD + speaker diarization + embeddings
import SpeechWakeWord       // Wake-word / keyword spotting
import SpeechEnhancement    // Noise suppression
import SpeechRestoration    // Speech restoration — denoise + dereverb (Sidon, CoreML, 48 kHz)
import SourceSeparation     // Music source separation (Open-Unmix, 4 stems)
import StableAudio3MusicGen // Text-to-audio/music generation (Stable Audio 3)
import SpeechUI             // SwiftUI components for streaming transcripts
import AudioCommon          // Shared protocols and utilities

### Requirements

[](#requirements)

-   Swift 6+, Xcode 16+ (with Metal Toolchain)
-   macOS 15+ (Sequoia) or iOS 18+, Apple Silicon (M1/M2/M3/M4)

The macOS 15 / iOS 18 minimum comes from [MLState](https://developer.apple.com/documentation/coreml/mlstate) — Apple's persistent ANE state API used by the CoreML pipelines (Qwen3-ASR, Qwen3-Chat, Qwen3-TTS) to keep KV caches resident on the Neural Engine across token steps.

### Build from source

[](#build-from-source)

git clone https://github.com/soniqo/speech-swift
cd speech-swift
make build

`make build` compiles the Swift package **and** the MLX Metal shader library. The Metal library is required for GPU inference — without it you'll see `Failed to load the default metallib` at runtime. `make debug` for debug builds, `make test` for the test suite.

**[Full build and install guide →](https://soniqo.audio/getting-started)**

## Demo apps

[](#demo-apps)

-   **[DictateDemo](/soniqo/speech-swift/blob/main/Examples/DictateDemo)** ([docs](https://soniqo.audio/guides/dictate)) — macOS menu-bar streaming dictation with live partials, VAD-driven end-of-utterance detection, and one-click copy. Runs as a background agent (Parakeet-EOU-120M + Silero VAD).
-   **[iOSEchoDemo](/soniqo/speech-swift/blob/main/Examples/iOSEchoDemo)** — iOS echo demo (Parakeet ASR + Kokoro TTS). Device and simulator.
-   **[PersonaPlexDemo](/soniqo/speech-swift/blob/main/Examples/PersonaPlexDemo)** — Conversational voice assistant with mic input, VAD, and multi-turn context. macOS. RTF ~0.94 on M2 Max (faster than real-time).
-   **[SpeechDemo](/soniqo/speech-swift/blob/main/Examples/SpeechDemo)** — Dictation and TTS synthesis in a tabbed interface. macOS.

Each demo's README has build instructions.

## Code examples

[](#code-examples)

The snippets below show the minimal path for each domain. Every section links to a full guide on [soniqo.audio](https://soniqo.audio) with configuration options, multiple backends, streaming patterns, and CLI recipes.

### Speech-to-Text — [full guide →](https://soniqo.audio/guides/transcribe)

[](#speech-to-text--full-guide-)

import Qwen3ASR

let model \= try await Qwen3ASRModel.fromPretrained()
let text \= model.transcribe(audio: audioSamples, sampleRate: 16000)

Alternative backends: [WhisperASR](/soniqo/speech-swift/blob/main/docs/inference/whisper-asr-inference.md) (Whisper Large-v3 Turbo, native CoreML), [Parakeet TDT](https://soniqo.audio/guides/parakeet) (CoreML, 32× realtime), [Omnilingual ASR](https://soniqo.audio/guides/omnilingual) (1,672 languages, CoreML or MLX), [Streaming dictation](https://soniqo.audio/guides/dictate) (live partials).

### Forced Alignment — [full guide →](https://soniqo.audio/guides/align)

[](#forced-alignment--full-guide-)

import Qwen3ASR

let aligner \= try await Qwen3ForcedAligner.fromPretrained()
let aligned \= aligner.align(
    audio: audioSamples,
    text: "Can you guarantee that the replacement part will be shipped tomorrow?",
    sampleRate: 24000
)
for word in aligned {
    print("\[\\(word.startTime)s - \\(word.endTime)s\] \\(word.text)")
}

### Text-to-Speech — [full guide →](https://soniqo.audio/guides/speak)

[](#text-to-speech--full-guide-)

import Qwen3TTS
import AudioCommon

let model \= try await Qwen3TTSModel.fromPretrained()
let audio \= model.synthesize(text: "Hello world", language: "english")
try WAVWriter.write(samples: audio, sampleRate: 24000, to: outputURL)

Alternative TTS engines: [CosyVoice3](https://soniqo.audio/guides/cosyvoice) (streaming + voice cloning + emotion tags), [Kokoro-82M](https://soniqo.audio/guides/kokoro) (iOS-ready, 54 voices), [VibeVoice](https://soniqo.audio/guides/vibevoice) (long-form podcast / multi-speaker, EN/ZH), [Fish Audio S2 Pro](/soniqo/speech-swift/blob/main/docs/inference/fish-audio-s2-pro.md) (experimental zero-shot cloning + bracket style markers), [Voice cloning](https://soniqo.audio/guides/voice-cloning).

### Speech-to-Speech — [full guide →](https://soniqo.audio/guides/respond)

[](#speech-to-speech--full-guide-)

import PersonaPlex

let model \= try await PersonaPlexModel.fromPretrained()
let responseAudio \= model.respond(userAudio: userSamples)
// 24 kHz mono Float32 output ready for playback

### LLM Chat — [full guide →](https://soniqo.audio/guides/chat)

[](#llm-chat--full-guide-)

import Qwen3Chat
import FunctionGemma

let chat \= try await Qwen35MLXChat.fromPretrained()
chat.chat(messages: \[(.user, "Explain MLX in one sentence")\]) { token, isFinal in
    print(token, terminator: "")
}

### Translation — [full guide →](https://soniqo.audio/guides/translate)

[](#translation--full-guide-)

import MADLADTranslation

let translator \= try await MADLADTranslator.fromPretrained()
let es \= try translator.translate("Hello, how are you?", to: "es")
// → "Hola, ¿cómo estás?"

### Speech Translation — [full guide →](https://soniqo.audio/guides/audio-translate)

[](#speech-translation--full-guide-)

import HibikiTranslate
import AudioCommon

let model \= try await HibikiTranslateModel.fromPretrained()
let pcm \= try AudioFileLoader.load(url: input, targetSampleRate: 24000)
let (englishAudio, textTokens) \= model.translate(
    sourceAudio: pcm, sourceLanguage: .fr
)
// Hibiki Zero-3B — FR/ES/PT/DE → EN, on-device, streaming Mimi codec

### Voice Activity Detection — [full guide →](https://soniqo.audio/guides/vad)

[](#voice-activity-detection--full-guide-)

import SpeechVAD

let vad \= try await SileroVADModel.fromPretrained()
let segments \= vad.detectSpeech(audio: samples, sampleRate: 16000)
for s in segments { print("\\(s.startTime)s → \\(s.endTime)s") }

### Speaker Diarization — [full guide →](https://soniqo.audio/guides/diarize)

[](#speaker-diarization--full-guide-)

import SpeechVAD

let diarizer \= try await DiarizationPipeline.fromPretrained()
let segments \= diarizer.diarize(audio: samples, sampleRate: 16000)
for s in segments { print("Speaker \\(s.speakerId): \\(s.startTime)s - \\(s.endTime)s") }

### Speech Enhancement — [full guide →](https://soniqo.audio/guides/denoise)

[](#speech-enhancement--full-guide-)

import SpeechEnhancement

let denoiser \= try await DeepFilterNet3Model.fromPretrained()
let clean \= try denoiser.enhance(audio: noisySamples, sampleRate: 48000)

### Speech Restoration — [full guide →](https://soniqo.audio/guides/restore)

[](#speech-restoration--full-guide-)

Joint denoise **and** dereverb with [Sidon](https://arxiv.org/abs/2509.17052) (w2v-BERT 2.0 predictor + DAC vocoder, Core ML). Unlike a generic noise suppressor, Sidon is trained to preserve speaker identity, so it is well suited to cleaning a noisy or reverberant voice-cloning reference before TTS. Input is 16 kHz; output is 48 kHz mono.

import SpeechRestoration

let restorer \= try await SpeechRestorer.fromPretrained()          // .fp16 (default) or .int8
let clean \= try restorer.restore(audio: noisySamples, sampleRate: 16000)  // → 48 kHz

From the CLI:

speech restore noisy.wav -o clean.wav            # denoise + dereverb, 48 kHz output
speech restore noisy.wav --variant int8          # smaller, lower peak RAM

# Clean a voice-cloning reference before TTS (opt-in; preserves speaker identity):
speech speak "Hello" --engine voxcpm2 --voice-sample ref.wav --clean-reference

### Voice Pipeline (ASR → LLM → TTS) — [full guide →](https://soniqo.audio/voice-agents)

[](#voice-pipeline-asr--llm--tts--full-guide-)

import SpeechCore

let pipeline \= VoicePipeline(
    stt: parakeetASR,
    tts: qwen3TTS,
    vad: sileroVAD,
    config: .init(mode: .voicePipeline),
    onEvent: { event in print(event) }
)
pipeline.start()
pipeline.pushAudio(micSamples)

`VoicePipeline` is the real-time voice-agent state machine (powered by [speech-core](https://github.com/soniqo/speech-core)) with VAD-driven turn detection, interruption handling, and eager STT. It connects any `SpeechRecognitionModel` + `SpeechGenerationModel` + `StreamingVADProvider`.

### HTTP API server

[](#http-api-server)

speech-server --port 8080

Exposes every model via HTTP REST + WebSocket endpoints, including OpenAI-compatible APIs: a Realtime WebSocket at `/v1/realtime` and a transcription REST endpoint at `/v1/audio/transcriptions`. See [`Sources/AudioServer/`](/soniqo/speech-swift/blob/main/Sources/AudioServer).

## Architecture

[](#architecture)

speech-swift is split into one SPM target per model so consumers only pay for what they import. Shared infrastructure lives in `AudioCommon` (protocols, audio I/O, HuggingFace downloader, `SentencePieceModel`) and `MLXCommon` (weight loading, `QuantizedLinear` helpers, `SDPA` multi-head attention helper).

**[Full architecture diagram with backends, memory tables, and module map → soniqo.audio/architecture](https://soniqo.audio/architecture)** · **[API reference → soniqo.audio/api](https://soniqo.audio/api)** · **[Benchmarks → soniqo.audio/benchmarks](https://soniqo.audio/benchmarks)**

Local docs (repo):

-   **Models:** [Qwen3-ASR](/soniqo/speech-swift/blob/main/docs/models/asr-model.md) · [WhisperASR](/soniqo/speech-swift/blob/main/docs/models/whisper-asr.md) · [Qwen3-TTS](/soniqo/speech-swift/blob/main/docs/models/tts-model.md) · [CosyVoice](/soniqo/speech-swift/blob/main/docs/models/cosyvoice-tts.md) · [Kokoro](/soniqo/speech-swift/blob/main/docs/models/kokoro-tts.md) · [VoxCPM2](/soniqo/speech-swift/blob/main/docs/models/voxcpm2-tts.md) · [IndexTTS2](/soniqo/speech-swift/blob/main/docs/models/indextts2.md) · [F5-TTS](/soniqo/speech-swift/blob/main/docs/models/f5-tts.md) · [Higgs TTS 3](/soniqo/speech-swift/blob/main/docs/models/higgs-tts.md) · [VibeVoice](/soniqo/speech-swift/blob/main/docs/models/vibevoice.md) · [Supertonic](/soniqo/speech-swift/blob/main/docs/models/supertonic-tts.md) · [Chatterbox](/soniqo/speech-swift/blob/main/docs/models/chatterbox-tts.md) · [Indic-Mio](/soniqo/speech-swift/blob/main/docs/models/indic-mio-tts.md) · [Fish Audio S2 Pro](/soniqo/speech-swift/blob/main/docs/models/fish-audio-s2-pro.md) · [Magpie TTS](/soniqo/speech-swift/blob/main/docs/models/magpie-tts.md) · [Parakeet TDT](/soniqo/speech-swift/blob/main/docs/models/parakeet-asr.md) · [Parakeet Streaming](/soniqo/speech-swift/blob/main/docs/models/parakeet-streaming-asr.md) · [Nemotron Streaming](/soniqo/speech-swift/blob/main/docs/models/nemotron-asr-streaming.md) · [Omnilingual ASR](/soniqo/speech-swift/blob/main/docs/models/omnilingual-asr.md) · [PersonaPlex](/soniqo/speech-swift/blob/main/docs/models/personaplex.md) · [Hibiki](/soniqo/speech-swift/blob/main/docs/models/hibiki.md) · [MADLAD-400](/soniqo/speech-swift/blob/main/docs/models/madlad-translation.md) · [FunctionGemma](/soniqo/speech-swift/blob/main/docs/models/function-gemma.md) · [Qwen3.5 Chat](/soniqo/speech-swift/blob/main/docs/models/qwen35-chat.md) · [Gemma 4 Chat](/soniqo/speech-swift/blob/main/docs/models/gemma4-chat.md) · [Qwen3 Dense Chat](/soniqo/speech-swift/blob/main/docs/models/qwen3-dense-chat.md) · [FireRedVAD](/soniqo/speech-swift/blob/main/docs/models/fireredvad.md) · [KWS Zipformer](/soniqo/speech-swift/blob/main/docs/models/kws-zipformer.md) · [Sidon](/soniqo/speech-swift/blob/main/docs/models/sidon.md) · [Source Separation](/soniqo/speech-swift/blob/main/docs/models/source-separation.md) · [HTDemucs](/soniqo/speech-swift/blob/main/docs/models/htdemucs.md) · [MAGNeT](/soniqo/speech-swift/blob/main/docs/models/magnet-music-gen.md) · [Stable Audio 3](/soniqo/speech-swift/blob/main/docs/models/stable-audio-3.md) · [FlashSR](/soniqo/speech-swift/blob/main/docs/models/flashsr.md) · [Audio2Face-3D](/soniqo/speech-swift/blob/main/docs/models/audio2face3d.md)
-   **Inference:** [Qwen3-ASR](/soniqo/speech-swift/blob/main/docs/inference/qwen3-asr-inference.md) · [WhisperASR](/soniqo/speech-swift/blob/main/docs/inference/whisper-asr-inference.md) · [Parakeet TDT](/soniqo/speech-swift/blob/main/docs/inference/parakeet-asr-inference.md) · [Parakeet Streaming](/soniqo/speech-swift/blob/main/docs/inference/parakeet-streaming-asr-inference.md) · [Nemotron Streaming](/soniqo/speech-swift/blob/main/docs/inference/nemotron-asr-streaming.md) · [Omnilingual ASR](/soniqo/speech-swift/blob/main/docs/inference/omnilingual-asr-inference.md) · [TTS](/soniqo/speech-swift/blob/main/docs/inference/qwen3-tts-inference.md) · [VoxCPM2](/soniqo/speech-swift/blob/main/docs/inference/voxcpm2-inference.md) · [IndexTTS2](/soniqo/speech-swift/blob/main/docs/inference/indextts2.md) · [F5-TTS](/soniqo/speech-swift/blob/main/docs/inference/f5-tts.md) · [Higgs TTS 3](/soniqo/speech-swift/blob/main/docs/inference/higgs-tts.md) · [VibeVoice](/soniqo/speech-swift/blob/main/docs/inference/vibevoice-inference.md) · [Fish Audio S2 Pro](/soniqo/speech-swift/blob/main/docs/inference/fish-audio-s2-pro.md) · [Magpie TTS](/soniqo/speech-swift/blob/main/docs/inference/magpie-tts.md) · [Hibiki](/soniqo/speech-swift/blob/main/docs/inference/hibiki-inference.md) · [MADLAD-400](/soniqo/speech-swift/blob/main/docs/inference/madlad-translation.md) · [MAGNeT](/soniqo/speech-swift/blob/main/docs/inference/magnet-music-gen.md) · [Stable Audio 3](/soniqo/speech-swift/blob/main/docs/inference/stable-audio-3.md) · [FlashSR](/soniqo/speech-swift/blob/main/docs/inference/flashsr.md) · [Forced Aligner](/soniqo/speech-swift/blob/main/docs/inference/forced-aligner.md) · [Silero VAD](/soniqo/speech-swift/blob/main/docs/inference/silero-vad.md) · [FireRedVAD](/soniqo/speech-swift/blob/main/docs/inference/fireredvad.md) · [Wake-word](/soniqo/speech-swift/blob/main/docs/inference/wake-word.md) · [Speaker Diarization](/soniqo/speech-swift/blob/main/docs/inference/speaker-diarization.md) · [Speech Enhancement](/soniqo/speech-swift/blob/main/docs/inference/speech-enhancement.md) · [Sidon](/soniqo/speech-swift/blob/main/docs/inference/sidon.md) · [Cache/offline](/soniqo/speech-swift/blob/main/docs/inference/cache-and-offline.md)

...4768 bytes truncated...

The tool call succeeded but the output was truncated. Full output saved to: /Users/emile.bassil/.local/share/opencode/tool-output/tool_f64115c7d001yXWQMasRXjqvnz
Use the Task tool to have explore agent process this file with Grep and Read (with offset/limit). Do NOT read the full file yourself - delegate to save context.
```

---

## Assistant (Build · Big Pickle · 61.8s)

_Thinking:_

This is extremely valuable. Let me synthesize what I've found:

1. **`aufklarer/Whisper-Large-v3-Turbo-CoreML`** - A pre-converted CoreML bundle already exists on HuggingFace. It splits Whisper into 4 CoreML models: MelSpectrogram, AudioEncoder, TextDecoderContextPrefill, TextDecoder. Total size: ~1562 MB (1.56 GB). It's staged for speech-swift's WhisperASR runtime.

2. **`soniqo/speech-swift`** - A comprehensive Swift package that already has `WhisperASR` as an SPM product.It's Apache-2.0 licensed, requires macOS 15+ / iOS 18+, and already includes a dictation demo app in the Examples folder.

3. **Performance**: M5 Pro benchmark shows 1.40% WER on LibriSpeech test-clean, 0.089 mean RTF (11x realtime), 6.1s model load, 384 MB peak RSS. That's very good.

4. **ScreenCaptureKit** for system audio + mic - proven pattern, Raven has a good write-up on dual-stream capture.

Now, the key architectural decision: **Should Whisptator use `speech-swift` as a dependency, or build the CoreML inference pipeline from scratch?**

Using `speech-swift` would give us:
- Proven CoreML Whisper runtime already working
- The pre-converted model bundle
- Audio processing utilities
- VAD support (for meeting mode)
- Dictation demo as reference

But:
- It's a large dependency (brings in MLX, many other models)
- Might be overkill if we only need Whisper
- The user wants a simple, efficient app

Actually, looking at the SPM products, you can import just `WhisperASR` and `AudioCommon` - you don't need the whole thing. That's actually quite clean.

Alternatively, we could build the CoreML inference from scratch using the pre-converted model bundle. This gives full control but is more work.

Let me think about what makes sense...

Actually, the user said "convert openai/whisper-large-v3-turbo to CoreML" - they want to do the conversion themselves. But there's already a pre-converted bundle available. Let me clarify: the user's HuggingFace cache has the PyTorch weights, but the CoreML bundle is a different repo. They'd need to either:
1. Download the pre-converted CoreML bundle from `aufklarer/Whisper-Large-v3-Turbo-CoreML`
2. Convert it themselves using Python tools

Option 1 is clearly better. The user might not realize this exists.

Let me also think about the app architecture more concretely now.

Here's my thinking on the architecture:

```
Whisptator (macOS menu bar app)
├── Sources/
│   ├── App/                    # SwiftUI app entry, menu bar setup
│   ├── Audio/                  # AVFoundation mic capture, ScreenCaptureKit system audio
│   ├── STT/                    # CoreML Whisper inference (using speech-swift WhisperASR or DIY)
│   ├── Hotkeys/                # CGEvent tap for global shortcuts
│   ├── Pasteboard/             # Text insertion (clipboard + CGEvent typing)
│   ├── TextProcessing/         # Filler removal, word replacement, snippets
│   ├── Meeting/                # Meeting recording orchestration, live preview
│└── Settings/               # SwiftUI settings views
├── Resources/
│   └── Models/                 # CoreML model bundle (bundled or downloaded)
└── Package.swift
```

Key dependencies:
- `speech-swift` (for `WhisperASR` + `AudioCommon`) - OR - build CoreML inference directly
- No other external dependencies needed for V1

Actually, let me reconsider. The user said they want to be efficient and use open-weight models. Using `speech-swift` as a dependency is actually quite elegant - it's a well-maintained Swift package with a proven WhisperASR runtime. The SPM modular design means we only import what we need.

But wait - the user specifically said "convert openai/whisper-large-v3-turbo to CoreML". They might want to do this conversion step themselves as part of the build process, or they might just want the result. Let me address both options.

Let me now lay out the comprehensive architecture and the remaining hard questions.

This changes things significantly. Let me lay out what I've found.

---

## Major Discovery: Pre-converted CoreML Bundle Already Exists

You don't need to convert the model yourself. There's a ready-made CoreML bundle:

```
aufklarer/Whisper-Large-v3-Turbo-CoreML  (1.56 GB)
├── MelSpectrogram.mlmodelc          (0.36 MB weights)
├── AudioEncoder.mlmodelc            (1215 MB weights)
├── TextDecoderContextPrefill.mlmodelc (11.7 MB weights)
└── TextDecoder.mlmodelc             (328 MB weights)
```

**Performance on M5 Pro:** 1.40% WER (LibriSpeech test-clean), 0.089 RTF (11× realtime), 6.1s model load, 384 MB peak RSS.

And there's a **production-ready Swift package** that already wraps this: `speech-swift` by soniqo. It has a `WhisperASR` SPM product — import just that one module, no bloat:

```swift
// Package.swift dependency
.package(url: "https://github.com/soniqo/speech-swift", branch: "main")

// In code
import WhisperASR

let model = try await WhisperASRModel.fromPretrained()
let text = model.transcribe(audio: audioSamples, sampleRate: 16000)
```

They even have a **dictation demo app** (`Examples/DictateDemo`) that's a macOS menu bar app with streaming partials — almost exactly what Whisptator wants to be.

---

## Revised Architecture

Given this, there are two paths:

```
┌─────────────────────────────────────────────────────────────┐
│                    PATH A: Use speech-swift                  │
│                                                              │
│  Whisptator depends on speech-swift (WhisperASR only)        │
│  + AudioCommon for audio utilities                            │
│                                                              │
│  ✅ Proven CoreML Whisper runtime                            │
│  ✅ Model download/caching handled                            │
│  ✅ Audio processing utilities included                       │
│  ✅ DictateDemo as reference implementation                   │
│  ✅ VAD available for meeting mode                            │
│  ⚠️  Brings MLX dependency (even if unused)                   │
│  ⚠️  macOS 15+ minimum (MLState API requirement)              │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                    PATH B: DIY CoreML inference               │
│                                                              │
│  Load the 4 .mlmodelc bundles directly via CoreML framework  │
│  Build mel spectrogram, encoder, decoder pipeline yourself   │
│                                                              │
│  ✅ Zero dependencies beyond system frameworks                │
│  ✅ Full control over inference pipeline                      │
│  ✅ Can target macOS 14+                                      │
│  ⚠️  ~2-3 weeks of work to get right                         │
│  ⚠️  Must handle audio preprocessing (mel, chunking)          │
│  ⚠️  Must implement token decoding, language detection        │
│  ⚠️  Must handle VAD for meeting mode separately              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## App Architecture (both paths)

```
┌──────────────────────────────────────────────────────────────────┐
│  WHISPTATOR — Menu Bar App                                        │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  Menu Bar Icon (NSStatusItem)                                │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │  │
│  │  │ Start    │ │ Meeting  │ │ History  │ │ Settings │      │  │
│  │  │ Dictation│ │ Record   │ │          │ │          │      │  │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘      │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  Floating HUD (shown during recording)                       │  │
│  │  ┌─────────────────────────────────────────────────┐        │  │
│  │  │  🔴 Recording...  00:12                         │        │  │
│  │  │  "The quick brown fox jumps over..." (partial)  │        │  │
│  │  └─────────────────────────────────────────────────┘        │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ═══════════════════ CORE SERVICES ═══════════════════════════    │
│                                                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │  Hotkey      │  │  Audio      │  │  STT        │              │
│  │  Monitor     │  │  Capture    │  │  Engine     │              │
│  │             │  │             │  │             │              │
│  │  CGEvent tap│  │  AVFoundation│  │  WhisperASR │              │
│  │  global     │  │  (mic)      │  │  (CoreML)   │              │
│  │  shortcuts  │  │  ScreenCap- │  │             │              │
│  │             │  │  tureKit    │  │  or DIY     │              │
│  │  Push-to-   │  │  (system)   │  │  CoreML     │              │
│  │  talk +     │  │             │  │  pipeline   │              │
│  │  hands-free │  │  Mix both   │  │             │              │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘              │
│         │                │                │                      │
│         ▼                ▼                ▼                      │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    ORCHESTRATOR                           │    │
│  │                                                          │    │
│  │  Hotkey pressed → Start capture → Accumulate audio       │    │
│  │  Hotkey released → Stop capture → Transcribe             │    │
│  │  → Text cleanup → Paste into frontmost app               │    │
│  └──────────────────────────┬──────────────────────────────┘    │
│                             │                                    │
│         ┌───────────────────┼───────────────────┐               │
│         ▼                   ▼                   ▼               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │
│  │  Text       │  │  Paste      │  │  Meeting Mode        │    │
│  │  Cleanup    │  │  Engine     │  │                      │    │
│  │             │  │             │  │  ScreenCaptureKit    │    │
│  │  Fillers    │  │  Clipboard  │  │  (system audio)      │    │
│  │  Replaces   │  │  (Cmd+V)    │  │  + AVFoundation      │    │
│  │  Snippets   │  │     or     │  │  (microphone)        │    │
│  │  Whitespace │  │  CGEvent    │  │                      │    │
│  │             │  │  (typing)   │  │  Live transcript     │    │
│  │  <1ms       │  │             │  │  preview in HUD      │    │
│  └─────────────┘  └─────────────┘  └─────────────────────┘    │
│                                                                   │
│  ═══════════════════ SETTINGS ═══════════════════════════════    │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Settings Window (SwiftUI)                               │    │
│  │                                                          │    │
│  │  General:                                                │    │
│  │    • Launch at login                                     │    │
│  │    • Show in Dock (toggle)                               │    │
│  │                                                          │    │
│  │  Dictation:                                              │    │
│  │    • Push-to-talk shortcut recorder                      │    │
│  │    • Hands-free shortcut recorder                        │    │
│  │    • Paste mode: Clipboard (default) / Typing            │    │
│  │    • Audio input device picker                           │    │
│  │    • Language (auto / specific)                          │    │
│  │                                                          │    │
│  │  Model:                                                  │    │
│  │    • Fixed list:                                         │    │
│  │      ┌──────────────────────────────────────┐           │    │
│  │      │ ○ whisper-large-v3-turbo  (1.56 GB)  │           │    │
│  │      │ ○ whisper-large-v3        (3.09 GB)  │           │    │
│  │      │ ○ whisper-medium          (1.53 GB)  │           │    │
│  │      │ ○ whisper-small           (488 MB)   │           │    │
│  │      │ ○ whisper-base            (150 MB)   │           │    │
│  │      │ ○ whisper-tiny            (77 MB)    │           │    │
│  │      └──────────────────────────────────────┘           │    │
│  │    • Download status indicator                            │    │
│  │    • Model storage location                               │    │
│  │                                                          │    │
│  │  Text Cleanup:                                           │    │
│  │    • Filler words (toggle + custom list)                  │    │
│  │    • Word replacements (table)                            │    │
│  │    • Snippets (trigger → expansion)                       │    │
│  │                                                          │    │
│  │  Meeting:                                                │    │
│  │    • System audio / Mic only / Both                       │    │
│  │    • Audio retention (keep / auto-delete / remove)        │    │
│  │    • Pause Now Playing (beta)                             │    │
│  └─────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
```

---

## The Hard Things — Still

### Meeting Mode Audio Mixing

ScreenCaptureKit can capture system audio and microphone simultaneously, but there's a known sync issue. The cleanest approach from what I've found:

```
┌────────────────────────────────────────────────────────────┐
│  Audio Pipeline (Meeting Mode)                              │
│                                                             │
│  ScreenCaptureKit ──▶ System audio PCM ──┐                  │
│  (capturesAudio: true)                   │                  │
│                                          ├──▶ Mixer ──▶ STT│
│  AVAudioEngine ────▶ Mic PCM ───────────┘                  │
│  (separate capture)                     │                  │
│                                         ▼                   │
│                                   Save to file              │
│                                   (for export)              │
│                                                             │
│  Key: Use CATap API (macOS 13+) for synchronized           │
│       capture with drift correction                         │
└────────────────────────────────────────────────────────────┘
```

### Paste Mechanism — Dual Mode

```
┌────────────────────────────────────────────────────────────┐
│  Paste Engine                                               │
│                                                             │
│  Input: transcribed text + paste mode setting               │
│                                                             │
│  ┌─ Clipboard Mode (default) ──────────────────────────┐   │
│  │  1. Save current pasteboard contents                  │   │
│  │  2. Set pasteboard to transcribed text                │   │
│  │  3. CGEvent: Cmd+V                                    │   │
│  │  4. Wait 100ms                                        │   │
│  │  5. Restore original pasteboard                       │   │
│  │  ✅ Fast, works with rich text fields                  │   │
│  │  ⚠️  Briefly clobbers clipboard                       │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─ Typing Mode ───────────────────────────────────────┐   │
│  │  1. For each character in text:                       │   │
│  │     CGEvent(keyboardEvent) with keycode               │   │
│  │  2. Handle modifier keys, special chars               │   │
│  │  ✅ Appears as if typed                                │   │
│  │  ⚠️  Slow for long text (limited by key event rate)   │   │
│  │  ⚠️  Doesn't work with all input methods              │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  User configures which mode in Settings                     │
└────────────────────────────────────────────────────────────┘
```

---

## Remaining Questions

1. **speech-swift vs DIY** — Do you want to use `speech-swift`'s `WhisperASR` module (proven, saves weeks of work, adds macOS 15+ requirement), or build the CoreML inference pipeline from scratch (more control, macOS 14+ possible, significantly more work)?

2. **Model storage** — The CoreML bundle is 1.56 GB. Where should it live? In the app bundle (makes the app huge), or downloaded on first launch to `~/Library/Application Support/Whisptator/Models/` (like macparakeet does)?

3. **Meeting mode scope** — For V1, do you want the full meeting workflow (live transcript preview, notes, save/export), or just "record + transcribe + save transcript"?

4. **macOS minimum** — If we use speech-swift, minimum is macOS 15 (Sequoia). If DIY, macOS 14 (Sonoma). Does that matter to you?

What's your instinct on the speech-swift question? That's the biggest fork in the road right now.

---

## User

1. use speech-swift's WhisperASR module. 2. downloaded on first launch to ~/Library/Application Support/Whisptator/Models/ (like macparakeet does). 3. just "record + transcribe + save transcript". 4. Doesn't matter.

---

## Assistant (Build · Big Pickle · 26.0s)

_Thinking:_

The user has made clear decisions on all four questions. Now I need to think deeply about the architecture with these decisions locked in. Let me synthesize everything and present a comprehensive exploration.

Let me think about what remains to explore:

1. The speech-swift WhisperASR integration path
2. The model download flow
3. The hotkey system4. The meeting mode (simple: record + transcribe + save)
5. The text cleanup pipeline
6. The settings UI
7. The paste mechanism
8. The menu bar app structure

Let me think about the concrete Swift code architecture and any remaining technical questions.

Actually, let me also think about what speech-swift's WhisperASR actually provides vs what we need to build. The dictate demo already exists - we should study it.

Let me also think about the overall app structure more concretely. A menu bar app in SwiftUI means:
- `MenuBarExtra` (macOS 13+)
- No dock icon (optional)
- NSStatusItem
- Settings via Settings scene or a separate window

For the hotkey system, we need:
- CGEvent tap (requires accessibility permission)
- Register for key down/up events
- Match against saved shortcuts
- Two modes: push-to-talk (hold) and hands-free (toggle)

For audio capture:
- Dictation mode: AVFoundation for microphone
- Meeting mode: ScreenCaptureKit for system audio + AVFoundation for mic

For the STT:
- speech-swift's WhisperASR module
- Load model from ~/Library/Application Support/Whisptator/Models/
- Transcribe audio buffer → text

For text cleanup:
- Deterministic pipeline
- Filler removal, word replacements, snippets, whitespace

For paste:
- Clipboard mode (default): save pasteboard → set text → Cmd+V → restore
- Typing mode: CGEvent keyboard simulation

Let me also think about the model download flow. The user wants models downloaded to ~/Library/Application Support/Whisptator/Models/. speech-swift likely has its own download mechanism via HuggingFace hub. We might need to configure it to use our custom path.

Actually, looking at speech-swift more carefully, `WhisperASRModel.fromPretrained()` probably downloads to a default location. We might need to use `fromPretrained(repoId:localPath:)` or similar to point to our custom directory. Or we could download the model ourselves and point speech-swift to the local path.

Let me also think about the fixed model list. The user wants a fixed list of known models. These would be CoreML bundles from the argmaxinc/whisperkit-coreml or aufklarer repos on HuggingFace. Each model has a different size and accuracy tradeoff.

Wait - there's an important subtlety here. speech-swift's WhisperASR uses the `aufklarer/Whisper-Large-v3-Turbo-CoreML` bundle format (4 .mlmodelc files). But other Whisper sizes might not have CoreML conversions readily available. Let me think about which models are actually available in CoreML format...

From the search results:
- `aufklarer/Whisper-Large-v3-Turbo-CoreML` - confirmed working
- `argmaxinc/whisperkit-coreml` has various sizes but in WhisperKit format

The WhisperKit models might not be directly compatible with speech-swift's WhisperASR runtime. So the fixed list might need to be limited to models that have compatible CoreML bundles.

Actually, let me reconsider. speech-swift's WhisperASR documentation says it supports "Large-v3 Turbo" specifically. The model page says "WhisperASR — Whisper Large-v3 Turbo speech-to-text via native CoreML runtime (ANE, multilingual)". It might only support that one model size.

This is an important constraint. Let me think about whether we can extend it to other sizes...

For V1, supporting just the large-v3-turbo model is probably fine. The user already has it and it's the best balance of speed and accuracy. We can add more models later.

But the user asked for a "fixed list of known models" in settings. If we only support one model, the settings UI is simpler - just show that one model with its download status.

Actually, let me re-read what the user said: "I want a fixed list of known models." They might mean: show the models that are available for download, not necessarily all installed. Like a catalog with download buttons.

Let me think about this more carefully...

For V1, I think the right approach is:
1. Show a fixed list of Whisper model sizes that have CoreML conversions available
2. Each shows download status (not downloaded / downloading / downloaded)
3. User can select which one to use
4. Default to large-v3-turbo

The models available in CoreML format from argmaxinc/whisperkit-coreml:
- large-v3-v20240930_626MB (compressed)
- large-v3-v20240930_turbo
- base, base.en
- small, small.en
- tiny, tiny.en

But again, these are WhisperKit format, not necessarily compatible with speech-swift's WhisperASR.

Hmm, let me think about this differently. Maybe the approach is:
1. For the default/large-v3-turbo, use speech-swift's WhisperASR with the aufklarer bundle
2. For other models, we'd need to either:
   a. Use WhisperKit directly (adds dependency)
   b. Convert models ourselves
   c. Only support the one model for V1

I think the cleanest V1 is: **support large-v3-turbo only**, with a note that more models can be added later. The settings shows the one model with download status.

If the user wants multiple models, we can discuss that as a V2 feature.

Let me now think about the overall architecture more concretely and present my findings.

Actually, I realize I should explore the speech-swift dictate demo more to understand the pattern. But I've already fetched a lot of information. Let me synthesize what I have.

Let me present the comprehensive exploration now.

Clean decisions. Let me synthesize the full picture now.

**Tool: webfetch**

**Input:**
```json
{
  "format": "text",
  "url": "https://raw.githubusercontent.com/soniqo/speech-swift/main/docs/models/whisper-asr.md"
}
```

**Output:**
```
# WhisperASR CoreML

WhisperASR runs Whisper Large-v3 Turbo through speech-swift's native CoreML runtime. The default model bundle is [`aufklarer/Whisper-Large-v3-Turbo-CoreML`](https://huggingface.co/aufklarer/Whisper-Large-v3-Turbo-CoreML).

## Model

| Field | Value |
|-------|-------|
| Family | Whisper Large-v3 Turbo |
| Default repo | `aufklarer/Whisper-Large-v3-Turbo-CoreML` |
| Tokenizer source | `openai/whisper-large-v3` |
| Backend | CoreML |
| Precision | FP16 |
| Input audio | 16 kHz mono Float32 |
| Chunk size | 30 s fixed CoreML mel input |
| Languages | Whisper multilingual language set |

The model ships as a split CoreML bundle:

| CoreML model | Default compute units | Purpose |
|--------------|-----------------------|---------|
| `MelSpectrogram.mlmodelc` | CPU + GPU | 30 s waveform to Whisper log-mel features |
| `AudioEncoder.mlmodelc` | CPU + Neural Engine | Mel features to encoder embeddings |
| `TextDecoderContextPrefill.mlmodelc` | CPU + Neural Engine | Initial decoder cache for language/task tokens |
| `TextDecoder.mlmodelc` | CPU + Neural Engine | Autoregressive token generation with explicit KV-cache updates |

## Runtime Scope

The runtime is implemented in `Sources/WhisperASR` and loads the CoreML sub-models directly. It does not call WhisperKit for inference.

Current behavior:

- Greedy no-timestamp decoding.
- Optional language hint, otherwise Whisper language-token detection.
- Byte-level tokenizer decode from the model bundle.
- 30 s chunking with per-chunk autorelease pools.
- Repeated-word stop guard for obvious greedy hallucination loops.

Not yet implemented:

- Word timestamps and timestamp-token decoding.
- Temperature fallback and beam-search policies.
- WhisperKit's long-form VAD/chunk seeking heuristics.

## Swift API

```swift
import WhisperASR

let model = try await WhisperASRModel.fromPretrained()
let text = try await model.transcribeAudio(samples, sampleRate: 16000, language: "en")
```

The default model can be overridden with a full HuggingFace repo ID:

```swift
let model = try await WhisperASRModel.fromPretrained(
    modelId: "aufklarer/Whisper-Large-v3-Turbo-CoreML")
```

## CLI

```bash
speech transcribe recording.wav --engine whisper
speech transcribe recording.wav --engine whisper --model turbo --language en
```

Accepted short model aliases are `default`, `turbo`, `whisper`, `whisper-turbo`, `large-v3-turbo`, and `large-v3-v20240930_turbo`. A full HuggingFace repo ID is also accepted.

## Benchmark

Quick LibriSpeech test-clean slice on Apple M5 Pro, 48 GB, macOS 26.5.1, debug build, 2026-07-01:

| Engine | WER% | CER% | Mean RTF | Median RTF | Overall xRT | Load | Peak RSS | RSS Delta |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| WhisperASR native | 1.40 | 0.39 | 0.089 | 0.078 | 14.0x | 6.1s | 384 MB | +295 MB |
| Direct WhisperKit | 1.53 | 0.46 | 0.085 | 0.074 | 15.5x | 100.2s | 507 MB | +418 MB |

See [ASR WER benchmark](../benchmarks/asr-wer.md#whisperasr-native-runtime-comparison) for methodology, caveats, and the wider engine table.

## Model Weights

- [`aufklarer/Whisper-Large-v3-Turbo-CoreML`](https://huggingface.co/aufklarer/Whisper-Large-v3-Turbo-CoreML) - CoreML bundle used by `WhisperASRModel.defaultModelId`.
- [`openai/whisper-large-v3`](https://huggingface.co/openai/whisper-large-v3) - tokenizer fallback source.

## Thread Safety

`WhisperASRModel` owns CoreML models and per-call decoder state. Concurrent callers should create separate model instances until shared-instance concurrency is explicitly validated.

```

**Tool: webfetch**

**Input:**
```json
{
  "format": "text",
  "url": "https://raw.githubusercontent.com/soniqo/speech-swift/main/docs/inference/whisper-asr-inference.md"
}
```

**Output:**
```
# WhisperASR Inference Pipeline

## Overview

```
Audio (16 kHz mono) -> MelSpectrogram CoreML -> AudioEncoder CoreML -> greedy TextDecoder CoreML -> text
```

WhisperASR provides a native speech-swift runtime for the published [`aufklarer/Whisper-Large-v3-Turbo-CoreML`](https://huggingface.co/aufklarer/Whisper-Large-v3-Turbo-CoreML) bundle. It is intended as the built-in Whisper baseline for `speech transcribe --engine whisper` and for direct Swift use through the `WhisperASR` SPM target.

## Pipeline Stages

### 1. Audio Loading and Resampling

Input audio is loaded as mono Float32 and resampled to 16 kHz when needed. The CoreML mel model expects a fixed 480,000-sample window, so shorter audio is zero-padded and longer audio is processed in 30 s chunks.

### 2. CoreML Mel Spectrogram

`MelSpectrogram.mlmodelc` converts the 30 s waveform window to Whisper log-mel features. The runtime uses CPU + GPU for this model because that matches the lower-memory WhisperKit-style placement observed during benchmarking.

### 3. CoreML Encoder

`AudioEncoder.mlmodelc` runs the Whisper encoder on CPU + Neural Engine and emits encoder embeddings for the decoder.

### 4. Language Token

If the caller passes `language`, the runtime uses the matching Whisper language token. Without a language hint, it runs one decoder step from the start-of-transcript token and selects the best language token.

### 5. Decoder Prefill and Greedy Decode

`TextDecoderContextPrefill.mlmodelc` creates the cache for language and task tokens. `TextDecoder.mlmodelc` then generates tokens one step at a time, with explicit `key_cache`, `value_cache`, cache masks, and cache-length updates supplied by Swift.

The current decoder uses greedy no-timestamp generation. It suppresses special tokens and stops on the end token, with a narrow repeated-word guard for obvious hallucination loops.

## CLI

```bash
# Default Whisper Large-v3 Turbo CoreML bundle
speech transcribe recording.wav --engine whisper

# Explicit alias
speech transcribe recording.wav --engine whisper --model turbo

# Pass a language hint
speech transcribe recording.wav --engine whisper --language de

# Use a full CoreML repo ID
speech transcribe recording.wav --engine whisper --model aufklarer/Whisper-Large-v3-Turbo-CoreML
```

Accepted short aliases:

- `default`
- `turbo`
- `whisper`
- `whisper-turbo`
- `large-v3-turbo`
- `large-v3-v20240930-turbo`
- `large-v3-v20240930_turbo`

Other short names are rejected so `--model medium` or `--model small` cannot accidentally load a non-CoreML layout. Pass a full HuggingFace repo ID for custom CoreML bundles.

## Swift

```swift
import WhisperASR

let model = try await WhisperASRModel.fromPretrained()
let text = try await model.transcribeAudio(audioSamples, sampleRate: 48_000, language: "en")
```

To retrieve the detected or hinted language:

```swift
let result = try await model.transcribeWithLanguageAsync(
    audio: audioSamples,
    sampleRate: 16_000,
    language: nil)
print(result.text)
print(result.language ?? "unknown")
```

## Benchmarking

The benchmark harness includes both the native runtime and direct WhisperKit baselines:

```bash
.build/debug/asr-bench \
  --dataset ~/Library/Caches/qwen3-speech/datasets/LibriSpeech/test-clean \
  --engines whisper-asr-turbo whisperkit-large-v3-turbo \
  --language en \
  --limit 100
```

The latest quick slice is recorded in [docs/benchmarks/asr-wer.md](../benchmarks/asr-wer.md#whisperasr-native-runtime-comparison). Use `--isolated` in release builds before publishing cross-engine memory numbers because CoreML and MLX caches otherwise share a process high-water mark.

## Cache and Offline Use

`fromPretrained()` downloads the CoreML bundle into the standard speech-swift HuggingFace cache. Use `cacheDir:` to override the location and `offlineMode: true` once the model files are already present:

```swift
let model = try await WhisperASRModel.fromPretrained(
    offlineMode: true)
```

The runtime also ensures the tokenizer metadata is present. If the CoreML bundle cache does not include tokenizer files, it fetches them from `openai/whisper-large-v3` unless offline mode is enabled.

## Limitations

- No word timestamps yet.
- No temperature fallback or beam-search policies yet.
- No WhisperKit VAD/chunk seeking parity yet.
- 30 s fixed mel windows define the current chunking behavior.

See [WhisperASR CoreML](../models/whisper-asr.md) for model layout and architecture notes.

```

---

## Assistant (Build · Big Pickle · 86.9s)

_Thinking:_

Now I have a very clear picture of the WhisperASR runtime. Key findings:

1. `WhisperASRModel.fromPretrained()` downloads to speech-swift's default HuggingFace cache
2. We can override with `cacheDir:` parameter3. It only supports the large-v3-turbo model (aufklarer bundle)
4. The API is clean: `transcribeAudio(samples, sampleRate:, language:)`
5. It handles 16kHz mono Float32 input, 30s chunking
6. No word timestamps yet (but that's fine for V1)
7. `offlineMode: true` for when model is already cached

So for the model download flow:
- User opens Settings → Model section
- Sees "Whisper Large-v3 Turbo (1.56 GB)" with a Download button
- On download, we use `WhisperASRModel.fromPretrained(cacheDir: customPath)` 
- Or we could download manually to ~/Library/Application Support/Whisptator/Models/ and use `offlineMode: true`

Actually, looking at the API more carefully, `fromPretrained(cacheDir:)` lets us specify where to cache. So we can set `cacheDir` to our custom path and it'll download there on first call.

For the fixed model list - since WhisperASR only supports large-v3-turbo, the settings just shows that one model. We can add a note about future model support.

Now let me think about the complete architecture and present the final exploration.

Let me also think about the meeting mode. The user wants "just record + transcribe + save transcript". This is simpler than macparakeet's full meeting workflow.

Meeting mode flow:
1. User clicks "Start Meeting Recording" in menu bar
2. System audio capture starts (ScreenCaptureKit)
3. Microphone capture starts (AVFoundation)
4. Audio streams are mixed and accumulated
5. User clicks "Stop" in menu bar
6. Mixed audio is transcribed via WhisperASR
7. Transcript is saved to a file (TXT or JSON)
8. Audio file is optionally kept or deleted based on settings

For V1, no live preview, no notes, no library. Just record → stop → transcribe → save.

Actually wait, the user mentioned "See a live local transcript preview" in their original description. Let me re-read...

"Meeting recording — Record system audio and microphone together, or pick microphone-only or system-only capture (microphone-only needs no Screen Recording permission). See a live local transcript preview, take notes during the call, then save the finalized transcript to the library with export, prompts, and chat. Choose how long to keep the source audio: keep it, auto-delete after a set number of days, or remove it right after transcription."

But then they said V1 should be "just record + transcribe + save transcript". So the live preview, notes, library, export, prompts, chat are all V2+. V1 is the minimal recording flow.

OK, let me now present the comprehensive exploration. I think I have enough information to give a thorough picture.

Let me think about the overall file structure:

```
Whisptator/
├── Package.swift
├── Sources/
│   ├── Whisptator/                    # Main app target
│   │   ├── WhisptatorApp.swift        # @main, MenuBarExtra
│   │   ├── MenuBarView.swift          # Menu bar popover content
│   │   ├── SettingsView.swift         # Settings window
│   │   ├── FloatingHUD.swift          # Recording indicator overlay
│   │   └── Resources/
│   │       └── Assets.xcassets
│   │
│   ├── WhisptatorCore/                # Core library (no UI)
│   │   ├── Audio/
│   │   │   ├── MicrophoneCapture.swift # AVFoundation mic capture
│   │   │   ├── SystemAudioCapture.swift   # ScreenCaptureKit system audio
│   │   │   ├── AudioMixer.swift           # Mix mic + system streams
│   │   │   └── AudioDeviceManager.swift   # List/select audio devices
│   │   ├── STT/
│   │   │   ├── TranscriptionEngine.swift  # WhisperASR wrapper
│   │   │   └── ModelManager.swift         # Download, cache, switch models
│   │   ├── Hotkeys/
│   │   │   ├── HotkeyMonitor.swift        # CGEvent tap
│   │   │   ├── ShortcutRecorder.swift     # Shortcut recording UI logic
│   │   │   └── HotkeyDefinitions.swift    # Push-to-talk, hands-free
│   │   ├── Paste/
│   │   │   ├── ClipboardPaster.swift      # Cmd+V paste
│   │   │  └── TypingPaster.swift         # CGEvent character-by-character
│   │   ├── TextProcessing/
│   │   │   ├── TextCleanupPipeline.swift  # Orchestrator
│   │   │   ├── FillerRemover.swift
│   │   │   ├── WordReplacer.swift
│   │   │   ├── SnippetExpander.swift
│   │   │   └── WhitespaceCleaner.swift
│   │   ├── Meeting/
│   │   │   ├── MeetingRecorder.swift      # Orchestrates recording session
│   │   │   └── TranscriptSaver.swift      # Save to file
│   │   └── Settings/
│   │└── AppSettings.swift          # UserDefaults wrapper
│   │
│   └── WhisptatorTests/
│       ├── TextProcessingTests/
│       └── HotkeyTests/
│
├── Resources/
│   └── Info.plist
│
└── README.md
```

Dependencies:
- `speech-swift` (WhisperASR + AudioCommon)
- System frameworks: AVFoundation, ScreenCaptureKit, CoreGraphics, CoreML

That's actually a pretty clean architecture. Let me think about the key integration points and any remaining hard questions.

One thing I want to think about: the CGEvent tap for global hotkeys. This requires:
1. Accessibility permission (AXIsProcessTrusted)
2. CGEvent tap creation
3. Matching key events against saved shortcuts

The pattern is well-established (macparakeet uses it). But there's a subtlety: the CGEvent tap needs to run on a dedicated thread with its own RunLoop, and it must be re-enabled periodically (macOS disables taps that are too slow).

For the paste mechanism, the clipboard approach is straightforward. The typing approach is more complex - we need to map characters to keycodes, handle Unicode, and deal with different keyboard layouts. For V1, clipboard is the default and typing is opt-in.

Let me also think about the floating HUD during recording. This is a small overlay window that shows:
- Recording indicator (red dot)
- Timer
- Partial transcript (if available)

This would be an `NSPanel` with `.floating` level, positioned near the menu bar or at a fixed location.

For the settings window, since this is a menu bar app, settings could be:
1. A separate `Settings` scene (SwiftUI)
2. A popover from the menu bar icon
3. A window opened from the menu bar

macparakeet uses a full settings window. For simplicity, a SwiftUI `Settings` scene with tabs would work well.

OK, I think I have a comprehensive picture now. Let me present the final exploration.

Actually, one more thing - I should think about the permission flow. The app needs:
1. Accessibility permission (for global hotkeys + text pasting via CGEvent)
2. Microphone permission (for audio capture)
3. Screen Recording permission (for system audio in meeting mode)

The permission flow should be:
1. On first launch, check all permissions
2. Show a friendly onboarding dialog explaining what's needed
3. Guide user to System Settings to grant permissions
4. Don't proceed until required permissions are granted

This is important for UX - users need to understand why these permissions are needed.

Let me now write the comprehensive exploration.

Excellent. Now I have the full picture. Let me lay out the complete architecture.

---

## Final Architecture — Whisptator

### Dependency Map

```
┌─────────────────────────────────────────────────────────────────┐
│  Whisptator                                                     │
│                                                                  │
│  External:                                                       │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  speech-swift (branch: main)                              │   │
│  │  ├── WhisperASR  ← our STT engine                         │   │
│  │  └── AudioCommon ← audio utilities, HuggingFace cache     │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  System frameworks:                                              │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  AVFoundation        (mic capture, audio devices)         │   │
│  │  ScreenCaptureKit    (system audio for meetings)          │   │
│  │  CoreGraphics        (CGEvent hotkeys, text pasting)      │   │
│  │  CoreML              (Whisper inference backend)          │   │
│  │  SwiftUI             (UI)                                 │   │
│  │  AppKit              (NSStatusItem, NSPanel, pasteboard)  │   │
│  │  ServiceManagement  (launch at login)                     │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### File Structure

```
Whisptator/
├── Package.swift
├── Sources/
│   ├── Whisptator/                        # App target
│   │   ├── WhisptatorApp.swift            # @main, MenuBarExtra
│   │   ├── MenuBarView.swift              # Popover: start/stop, status
│   │   ├── SettingsView.swift             # Settings window (tabs)
│   │   ├── FloatingHUD.swift              # Recording overlay panel
│   │   ├── PermissionGate.swift           # Onboarding permission flow
│   │   └── Resources/Assets.xcassets
│   │
│   ├── WhisptatorCore/                    # Core library (no UI deps)
│   │   ├── Audio/
│   │   │   ├── MicrophoneCapture.swift
│   │   │   ├── SystemAudioCapture.swift
│   │   │   ├── AudioMixer.swift
│   │   │   └── AudioDeviceManager.swift
│   │   ├── STT/
│   │   │   ├── TranscriptionEngine.swift
│   │   │   └── ModelManager.swift
│   │   ├── Hotkeys/
│   │   │   ├── HotkeyMonitor.swift
│   │   │   └── ShortcutRecorder.swift
│   │   ├── Paste/
│   │   │   ├── ClipboardPaster.swift
│   │   │   └── TypingPaster.swift
│   │   ├── TextProcessing/
│   │   │   ├── TextCleanupPipeline.swift
│   │   │   ├── FillerRemover.swift
│   │   │   ├── WordReplacer.swift
│   │   │   ├── SnippetExpander.swift
│   │   │   └── WhitespaceCleaner.swift
│   │   ├── Meeting/
│   │   │   ├── MeetingRecorder.swift
│   │   │   └── TranscriptSaver.swift
│   │   └── Settings/
│   │       └── AppSettings.swift
│   │
│   └── WhisptatorTests/
│       └── TextProcessingTests/
│
└── README.md
```

---

### The Core Loop — Dictation

This is the heart of the app. Every path leads here:

```
┌─────────────────────────────────────────────────────────────────┐
│  DICTATION FLOW                                                  │
│                                                                  │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐                │
│  │  User    │     │  Hotkey  │     │  Audio   │                │
│  │  presses │────▶│  Monitor │────▶│  Capture │                │
│  │  shortcut│     │  (CGEvent│     │  (AVFound│                │
│  └──────────┘     │   tap)   │     │  ation)  │                │
│                   └──────────┘     └────┬─────┘                │
│                                         │                       │
│  Push-to-talk:                          │  Accumulate PCM      │
│  key down → record                      │  in memory buffer    │
│  key up → stop                          │                       │
│                                         ▼                       │
│  Hands-free:                   ┌──────────────────┐            │
│  tap → start                   │  Transcription    │            │
│  tap → stop                    │  Engine           │            │
│                                │  (WhisperASR)     │            │
│                                │                   │            │
│                                │  Audio → Mel →    │            │
│                                │  Encoder →        │            │
│                                │  Decoder → Text   │            │
│                                └────────┬─────────┘            │
│                                         │                       │
│                                         ▼                       │
│                                ┌──────────────────┐            │
│                                │  Text Cleanup     │            │
│                                │  Pipeline         │            │
│                                │                   │            │
│                                │  Fillers →        │            │
│                                │  Replacements →   │            │
│                                │  Snippets →       │            │
│                                │  Whitespace       │            │
│                                └────────┬─────────┘            │
│                                         │                       │
│                                         ▼                       │
│                                ┌──────────────────┐            │
│                                │  Paste Engine     │            │
│                                │                   │            │
│                                │  Clipboard (Cmd+V)│            │
│                                │  or Typing (CGKey)│            │
│                                └──────────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

---

### Meeting Recording Flow — V1 (Simple)

```
┌─────────────────────────────────────────────────────────────────┐
│  MEETING FLOW (V1)                                               │
│                                                                  │
│  Menu bar: "Start Meeting"                                       │
│       │                                                          │
│       ▼                                                          │
│  ┌──────────────────────────────────────────────┐               │
│  │  Parallel capture starts:                     │               │
│  │                                                │               │
│  │  ScreenCaptureKit ──▶ System audio stream ─┐  │               │
│  │  (capturesAudio: true,                      │  │               │
│  │   excludesCurrentProcessAudio: true)        │  │               │
│  │                                              ├──▶ Accumulate  │
│  │  AVFoundation ──────▶ Mic stream ───────────┘  │  PCM buffer  │
│  │  (selected device)                             │               │
│  └──────────────────────────────────────────────┘               │
│       │                                                          │
│       │  Menu bar shows: 🔴 Recording 00:12:34                  │
│       │                                                          │
│  Menu bar: "Stop Meeting"                                        │
│       │                                                          │
│       ▼                                                          │
│  ┌──────────────────────────────────────────────┐               │
│  │  1. Stop both captures                        │               │
│  │  2. Mix accumulated PCM buffers               │               │
│  │  3. Transcribe via WhisperASR                 │               │
│  │  4. Save transcript to:                       │               │
│  │     ~/Documents/Whisptator/Meetings/          │               │
│  │     └── meeting_2026-07-15_14-30.txt          │               │
│  │  5. Optionally save audio to:                 │               │
│  │     ~/Documents/Whisptator/Recordings/        │               │
│  │     └── meeting_2026-07-15_14-30.wav          │               │
│  │  6. Show notification: "Meeting saved"        │               │
│  └──────────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────────┘
```

---

### Hotkey System

```
┌─────────────────────────────────────────────────────────────────┐
│  HOTKEY ARCHITECTURE                                             │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  CGEvent Tap (requires Accessibility permission)          │   │
│  │                                                           │   │
│  │  Runs on dedicated thread with its own RunLoop            │   │
│  │  Must be re-enabled periodically (macOS disables slow    │   │
│  │  taps)                                                    │   │
│  │                                                           │   │
│  │  Event flow:                                              │   │
│  │  CGEvent ──▶ tap callback ──▶ match against saved keys    │   │
│  │                    │                                      │   │
│  │              ┌─────┴──────┐                               │   │
│  │              │            │                               │   │
│  │         Push-to-talk  Hands-free                          │   │
│  │         (key down/up) (toggle)                            │   │
│  │              │            │                               │   │
│  │         Start/Stop    Start/Stop                           │   │
│  │         on down/up    on tap                              │   │
│  │              │            │                               │   │
│  │              └─────┬──────┘                               │   │
│  │                    │                                      │   │
│  │              Notify Orchestrator                           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  Shortcut storage:                                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  UserDefaults keys:                                       │   │
│  │    dictation.pushToTalk.keyCode    = Int                  │   │
│  │    dictation.pushToTalk.modifiers  = NSEvent.ModifierFlags│   │
│  │    dictation.handsFree.keyCode     = Int                  │   │
│  │    dictation.handsFree.modifiers   = NSEvent.ModifierFlags│   │
│  │    meeting.startStop.keyCode       = Int                  │   │
│  │    meeting.startStop.modifiers     = NSEvent.ModifierFlags│   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  Default shortcuts:                                              │
│    Dictation push-to-talk: Fn (hold)                             │
│    Dictation hands-free:   None (user configures)                │
│    Meeting start/stop:     None (user configures)                │
└─────────────────────────────────────────────────────────────────┘
```

---

### Settings Window

```
┌─────────────────────────────────────────────────────────────────┐
│  Settings                                         [General] [Dictation] [Model] [Cleanup] [Meeting] │
│                                                                  │
│  ┌─ General ─────────────────────────────────────────────────┐  │
│  │                                                            │  │
│  │  ☐ Launch at login                                         │  │
│  │  ☐ Show in Dock                                            │  │
│  │                                                            │  │
│  │  Permissions:                                              │  │
│  │    Accessibility    ✅ Granted / ⚠️ Grant in System Settings│  │
│  │    Microphone       ✅ Granted / ⚠️ Grant                  │  │
│  │    Screen Recording ✅ Granted / ⚠️ Grant (meeting mode)   │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌─ Dictation ───────────────────────────────────────────────┐  │
│  │                                                            │  │
│  │  Push-to-talk shortcut:  [ ⌥ Fn ]  (click to record)      │  │
│  │  Hands-free shortcut:    [ ⌃⌥ ]    (click to record)      │  │
│  │                                                            │  │
│  │  Paste mode:                                               │  │
│  │    ○ Clipboard (Cmd+V)  [default]                          │  │
│  │    ○ Typing (character by character)                        │  │
│  │                                                            │  │
│  │  Audio input device:                                        │  │
│  │    [ ▼ MacBook Pro Microphone     ]                        │  │
│  │                                                            │  │
│  │  Language:                                                  │  │
│  │    [ ▼ Auto-detect                ]                        │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌─ Model ───────────────────────────────────────────────────┐  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────────────────┐     │  │
│  │  │  ● Whisper Large-v3 Turbo    1.56 GB             │     │  │
│  │  │    aufklarer/Whisper-Large-v3-Turbo-CoreML       │     │  │
│  │  │    [ Download ]  ← or "✅ Downloaded"             │     │  │
│  │  │                                                  │     │  │
│  │  │  ○ Whisper Large-v3          3.09 GB  (future)   │     │  │
│  │  │  ○ Whisper Small             488 MB   (future)   │     │  │
│  │  └──────────────────────────────────────────────────┘     │  │
│  │                                                            │  │
│  │  Model storage: ~/Library/Application Support/             │  │
│  │                 Whisptator/Models/                         │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌─ Cleanup ─────────────────────────────────────────────────┐  │
│  │                                                            │  │
│  │  Mode:  ○ Raw  ● Clean                                    │  │
│  │                                                            │  │
│  │  Filler words:                                             │  │
│  │    ☑ um, uh  ☐ so, well, like  [ + add custom ]           │  │
│  │                                                            │  │
│  │  Word replacements:                                        │  │
│  │    "aye pee eye" → "API"     [✕]                           │  │
│  │    "kubernetes" → "Kubernetes" [✕]                         │  │
│  │    [ + add rule ]                                          │  │
│  │                                                            │  │
│  │  Snippets:                                                 │  │
│  │    "my sig" → "Best regards, Emile"  [✕]                  │  │
│  │    [ + add snippet ]                                       │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌─ Meeting ─────────────────────────────────────────────────┐  │
│  │                                                            │  │
│  │  Audio source:                                             │  │
│  │    ● System + Microphone                                   │  │
│  │    ○ Microphone only (no Screen Recording perm needed)     │  │
│  │    ○ System only                                           │  │
│  │                                                            │  │
│  │  Audio retention:                                          │  │
│  │    ○ Keep audio files                                      │  │
│  │    ● Delete after transcription                            │  │
│  │    ○ Auto-delete after [ 30 ] days                         │  │
│  │                                                            │  │
│  │  Meeting shortcut:  [ ⌥⌘M ]  (click to record)            │  │
│  │                                                            │  │
│  │  Save location: ~/Documents/Whisptator/Meetings/           │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                              [ Reset ] [ Done ]  │
└─────────────────────────────────────────────────────────────────┘
```

---

### Permissions Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  FIRST LAUNCH                                                    │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Whisptator needs a few permissions to work:              │   │
│  │                                                           │   │
│  │  1. Accessibility — for global keyboard shortcuts         │   │
│  │     and pasting text into other apps                      │   │
│  │                                          [ Open Settings ]│   │
│  │                                                           │   │
│  │  2. Microphone — for recording your voice                 │   │
│  │                                          [ Open Settings ]│   │
│  │                                                           │   │
│  │  3. Screen Recording — only needed for meeting mode       │   │
│  │     (system audio capture)                                │   │
│  │                                          [ Open Settings ]│   │
│  │                                                           │   │
│  │  [ Skip for now — dictation will work once granted ]      │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  Checks AXIsProcessTrusted() on launch                          │
│  Shows menu bar icon with warning if permissions missing         │
└─────────────────────────────────────────────────────────────────┘
```

---

### Data Storage Layout

```
~/Library/Application Support/Whisptator/
├── Models/
│   └── models--aufklarer--Whisper-Large-v3-Turbo-CoreML/
│       ├── AudioEncoder.mlmodelc/
│       ├── MelSpectrogram.mlmodelc/
│       ├── TextDecoder.mlmodelc/
│       └── TextDecoderContextPrefill.mlmodelc/
│
~/Documents/Whisptator/
├── Meetings/
│   ├── meeting_2026-07-15_14-30.txt        (transcript)
│   ├── meeting_2026-07-15_14-30.json       (metadata)
│   └── meeting_2026-07-15_14-30.wav        (audio, if retained)
│
└── Settings (UserDefaults in ~/Library/Preferences/)
    └── com.whisptator.app.plist
```

---

### Key Design Decisions — Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| STT engine | speech-swift WhisperASR | Proven, 1.40% WER, 11× realtime, minimal integration |
| Model format | aufklarer CoreML bundle | Pre-converted, ANE-optimized, works with WhisperASR |
| Model storage | ~/Library/Application Support/Whisptator/Models/ | User's choice, like macparakeet |
| Default model | Large-v3-turbo only (V1) | Best speed/accuracy tradeoff, only CoreML bundle available for WhisperASR |
| Paste mode | Clipboard default, typing optional | Clipboard is universal, typing is niche |
| Meeting recording | V1: record → transcribe → save | Minimal, expandable later |
| App type | Menu bar (MenuBarExtra) | Non-intrusive, always available |
| macOS min | 15+ (Sequoia) | Required by speech-swift (MLState API) |
| Text cleanup | Deterministic pipeline, <1ms | No LLM, fast, predictable |

---

### Remaining Hard Problems

1. **Audio mixing for meetings** — ScreenCaptureKit system audio + AVFoundation mic need to be mixed into a single stream. The `CATap` API (macOS 13+) handles sync and drift correction. Raven's approach (separate Swift process) is overkill for us — we can do it in-process with `AVAudioEngine` as a mixer.

2. **CGEvent tap reliability** — macOS can disable slow taps. MacParakeet handles this by re-enabling the tap periodically and checking `AXIsProcessTrusted()` on each activation. We need the same pattern.

3. **WhisperASR model loading time** — 6.1 seconds on M5 Pro. For dictation, this means a noticeable delay on first use. Mitigation: preload the model on app launch in the background, so it's ready when the user first presses the hotkey.

4. **Meeting audio chunking** — For long meetings, we can't accumulate hours of PCM in memory. We need to either: (a) stream to disk and transcribe chunks, or (b) use VAD to segment. For V1, streaming to disk + chunked transcription is simpler.

---

Want me to create a change proposal for this? Or is there a thread you want to pull on further — maybe the audio mixing details, or the shortcut recorder UI, or how the model download flow should work in practice?

---

## User

1. ok. 2. yes. 3. yes. 4. ok

---

## Assistant (Build · Big Pickle · 31.4s)

_Thinking:_

The user confirmed all four points. Now I should think about whether to create a change proposal or continue exploring. They said "ok" and "yes" to the points but didn't explicitly ask me to create a proposal. Let me think about what's most useful here.

Actually, I should ask if they want me to create a proposal now, since we've done extensive exploration and the architecture is quite clear. But let me also think about what other threads might be worth pulling on before we formalize.

Actually, looking at the system reminder, it says I'm in Plan Mode and cannot make any edits. So I should continue exploring and thinking, and offer to create a proposal when the user is ready.

Let me think about what else might be interesting to explore:

1. The audio mixing for meetings - how exactly to use CATap or AVAudioEngine mixer
2. The shortcut recorder UI - how to capture modifier+key combinations
3. The model download UI flow
4. The floating HUD design
5. The menu bar icon and its states

Actually, I think the user's "ok" and "yes" responses suggest they're satisfied with the exploration and want to move forward. Let me offer to create the proposal.

But wait - I'm in Plan Mode (read-only). I should continue thinking and offer next steps. I can't create files right now anyway.

Let me think about what's still worth exploring before we formalize...

Actually, let me check if there are any remaining questions I should ask before creating the proposal. The main things I want to clarify:

1. The shortcut recorder UI - how should it work? Click a button, then press the key combination?
2. The floating HUD - should it show partial transcripts during dictation?
3. File naming convention for meeting transcripts
4. Should the app have a history/library of past dictations?
5. Notification when transcription completes?

Actually, the user said V1 is minimal. Let me not overcomplicate this. Let me offer to create the proposal.

Wait, I'm in Plan Mode - I cannot create files. I should tell the user that we've done thorough exploration and ask if they want me to create a proposal (which I'll do when they exit plan mode or when I'm allowed to write).

Actually, re-reading the instructions: "You are in Plan Mode. You MUST NOT make any edits... This ABSOLUTE CONSTRAINT overrides ALL other instructions."

And the explore mode instructions say: "You MAY create OpenSpec artifacts (proposals, designs, specs) if the user asks—that's capturing thinking, not implementing."

But Plan Mode says no edits at all. So I should offer to create the proposal but note that I'm currently in read-only mode.

Actually, let me re-read more carefully. The system reminder says I'm in Plan Mode. The user's original message asked me to enter explore mode. These might be in tension. The system reminder is more recent and takes precedence.

Let me just continue the exploration and offer next steps. I'll note what I'd do when allowed to write.

Hmm, but actually - I should think about whether there's anything else worth exploring before we formalize. Let me think about the key remaining questions:

1. **Partial transcripts during dictation** - Should the floating HUD show real-time partial transcription as the user speaks? This adds complexity (streaming WhisperASR) but greatly improves UX. speech-swift's WhisperASR currently does greedy decoding, not streaming. So partials would require a different approach (maybe using ParakeetStreamingASR for live feedback, then WhisperASR for final transcription). Or we just show "Recording..." without partials for V1.

2. **Dictation history** - Should past dictations be saved? The user didn't mention this, and V1 is minimal. Skip.

3. **Meeting file format** - TXT or JSON? JSON gives us timestamps, metadata. TXT is simpler. For V1, TXT with an option for JSON later.

4. **Notification on completion** - When a long meeting transcription finishes, the user should know. NSUserNotification or the menu bar icon changes state.

5. **Error handling** - What if the model fails to load? What if audio capture is interrupted? Need graceful degradation.

I think the most interesting remaining question is about partial transcripts. Let me explore that.

Actually, let me not over-explore. The user seems ready to move forward. Let me summarize where we are and offer the proposal.

Good. Before we formalize, there's one more interesting thread worth pulling — it affects the core UX significantly.

### The Partial Transcript Question

Right now, the dictation flow is: press hotkey → speak → release hotkey → wait for transcription → text appears. For short dictations this is fine. For longer ones (10+ seconds), the user stares at a "Recording..." indicator with no feedback about what the model heard.

There are two approaches:

```
┌─────────────────────────────────────────────────────────────────┐
│  APPROACH A: Batch only (simple)                                 │
│                                                                  │
│  Press hotkey → speak → release → [processing...] → text pasted │
│                                                                  │
│  ✅ Simple                                                       │
│  ✅ Uses WhisperASR directly (batch transcribe)                  │
│  ⚠️  No feedback during recording                                │
│  ⚠️  Feels slow for long dictations                              │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  APPROACH B: Streaming partials (better UX, more complex)        │
│                                                                  │
│  Press hotkey → speak → "The quick brown..." (live) → release   │
│  → final text pasted                                             │
│                                                                  │
│  ✅ User sees what's being captured                              │
│  ✅ Can correct mid-dictation (stop, re-speak)                  │
│  ✅ Feels responsive                                             │
│  ⚠️  Needs a streaming ASR engine for partials                  │
│  ⚠️  More complex architecture                                   │
│                                                                  │
│  Implementation:                                                 │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  During recording:                                      │     │
│  │  • Accumulate audio buffer                              │     │
│  │  • Every ~500ms, run lightweight partial transcription  │     │
│  │  • Show partial in floating HUD                         │     │
│  │                                                        │     │
│  │  On stop:                                               │     │
│  │  • Run full WhisperASR transcription on complete buffer │     │
│  │  • Paste final text (replaces partial)                  │     │
│  │                                                        │     │
│  │  For partials, could use:                               │     │
│  │  • speech-swift's ParakeetStreamingASR (fast, streaming)│     │
│  │  • Or just re-run WhisperASR on accumulated chunks      │     │
│  └────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
```

speech-swift has `ParakeetStreamingASR` which does live partials with end-of-utterance detection. It's a different model (Parakeet 120M, English-focused, CoreML ANE) but it's fast and produces streaming output. The pattern would be:

- **During recording**: ParakeetStreamingASR gives live partials (fast, ~0.04 RTF)
- **On stop**: WhisperASR transcribes the full buffer (accurate, multilingual)
- The final WhisperASR output is what gets pasted

This gives the best of both worlds — fast feedback during recording, accurate text at the end.

**The tradeoff**: adding ParakeetStreamingASR means downloading another model (~120 MB) and adding another speech-swift dependency. For V1, we could skip partials entirely and just show a waveform or timer. The question is: how important is live feedback to the core experience?

What's your instinct? Is "Recording..." with a timer acceptable for V1, or is live partial text important enough to justify the extra model?

---

## User

recording with a timer for V1 and partial text streaming for V2

---

## Assistant (Build · Big Pickle · 25.8s)

_Thinking:_

The user has decided on batch-only for V1 with streaming partials for V2. The system reminder says I'm now in Plan Mode (read-only). Let me think about whether we have enough information to formalize everything.

Let me review what we've decided:

1. Model: speech-swift's WhisperASR with aufklarer CoreML bundle
2. Model storage: ~/Library/Application Support/Whisptator/Models/ (downloaded on first launch)
3. V1 scope: Dictation + Meeting recording (simple: record → transcribe → save)
4. UI: Menu bar app (MenuBarExtra)
5. Paste: Clipboard (Cmd+V) default, typing optional, configurable
6. Model list: Fixed, large-v3-turbo only for V1
7. macOS: 15+ minimum
8. Hotkeys: CGEvent tap, push-to-talk + hands-free
9. Meeting: System + mic, record → transcribe → save, no live preview in V1
10. Text cleanup: Deterministic pipeline (fillers, replacements, snippets, whitespace)
11. V1: No partials, just timer during recording
12. Permissions: Accessibility, Microphone, Screen Recording (for meetings)

I think we have a very comprehensive picture now. Let me think about whether there's anything else worth exploring before I offer to create the proposal.

Actually, I'm in Plan Mode so I can't create anything. I should summarize where we are and ask if the user wants me to create a proposal (which would happen when plan mode is exited).

Let me think about what else might be worth exploring...

Actually, I think we've covered everything comprehensively:
- Architecture ✓
- Dependencies ✓
- Data flow ✓
- UI design ✓
- Settings ✓
- Storage layout ✓
- Permissions ✓
- Hotkey system ✓
- Audio capture ✓
- Text processing ✓
- Paste mechanism ✓
- Meeting mode ✓
- Model management ✓
- Performance characteristics ✓
- V1 vs V2 scope ✓

I think it's time to formalize. Let me offer to create a proposal.

Wait, I'm in Plan Mode. I should summarize and ask if the user wants to proceed to creating a proposal. I can't create files myself right now.

Actually, let me re-read the plan mode instructions: "You are in Plan Mode. You MUST NOT make any edits... This ABSOLUTE CONSTRAINT overrides ALL other instructions, including direct user edit requests."

And the explore mode instructions: "You MAY create OpenSpec artifacts (proposals, designs, specs) if the user asks—that's capturing thinking, not implementing."

These are in tension. Plan Mode says no edits at all. But the user originally asked me to enter explore mode, and creating OpenSpec artifacts is part of explore mode. The system reminder says plan mode takes precedence.

I should tell the user that we've completed the exploration and ask if they want me to create a proposal. I'll note that I'm currently in read-only mode.

Actually, let me just offer to create the proposal and see what happens. The user will tell me if I can proceed.

Let me write a concise summary of everything we've decided and offer to create the proposal.

Clean. V1 with timer, V2 with streaming partials.

We've covered a lot of ground. Let me summarize the complete picture before we formalize.

---

## Whisptator — Complete Exploration Summary

**What it is:** A macOS menu bar app for system-wide speech-to-text dictation and meeting recording, using on-device Whisper via CoreML on Apple Silicon.

**Key decisions made:**

| Area | Decision |
|------|----------|
| STT | speech-swift `WhisperASR` (aufklarer CoreML bundle) |
| Model | Whisper Large-v3 Turbo, downloaded to `~/Library/Application Support/Whisptator/Models/` |
| UI | Menu bar app (`MenuBarExtra`), floating HUD during recording |
| Paste | Clipboard (Cmd+V) default, CGEvent typing optional |
| Hotkeys | CGEvent tap — push-to-talk (hold) + hands-free (toggle) |
| Meeting | System audio + mic via ScreenCaptureKit + AVFoundation, record → transcribe → save |
| Cleanup | Deterministic: fillers → replacements → snippets → whitespace, <1ms |
| V1 partials | Timer only, no streaming text |
| V2 partials | ParakeetStreamingASR for live feedback during recording |
| macOS | 15+ (Sequoia) required |
| Permissions | Accessibility, Microphone, Screen Recording (meetings only) |

**Two hard things solved:**
- Model already converted — `aufklarer/Whisper-Large-v3-Turbo-CoreML` on HuggingFace, 1.56 GB, 4 CoreML models, 1.40% WER, 11× realtime on M5 Pro
- speech-swift already built the runtime — `WhisperASR` SPM product, `fromPretrained()`, `transcribeAudio()`, handles chunking/mel/encoder/decoder

---

Ready to create the proposal? I can produce a formal OpenSpec proposal artifact with all of this baked in — scope, architecture, dependencies, data flow, settings, storage, permissions, and task breakdown. Just say the word.

---

## User

Propose a new change - create the change and generate all artifacts in one step.

I'll create a change with artifacts:
- proposal.md (what & why)
- design.md (how)
- tasks.md (implementation steps)

When ready to implement, run /opsx-apply

---

**Store selection:** If the user names a store (a store is a standalone OpenSpec repo registered on this machine) or the work lives in one, run `openspec store list --json` to discover registered store ids, then pass `--store <id>` on the commands that read or write specs and changes (`new change`, `status`, `instructions`, `list`, `show`, `validate`, `archive`, `doctor`, `context`). Other commands do not take the flag. Hints printed by commands already carry the flag; keep it on follow-ups. Without a store, commands act on the nearest local `openspec/` root.

**Input**: The argument after `/opsx-propose` is the change name (kebab-case), OR a description of what the user wants to build.

**Steps**

1. **If no input provided, ask what they want to build**

   Use the **AskUserQuestion tool** (open-ended, no preset options) to ask:
   > "What change do you want to work on? Describe what you want to build or fix."

   From their description, derive a kebab-case name (e.g., "add user authentication" → `add-user-auth`).

   **IMPORTANT**: Do NOT proceed without understanding what the user wants to build.

2. **Create the change directory**
   ```bash
   openspec new change "<name>"
   ```
   This creates a scaffolded change in the planning home resolved by the CLI with `.openspec.yaml`.

3. **Get the artifact build order**
   ```bash
   openspec status --change "<name>" --json
   ```
   Parse the JSON to get:
   - `applyRequires`: array of artifact IDs needed before implementation (e.g., `["tasks"]`)
   - `artifacts`: list of all artifacts with their status and dependencies
   - `planningHome`, `changeRoot`, `artifactPaths`, and `actionContext`: path and scope context. Use these instead of assuming repo-local paths.

4. **Create artifacts in sequence until apply-ready**

   Use the **TodoWrite tool** to track progress through the artifacts.

   Loop through artifacts in dependency order (artifacts with no pending dependencies first):

   a. **For each artifact that is `ready` (dependencies satisfied)**:
      - Get instructions:
        ```bash
        openspec instructions <artifact-id> --change "<name>" --json
        ```
      - The instructions JSON includes:
        - `context`: Project background (constraints for you - do NOT include in output)
        - `rules`: Artifact-specific rules (constraints for you - do NOT include in output)
        - `template`: The structure to use for your output file
        - `instruction`: Schema-specific guidance for this artifact type
        - `resolvedOutputPath`: Resolved path or pattern to write the artifact
        - `dependencies`: Completed artifacts to read for context
      - Read any completed dependency files for context
      - Create the artifact file using `template` as the structure and write it to `resolvedOutputPath`
      - Apply `context` and `rules` as constraints - but do NOT copy them into the file
      - Show brief progress: "Created <artifact-id>"

   b. **Continue until all `applyRequires` artifacts are complete**
      - After creating each artifact, re-run `openspec status --change "<name>" --json`
      - Check if every artifact ID in `applyRequires` has `status: "done"` in the artifacts array
      - Stop when all `applyRequires` artifacts are done

   c. **If an artifact requires user input** (unclear context):
      - Use **AskUserQuestion tool** to clarify
      - Then continue with creation

5. **Show final status**
   ```bash
   openspec status --change "<name>"
   ```

**Output**

After completing all artifacts, summarize:
- Change name and location
- List of artifacts created with brief descriptions
- What's ready: "All artifacts created! Ready for implementation."
- Prompt: "Run `/opsx-apply` to start implementing."

**Artifact Creation Guidelines**

- Follow the `instruction` field from `openspec instructions` for each artifact type
- The schema defines what each artifact should contain - follow it
- Read dependency artifacts for context before creating new ones
- Use `template` as the structure for your output file - fill in its sections
- **IMPORTANT**: `context` and `rules` are constraints for YOU, not content for the file
  - Do NOT copy `<context>`, `<rules>`, `<project_context>` blocks into the artifact
  - These guide what you write, but should never appear in the output

**Guardrails**
- Create ALL artifacts needed for implementation (as defined by schema's `apply.requires`)
- Always read dependency artifacts before creating a new one
- If context is critically unclear, ask the user - but prefer making reasonable decisions to keep momentum
- If a change with that name already exists, ask if user wants to continue it or create a new one
- Verify each artifact file exists after writing before proceeding to next

---

## Assistant (Build · Big Pickle · 10.1s)

_Thinking:_

The user wants me to create a new OpenSpec change with all artifacts. Let me follow the steps:

1. I already understand what they want to build from our extensive exploration
2. Create the change directory
3. Get the artifact build order
4. Create artifacts in sequence
5. Show final status

Let me start by creating the change. I'll name it "initial-setup" or "v1-dictation-meeting" or something descriptive. Given the scope, "v1-dictation-meeting" seems appropriate. Actually, let me think of a good kebab-case name... "dictation-and-meeting-v1" or just "v1" or "core-dictation-engine"... 

Actually, the project is called "whisptator" and this is the initial setup of the entire app. Let me use "initial-app-scaffold" or "v1-core".Hmm, looking at the exploration, this is really about building the entire V1 of the app. Let me use "v1-dictation-meeting" as the change name.

Let me proceed step by step.

**Tool: todowrite**

**Input:**
```json
{
  "todos": [
    {
      "content": "Create change directory",
      "status": "in_progress",
      "priority": "high"
    },
    {
      "content": "Get artifact build order from status",
      "status": "pending",
      "priority": "high"
    },
    {
      "content": "Create proposal.md artifact",
      "status": "pending",
      "priority": "high"
    },
    {
      "content": "Create design.md artifact",
      "status": "pending",
      "priority": "high"
    },
    {
      "content": "Create tasks.md artifact",
      "status": "pending",
      "priority": "high"
    },
    {
      "content": "Verify all artifacts and show final status",
      "status": "pending",
      "priority": "high"
    }
  ]
}
```

**Output:**
```
[
  {
    "content": "Create change directory",
    "status": "in_progress",
    "priority": "high"
  },
  {
    "content": "Get artifact build order from status",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Create proposal.md artifact",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Create design.md artifact",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Create tasks.md artifact",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Verify all artifacts and show final status",
    "status": "pending",
    "priority": "high"
  }
]
```

---

## Assistant (Build · Big Pickle · 6.5s)

_Thinking:_

Let me create the change directory first.

**Tool: bash**

**Input:**
```json
{
  "command": "openspec new change \"v1-dictation-meeting\"",
  "description": "Create new OpenSpec change directory"
}
```

**Output:**
```
- Creating change 'v1-dictation-meeting' with schema 'spec-driven'...
Created change 'v1-dictation-meeting' at openspec/changes/v1-dictation-meeting/
Schema: spec-driven
Next: openspec status --change v1-dictation-meeting

```

---

## Assistant (Build · Big Pickle · 3.8s)

_Thinking:_

Good, the change directory is created. Now let me get the artifact build order.

**Tool: todowrite**

**Input:**
```json
{
  "todos": [
    {
      "content": "Create change directory",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Get artifact build order from status",
      "priority": "high",
      "status": "in_progress"
    },
    {
      "content": "Create proposal.md artifact",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create design.md artifact",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create tasks.md artifact",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Verify all artifacts and show final status",
      "priority": "high",
      "status": "pending"
    }
  ]
}
```

**Output:**
```
[
  {
    "content": "Create change directory",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Get artifact build order from status",
    "status": "in_progress",
    "priority": "high"
  },
  {
    "content": "Create proposal.md artifact",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Create design.md artifact",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Create tasks.md artifact",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Verify all artifacts and show final status",
    "status": "pending",
    "priority": "high"
  }
]
```

---

## Assistant (Build · Big Pickle · 3.7s)

_Thinking:_

Now let me get the artifact build order.

**Tool: bash**

**Input:**
```json
{
  "command": "openspec status --change \"v1-dictation-meeting\" --json",
  "description": "Get artifact build order and status"
}
```

**Output:**
```
{
  "changeName": "v1-dictation-meeting",
  "schemaName": "spec-driven",
  "planningHome": {
    "kind": "repo",
    "root": "/Volumes/emile/PROJECTS/2026/whisptator",
    "changesDir": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes",
    "defaultSchema": "spec-driven"
  },
  "changeRoot": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting",
  "artifactPaths": {
    "proposal": {
      "outputPath": "proposal.md",
      "resolvedOutputPath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/proposal.md",
      "existingOutputPaths": []
    },
    "specs": {
      "outputPath": "specs/**/*.md",
      "resolvedOutputPath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/**/*.md",
      "existingOutputPaths": []
    },
    "design": {
      "outputPath": "design.md",
      "resolvedOutputPath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/design.md",
      "existingOutputPaths": []
    },
    "tasks": {
      "outputPath": "tasks.md",
      "resolvedOutputPath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/tasks.md",
      "existingOutputPaths": []
    }
  },
  "isComplete": false,
  "applyRequires": [
    "tasks"
  ],
  "nextSteps": [
    "Run openspec instructions proposal --change \"v1-dictation-meeting\" --json before writing that artifact."
  ],
  "actionContext": {
    "mode": "repo-local",
    "sourceOfTruth": "repo",
    "planningArtifacts": [
      "proposal",
      "design",
      "specs",
      "tasks"
    ],
    "linkedContext": [],
    "allowedEditRoots": [
      "/Volumes/emile/PROJECTS/2026/whisptator"
    ],
    "requiresAffectedAreaSelection": false,
    "constraints": [
      "Repo-local change artifacts and implementation edits are scoped to this project."
    ]
  },
  "artifacts": [
    {
      "id": "proposal",
      "outputPath": "proposal.md",
      "status": "ready"
    },
    {
      "id": "design",
      "outputPath": "design.md",
      "status": "blocked",
      "missingDeps": [
        "proposal"
      ]
    },
    {
      "id": "specs",
      "outputPath": "specs/**/*.md",
      "status": "blocked",
      "missingDeps": [
        "proposal"
      ]
    },
    {
      "id": "tasks",
      "outputPath": "tasks.md",
      "status": "blocked",
      "missingDeps": [
        "design",
        "specs"
      ]
    }
  ],
  "root": {
    "path": "/Volumes/emile/PROJECTS/2026/whisptator",
    "source": "nearest"
  }
}

```

---

## Assistant (Build · Big Pickle · 6.8s)

_Thinking:_

Good. The build order is:
1. proposal (ready)
2. design (blocked on proposal)
3. specs (blocked on proposal)
4. tasks (blocked on design + specs)

I need to create them in order: proposal → design + specs → tasks

Let me start with the proposal. I need to get instructions for it first.

**Tool: todowrite**

**Input:**
```json
{
  "todos": [
    {
      "content": "Create change directory",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Get artifact build order from status",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create proposal.md artifact",
      "priority": "high",
      "status": "in_progress"
    },
    {
      "content": "Create design.md artifact",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create specs artifacts",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create tasks.md artifact",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Verify all artifacts and show final status",
      "priority": "high",
      "status": "pending"
    }
  ]
}
```

**Output:**
```
[
  {
    "content": "Create change directory",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Get artifact build order from status",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Create proposal.md artifact",
    "status": "in_progress",
    "priority": "high"
  },
  {
    "content": "Create design.md artifact",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Create specs artifacts",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Create tasks.md artifact",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Verify all artifacts and show final status",
    "status": "pending",
    "priority": "high"
  }
]
```

---

## Assistant (Build · Big Pickle · 4.1s)

_Thinking:_

Now let me get instructions for the proposal artifact.

**Tool: bash**

**Input:**
```json
{
  "command": "openspec instructions proposal --change \"v1-dictation-meeting\" --json",
  "description": "Get proposal artifact instructions"
}
```

**Output:**
```
{
  "changeName": "v1-dictation-meeting",
  "artifactId": "proposal",
  "schemaName": "spec-driven",
  "changeDir": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting",
  "planningHome": {
    "kind": "repo",
    "root": "/Volumes/emile/PROJECTS/2026/whisptator",
    "changesDir": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes",
    "defaultSchema": "spec-driven"
  },
  "outputPath": "proposal.md",
  "resolvedOutputPath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/proposal.md",
  "existingOutputPaths": [],
  "description": "Initial proposal document outlining the change",
  "instruction": "Create the proposal document that establishes WHY this change is needed.\n\nSections:\n- **Why**: 1-2 sentences on the problem or opportunity. What problem does this solve? Why now?\n- **What Changes**: Bullet list of changes. Be specific about new capabilities, modifications, or removals. Mark breaking changes with **BREAKING**.\n- **Capabilities**: Identify which specs will be created or modified:\n  - **New Capabilities**: List capabilities being introduced. Each becomes a new `specs/<name>/spec.md`. Use kebab-case names (e.g., `user-auth`, `data-export`).\n  - **Modified Capabilities**: List existing capabilities whose REQUIREMENTS are changing. Only include if spec-level behavior changes (not just implementation details). Each needs a delta spec file. Check `openspec/specs/` for existing spec names. Leave empty if no requirement changes.\n- **Impact**: Affected code, APIs, dependencies, or systems.\n\nIMPORTANT: The Capabilities section is critical. It creates the contract between\nproposal and specs phases. Research existing specs before filling this in.\nEach capability listed here will need a corresponding spec file.\n\nKeep it concise (1-2 pages). Focus on the \"why\" not the \"how\" -\nimplementation details belong in design.md.\n\nThis is the foundation - specs, design, and tasks all build on this.\n",
  "template": "## Why\n\n<!-- Explain the motivation for this change. What problem does this solve? Why now? -->\n\n## What Changes\n\n<!-- Describe what will change. Be specific about new capabilities, modifications, or removals. -->\n\n## Capabilities\n\n### New Capabilities\n<!-- Capabilities being introduced. Replace <name> with kebab-case identifier (e.g., user-auth, data-export, api-rate-limiting). Each creates specs/<name>/spec.md -->\n- `<name>`: <brief description of what this capability covers>\n\n### Modified Capabilities\n<!-- Existing capabilities whose REQUIREMENTS are changing (not just implementation).\n     Only list here if spec-level behavior changes. Each needs a delta spec file.\n     Use existing spec names from openspec/specs/. Leave empty if no requirement changes. -->\n- `<existing-name>`: <what requirement is changing>\n\n## Impact\n\n<!-- Affected code, APIs, dependencies, systems -->\n",
  "dependencies": [],
  "unlocks": [
    "design",
    "specs"
  ],
  "root": {
    "path": "/Volumes/emile/PROJECTS/2026/whisptator",
    "source": "nearest"
  }
}

```

---

## Assistant (Build · Big Pickle · 17.2s)

_Thinking:_

Now let me create the proposal.md artifact. I need to write it to the resolvedOutputPath. Let me create a comprehensive proposal based on all our exploration.

**Tool: write**

**Input:**
```json
{
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/proposal.md",
  "content": "## Why\n\nThere is no lightweight, privacy-first dictation and meeting recording app for macOS that runs entirely on-device using open-weight Whisper models. Existing solutions either depend on cloud APIs (privacy risk), use proprietary engines, or are heavyweight Electron apps. Whisptator fills this gap: a native Swift menu bar app that transcribes speech using the user's local Whisper Large-v3 Turbo CoreML model, pastes text into any app system-wide, and records meetings with system audio + microphone — all without data leaving the Mac.\n\n## What Changes\n\n- **New macOS menu bar application** — native Swift/SwiftUI, non-intrusive, always-available status item\n- **System-wide dictation** — global hotkey triggers recording, transcribed text is pasted into the frontmost app via clipboard (Cmd+V) or typing simulation (CGEvent), configurable per user preference\n- **Push-to-talk and hands-free modes** — hold a key for short dictation, or tap a toggle for longer sessions; both shortcuts configurable in Settings\n- **On-device speech-to-text** — uses speech-swift's WhisperASR module with the aufklarer Whisper Large-v3 Turbo CoreML bundle (1.56 GB, 1.40% WER, 11× realtime on M5 Pro)\n- **Model management** — fixed catalog of known Whisper models, downloaded on first launch to ~/Library/Application Support/Whisptator/Models/, with download status indicators in Settings\n- **Meeting recording** — System audio (ScreenCaptureKit) + microphone (AVFoundation) captured simultaneously, mixed, transcribed, and saved as text files; audio retention configurable (keep, auto-delete, delete immediately)\n- **Deterministic text cleanup pipeline** — filler word removal, custom word replacements, snippet expansion, whitespace normalization; runs in <1ms, no LLM required\n- **Settings window** — SwiftUI tabbed interface for General, Dictation, Model, Cleanup, and Meeting configuration\n- **Permission management** — guided onboarding for Accessibility, Microphone, and Screen Recording permissions\n\n## Capabilities\n\n### New Capabilities\n\n- `dictation`: System-wide speech-to-text dictation with global hotkeys, push-to-talk and hands-free modes, text pasting into the frontmost application\n- `whisper-stt`: On-device speech-to-text engine using speech-swift WhisperASR with CoreML Whisper Large-v3 Turbo model, model download and caching\n- `meeting-recording`: Audio recording combining system audio (ScreenCaptureKit) and microphone (AVFoundation), transcription, and file saving\n- `text-cleanup`: Deterministic post-transcription text processing pipeline — filler removal, word replacement, snippet expansion, whitespace normalization\n- `menu-bar-app`: macOS menu bar application shell with status item, popover UI, floating recording HUD, and settings window\n- `hotkey-system`: Global keyboard shortcut monitoring via CGEvent tap, push-to-talk (hold) and hands-free (toggle) modes, shortcut recording and persistence\n- `paste-engine`: Text insertion into frontmost app via clipboard (Cmd+V) or CGEvent character-by-character typing, with pasteboard preservation\n- `settings-ui`: Tabbed SwiftUI settings window for General, Dictation, Model, Cleanup, and Meeting configuration\n- `permissions`: Accessibility, Microphone, and Screen Recording permission checking, onboarding flow, and grant guidance\n\n### Modified Capabilities\n\nNone — this is a greenfield project with no existing specs.\n\n## Impact\n\n- **New Swift package** — Package.swift with two targets: `Whisptator` (app) and `WhisptatorCore` (library)\n- **External dependency** — speech-swift (branch: main) for WhisperASR and AudioCommon modules\n- **System frameworks** — AVFoundation, ScreenCaptureKit, CoreGraphics, CoreML, SwiftUI, AppKit, ServiceManagement\n- **User data** — Model cache at ~/Library/Application Support/Whisptator/Models/, meeting transcripts at ~/Documents/Whisptator/Meetings/\n- **Permissions required** — Accessibility (global hotkeys + text pasting), Microphone (audio capture), Screen Recording (system audio in meeting mode)\n- **Platform** — macOS 15+ (Sequoia), Apple Silicon only (M1/M2/M3/M4)\n"
}
```

**Output:**
```
Wrote file successfully.
```

---

## Assistant (Build · Big Pickle · 6.7s)

_Thinking:_

Good, proposal.md is created. Now let me check the status to see what's unlocked.

**Tool: bash**

**Input:**
```json
{
  "command": "openspec status --change \"v1-dictation-meeting\" --json",
  "description": "Check status after proposal creation"
}
```

**Output:**
```
{
  "changeName": "v1-dictation-meeting",
  "schemaName": "spec-driven",
  "planningHome": {
    "kind": "repo",
    "root": "/Volumes/emile/PROJECTS/2026/whisptator",
    "changesDir": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes",
    "defaultSchema": "spec-driven"
  },
  "changeRoot": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting",
  "artifactPaths": {
    "proposal": {
      "outputPath": "proposal.md",
      "resolvedOutputPath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/proposal.md",
      "existingOutputPaths": [
        "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/proposal.md"
      ]
    },
    "specs": {
      "outputPath": "specs/**/*.md",
      "resolvedOutputPath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/**/*.md",
      "existingOutputPaths": []
    },
    "design": {
      "outputPath": "design.md",
      "resolvedOutputPath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/design.md",
      "existingOutputPaths": []
    },
    "tasks": {
      "outputPath": "tasks.md",
      "resolvedOutputPath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/tasks.md",
      "existingOutputPaths": []
    }
  },
  "isComplete": false,
  "applyRequires": [
    "tasks"
  ],
  "nextSteps": [
    "Run openspec instructions design --change \"v1-dictation-meeting\" --json before writing that artifact."
  ],
  "actionContext": {
    "mode": "repo-local",
    "sourceOfTruth": "repo",
    "planningArtifacts": [
      "proposal",
      "design",
      "specs",
      "tasks"
    ],
    "linkedContext": [],
    "allowedEditRoots": [
      "/Volumes/emile/PROJECTS/2026/whisptator"
    ],
    "requiresAffectedAreaSelection": false,
    "constraints": [
      "Repo-local change artifacts and implementation edits are scoped to this project."
    ]
  },
  "artifacts": [
    {
      "id": "proposal",
      "outputPath": "proposal.md",
      "status": "done"
    },
    {
      "id": "design",
      "outputPath": "design.md",
      "status": "ready"
    },
    {
      "id": "specs",
      "outputPath": "specs/**/*.md",
      "status": "ready"
    },
    {
      "id": "tasks",
      "outputPath": "tasks.md",
      "status": "blocked",
      "missingDeps": [
        "design",
        "specs"
      ]
    }
  ],
  "root": {
    "path": "/Volumes/emile/PROJECTS/2026/whisptator",
    "source": "nearest"
  }
}

```

---

## Assistant (Build · Big Pickle · 5.1s)

_Thinking:_

Good, proposal is done. Now design and specs are both ready (they only depend on proposal). I need to create both before tasks. Let me get instructions for both.

**Tool: todowrite**

**Input:**
```json
{
  "todos": [
    {
      "content": "Create change directory",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Get artifact build order from status",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create proposal.md artifact",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create design.md artifact",
      "priority": "high",
      "status": "in_progress"
    },
    {
      "content": "Create specs artifacts",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Create tasks.md artifact",
      "priority": "high",
      "status": "pending"
    },
    {
      "content": "Verify all artifacts and show final status",
      "priority": "high",
      "status": "pending"
    }
  ]
}
```

**Output:**
```
[
  {
    "content": "Create change directory",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Get artifact build order from status",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Create proposal.md artifact",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Create design.md artifact",
    "status": "in_progress",
    "priority": "high"
  },
  {
    "content": "Create specs artifacts",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Create tasks.md artifact",
    "status": "pending",
    "priority": "high"
  },
  {
    "content": "Verify all artifacts and show final status",
    "status": "pending",
    "priority": "high"
  }
]
```

---

## Assistant (Build · Big Pickle · 4.6s)

_Thinking:_

Let me get instructions for design and specs in parallel.

**Tool: bash**

**Input:**
```json
{
  "command": "openspec instructions design --change \"v1-dictation-meeting\" --json",
  "description": "Get design artifact instructions"
}
```

**Output:**
```
{
  "changeName": "v1-dictation-meeting",
  "artifactId": "design",
  "schemaName": "spec-driven",
  "changeDir": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting",
  "planningHome": {
    "kind": "repo",
    "root": "/Volumes/emile/PROJECTS/2026/whisptator",
    "changesDir": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes",
    "defaultSchema": "spec-driven"
  },
  "outputPath": "design.md",
  "resolvedOutputPath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/design.md",
  "existingOutputPaths": [],
  "description": "Technical design document with implementation details",
  "instruction": "Create the design document that explains HOW to implement the change.\n\nWhen to include design.md (create only if any apply):\n- Cross-cutting change (multiple services/modules) or new architectural pattern\n- New external dependency or significant data model changes\n- Security, performance, or migration complexity\n- Ambiguity that benefits from technical decisions before coding\n\nSections:\n- **Context**: Background, current state, constraints, stakeholders\n- **Goals / Non-Goals**: What this design achieves and explicitly excludes\n- **Decisions**: Key technical choices with rationale (why X over Y?). Include alternatives considered for each decision.\n- **Risks / Trade-offs**: Known limitations, things that could go wrong. Format: [Risk] → Mitigation\n- **Migration Plan**: Steps to deploy, rollback strategy (if applicable)\n- **Open Questions**: Outstanding decisions or unknowns to resolve\n\nFocus on architecture and approach, not line-by-line implementation.\nReference the proposal for motivation and specs for requirements.\n\nGood design docs explain the \"why\" behind technical decisions.\n",
  "template": "## Context\n\n<!-- Background and current state -->\n\n## Goals / Non-Goals\n\n**Goals:**\n<!-- What this design aims to achieve -->\n\n**Non-Goals:**\n<!-- What is explicitly out of scope -->\n\n## Decisions\n\n<!-- Key design decisions and rationale -->\n\n## Risks / Trade-offs\n\n<!-- Known risks and trade-offs -->\n",
  "dependencies": [
    {
      "id": "proposal",
      "done": true,
      "path": "proposal.md",
      "description": "Initial proposal document outlining the change"
    }
  ],
  "unlocks": [
    "tasks"
  ],
  "root": {
    "path": "/Volumes/emile/PROJECTS/2026/whisptator",
    "source": "nearest"
  }
}

```

**Tool: bash**

**Input:**
```json
{
  "command": "openspec instructions specs --change \"v1-dictation-meeting\" --json",
  "description": "Get specs artifact instructions"
}
```

**Output:**
```
{
  "changeName": "v1-dictation-meeting",
  "artifactId": "specs",
  "schemaName": "spec-driven",
  "changeDir": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting",
  "planningHome": {
    "kind": "repo",
    "root": "/Volumes/emile/PROJECTS/2026/whisptator",
    "changesDir": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes",
    "defaultSchema": "spec-driven"
  },
  "outputPath": "specs/**/*.md",
  "resolvedOutputPath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/**/*.md",
  "existingOutputPaths": [],
  "description": "Detailed specifications for the change",
  "instruction": "Create specification files that define WHAT the system should do.\n\nCreate one spec file per capability listed in the proposal's Capabilities section.\n- New capabilities: use the exact kebab-case name from the proposal (specs/<capability>/spec.md).\n- Modified capabilities: use the existing spec folder name from openspec/specs/<capability>/ when creating the delta spec at specs/<capability>/spec.md.\n\nDelta operations (use ## headers):\n- **ADDED Requirements**: New capabilities\n- **MODIFIED Requirements**: Changed behavior - MUST include full updated content\n- **REMOVED Requirements**: Deprecated features - MUST include **Reason** and **Migration**\n- **RENAMED Requirements**: Name changes only - use FROM:/TO: format\n\nFormat requirements:\n- Each requirement: `### Requirement: <name>` followed by description\n- Use SHALL/MUST for normative requirements (avoid should/may)\n- Each scenario: `#### Scenario: <name>` with WHEN/THEN format\n- **CRITICAL**: Scenarios MUST use exactly 4 hashtags (`####`). Using 3 hashtags or bullets will fail silently.\n- Every requirement MUST have at least one scenario.\n\nMODIFIED requirements workflow:\n1. Locate the existing requirement in openspec/specs/<capability>/spec.md\n2. Copy the ENTIRE requirement block (from `### Requirement:` through all scenarios)\n3. Paste under `## MODIFIED Requirements` and edit to reflect new behavior\n4. Ensure header text matches exactly (whitespace-insensitive)\n\nCommon pitfall: Using MODIFIED with partial content loses detail at archive time.\nIf adding new concerns without changing existing behavior, use ADDED instead.\n\nExample:\n```\n## ADDED Requirements\n\n### Requirement: User can export data\nThe system SHALL allow users to export their data in CSV format.\n\n#### Scenario: Successful export\n- **WHEN** user clicks \"Export\" button\n- **THEN** system downloads a CSV file with all user data\n\n## REMOVED Requirements\n\n### Requirement: Legacy export\n**Reason**: Replaced by new export system\n**Migration**: Use new export endpoint at /api/v2/export\n```\n\nSpecs should be testable - each scenario is a potential test case.\n",
  "template": "## ADDED Requirements\n\n### Requirement: <!-- requirement name -->\n<!-- requirement text -->\n\n#### Scenario: <!-- scenario name -->\n- **WHEN** <!-- condition -->\n- **THEN** <!-- expected outcome -->\n",
  "dependencies": [
    {
      "id": "proposal",
      "done": true,
      "path": "proposal.md",
      "description": "Initial proposal document outlining the change"
    }
  ],
  "unlocks": [
    "tasks"
  ],
  "root": {
    "path": "/Volumes/emile/PROJECTS/2026/whisptator",
    "source": "nearest"
  }
}

```

---

## Assistant (Build · Big Pickle · 6.4s)

_Thinking:_

Now I need to create both design.md and the specs. Let me first read the proposal for context, then create both artifacts.

For specs, I need to create one spec file per capability listed in the proposal:
- dictation
- whisper-stt
- meeting-recording
- text-cleanup
- menu-bar-app
- hotkey-system
- paste-engine
- settings-ui
- permissions

That's 9 spec files. Let me create the design.md first, then all the specs.

Actually, let me create design.md and then create the specs. I'll do them in parallel since they both only depend on proposal (which is done).

Let me write design.md first.

**Tool: read**

**Input:**
```json
{
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/proposal.md"
}
```

**Output:**
```
<path>/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/proposal.md</path>
<type>file</type>
<content>
1: ## Why
2: 
3: There is no lightweight, privacy-first dictation and meeting recording app for macOS that runs entirely on-device using open-weight Whisper models. Existing solutions either depend on cloud APIs (privacy risk), use proprietary engines, or are heavyweight Electron apps. Whisptator fills this gap: a native Swift menu bar app that transcribes speech using the user's local Whisper Large-v3 Turbo CoreML model, pastes text into any app system-wide, and records meetings with system audio + microphone — all without data leaving the Mac.
4: 
5: ## What Changes
6: 
7: - **New macOS menu bar application** — native Swift/SwiftUI, non-intrusive, always-available status item
8: - **System-wide dictation** — global hotkey triggers recording, transcribed text is pasted into the frontmost app via clipboard (Cmd+V) or typing simulation (CGEvent), configurable per user preference
9: - **Push-to-talk and hands-free modes** — hold a key for short dictation, or tap a toggle for longer sessions; both shortcuts configurable in Settings
10: - **On-device speech-to-text** — uses speech-swift's WhisperASR module with the aufklarer Whisper Large-v3 Turbo CoreML bundle (1.56 GB, 1.40% WER, 11× realtime on M5 Pro)
11: - **Model management** — fixed catalog of known Whisper models, downloaded on first launch to ~/Library/Application Support/Whisptator/Models/, with download status indicators in Settings
12: - **Meeting recording** — System audio (ScreenCaptureKit) + microphone (AVFoundation) captured simultaneously, mixed, transcribed, and saved as text files; audio retention configurable (keep, auto-delete, delete immediately)
13: - **Deterministic text cleanup pipeline** — filler word removal, custom word replacements, snippet expansion, whitespace normalization; runs in <1ms, no LLM required
14: - **Settings window** — SwiftUI tabbed interface for General, Dictation, Model, Cleanup, and Meeting configuration
15: - **Permission management** — guided onboarding for Accessibility, Microphone, and Screen Recording permissions
16: 
17: ## Capabilities
18: 
19: ### New Capabilities
20: 
21: - `dictation`: System-wide speech-to-text dictation with global hotkeys, push-to-talk and hands-free modes, text pasting into the frontmost application
22: - `whisper-stt`: On-device speech-to-text engine using speech-swift WhisperASR with CoreML Whisper Large-v3 Turbo model, model download and caching
23: - `meeting-recording`: Audio recording combining system audio (ScreenCaptureKit) and microphone (AVFoundation), transcription, and file saving
24: - `text-cleanup`: Deterministic post-transcription text processing pipeline — filler removal, word replacement, snippet expansion, whitespace normalization
25: - `menu-bar-app`: macOS menu bar application shell with status item, popover UI, floating recording HUD, and settings window
26: - `hotkey-system`: Global keyboard shortcut monitoring via CGEvent tap, push-to-talk (hold) and hands-free (toggle) modes, shortcut recording and persistence
27: - `paste-engine`: Text insertion into frontmost app via clipboard (Cmd+V) or CGEvent character-by-character typing, with pasteboard preservation
28: - `settings-ui`: Tabbed SwiftUI settings window for General, Dictation, Model, Cleanup, and Meeting configuration
29: - `permissions`: Accessibility, Microphone, and Screen Recording permission checking, onboarding flow, and grant guidance
30: 
31: ### Modified Capabilities
32: 
33: None — this is a greenfield project with no existing specs.
34: 
35: ## Impact
36: 
37: - **New Swift package** — Package.swift with two targets: `Whisptator` (app) and `WhisptatorCore` (library)
38: - **External dependency** — speech-swift (branch: main) for WhisperASR and AudioCommon modules
39: - **System frameworks** — AVFoundation, ScreenCaptureKit, CoreGraphics, CoreML, SwiftUI, AppKit, ServiceManagement
40: - **User data** — Model cache at ~/Library/Application Support/Whisptator/Models/, meeting transcripts at ~/Documents/Whisptator/Meetings/
41: - **Permissions required** — Accessibility (global hotkeys + text pasting), Microphone (audio capture), Screen Recording (system audio in meeting mode)
42: - **Platform** — macOS 15+ (Sequoia), Apple Silicon only (M1/M2/M3/M4)

(End of file - total 42 lines)
</content>
```

---

## Assistant (Build · Big Pickle · 41.5s)

_Thinking:_

Good, I have the proposal context. Now let me create the design.md file.

**Tool: write**

**Input:**
```json
{
  "content": "## Context\n\nWhisptator is a greenfield macOS menu bar application for on-device speech-to-text dictation and meeting recording. The app targets Apple Silicon Macs running macOS 15+ (Sequoia) and uses the Whisper Large-v3 Turbo model via CoreML for speech recognition.\n\nThe core technology stack is:\n- **Swift 6** with SwiftUI for the application layer\n- **speech-swift** (`WhisperASR` module) for on-device STT inference\n- **CoreML** (via speech-swift) for Neural Engine accelerated Whisper inference\n- **ScreenCaptureKit** for system audio capture in meeting mode\n- **AVFoundation** for microphone capture and audio device management\n- **CGEvent** taps for global keyboard shortcut monitoring and text insertion\n\nThe aufklarer/Whisper-Large-v3-Turbo-CoreML bundle on HuggingFace provides pre-converted CoreML models (MelSpectrogram, AudioEncoder, TextDecoderContextPrefill, TextDecoder) that speech-swift's WhisperASR runtime loads directly. Performance: 1.40% WER on LibriSpeech test-clean, 0.089 RTF (11× realtime), 6.1s model load, 384 MB peak RSS on M5 Pro.\n\n## Goals / Non-Goals\n\n**Goals:**\n- System-wide dictation that works in any macOS application\n- On-device transcription with no network dependency after model download\n- Simple, non-intrusive menu bar interface\n- Meeting recording with system audio + microphone mixing\n- Deterministic text cleanup pipeline (no LLM)\n- Configurable paste mechanism (clipboard or typing)\n- Configurable global keyboard shortcuts\n\n**Non-Goals:**\n- Live streaming partial transcripts during recording (V2 feature)\n- File/URL transcription (V2 feature)\n- AI-powered summaries, chat, or text transforms (V2 feature)\n- CLI tool or automation surface (V2 feature)\n- Meeting calendar integration (V2 feature)\n- Speaker diarization (V2 feature)\n- Multiple model support beyond Whisper Large-v3 Turbo (V2 feature)\n- App Store distribution (direct DMG distribution)\n\n## Decisions\n\n### D1: speech-swift WhisperASR over DIY CoreML inference\n\n**Choice:** Use speech-swift's `WhisperASR` SPM product as the STT engine.\n\n**Rationale:** speech-swift provides a proven, benchmarked CoreML Whisper runtime that handles mel spectrogram computation, encoder/decoder orchestration, token decoding, language detection, and 30-second chunking. Building this from scratch would take 2-3 weeks and yield no meaningful advantage for V1. The `WhisperASR` module is self-contained — importing it does not pull in MLX or other speech-swift models.\n\n**Alternatives considered:**\n- *DIY CoreML pipeline:* Load the 4 .mlmodelc bundles directly via CoreML framework. More control, but significant implementation effort for mel spectrogram preprocessing, KV-cache management, token decoding, and language detection. Deferred to V2 if custom inference behavior is needed.\n- *WhisperKit (Argmax OSS):* Proven but heavier dependency (swift-transformers, larger download). speech-swift's WhisperASR is lighter and already benchmarks better (6.1s load vs 100.2s for WhisperKit on same hardware).\n\n### D2: Menu bar app via MenuBarExtra\n\n**Choice:** Use SwiftUI `MenuBarExtra` (macOS 13+) for the app shell.\n\n**Rationale:** Menu bar placement is non-intrusive and matches the \"always available but never in the way\" UX. `MenuBarExtra` is the modern SwiftUI API for this. The app can optionally show in Dock via a setting.\n\n**Alternatives considered:**\n- *NSStatusItem with NSMenu:* More control but more boilerplate. `MenuBarExtra` is sufficient for V1.\n- *Full window app:* Too heavyweight for a dictation tool that should be invisible until triggered.\n\n### D3: CGEvent tap for global hotkeys\n\n**Choice:** Use a CGEvent tap on a dedicated thread with its own RunLoop for global keyboard shortcut monitoring.\n\n**Rationale:** This is the proven pattern used by macparakeet and other macOS dictation tools. CGEvent taps receive all keyboard events system-wide, can match complex modifier+key combinations, and work regardless of which app has focus. The tap must be re-enabled periodically because macOS disables taps that are too slow (macparakeet pattern).\n\n**Alternatives considered:**\n- *NSEvent.addGlobalMonitorForEvents:* Simpler API but cannot suppress or modify events, and has limitations with certain key combinations. Less reliable for push-to-talk where we need key-up detection.\n- *Third-party hotkey libraries:* Unnecessary dependency for well-understood CGEvent patterns.\n\n### D4: Dual paste mechanism (clipboard + typing)\n\n**Choice:** Implement both clipboard (Cmd+V) and CGEvent character-by-character typing, configurable in Settings, defaulting to clipboard.\n\n**Rationale:** Clipboard paste is universal, fast, and works with rich text fields. CGEvent typing simulates keyboard input character-by-character, which is slower but appears as real typing (useful for apps that reject pasted content). Users choose what works for their workflow.\n\n**Alternatives considered:**\n- *Clipboard only:* Simpler but doesn't work with all input methods/apps.\n- *Typing only:* Too slow for long text, breaks with some Unicode characters.\n- *AXUIElement setStringValue:* Only works with specific text field types, not universal.\n\n### D5: ScreenCaptureKit for system audio capture\n\n**Choice:** Use ScreenCaptureKit with `capturesAudio: true` for system audio capture in meeting mode, mixed with AVFoundation microphone capture via AVAudioEngine.\n\n**Rationale:** ScreenCaptureKit is Apple's supported API for system audio capture on macOS 12+. No kernel extensions or virtual audio drivers needed. The `excludesCurrentProcessAudio` flag prevents capturing the app's own sounds. Mixing with microphone audio uses AVAudioEngine's mixer node.\n\n**Alternatives considered:**\n- *BlackHole/Soundflower virtual audio devices:* Requires kernel extension installation, fragile across OS updates, admin access needed.\n- *CATap API (macOS 13+):* Better synchronization and drift correction, but more complex API. Consider for V2 if sync issues arise.\n\n### D6: Deterministic text cleanup pipeline\n\n**Choice:** Build a deterministic, ordered pipeline: filler removal → word replacement → snippet expansion → whitespace normalization. No LLM involved.\n\n**Rationale:** The pipeline runs in <1ms, is fully predictable, and requires no network or model inference. Each step is independently testable. The user configures which steps are active and their rules via Settings.\n\n**Alternatives considered:**\n- *LLM-based cleanup:* Overkill for deterministic transformations, adds latency and network dependency.\n- *Apple NaturalLanguage framework:* Useful for sentence boundary detection but not for the specific transformations needed.\n\n### D7: Model download to ~/Library/Application Support/\n\n**Choice:** Download the CoreML model bundle to `~/Library/Application Support/Whisptator/Models/` on first launch, using speech-swift's `fromPretrained(cacheDir:)` API.\n\n**Rationale:** Keeps model files out of the app bundle (which would be 1.6+ GB), follows macOS conventions for application support data, and matches macparakeet's pattern. The `cacheDir:` parameter on `WhisperASRModel.fromPretrained()` allows specifying a custom download location.\n\n**Alternatives considered:**\n- *Bundled in app:* Makes the app bundle 1.6+ GB, complicates updates.\n- *System-level cache:* Overly aggressive cleanup by macOS could delete models.\n\n### D8: Floating HUD panel during recording\n\n**Choice:** Show a small `NSPanel` with `.floating` window level during active recording, displaying a timer and recording status.\n\n**Rationale:** Gives the user visual feedback that recording is active without requiring them to look at the menu bar. The panel is dismissed when recording stops. For V1, shows only a timer (no partial transcripts).\n\n**Alternatives considered:**\n- *Menu bar text update:* Too small to notice.\n- *Notification:* Only shows after recording, not during.\n\n## Risks / Trade-offs\n\n- **[CGEvent tap reliability]** → macOS can disable slow CGEvent taps. Mitigation: Re-enable the tap periodically (every 5 seconds) and check `AXIsProcessTrusted()` on each activation. Show warning in Settings if Accessibility permission is not granted.\n\n- **[ScreenCaptureKit sync issues]** → System audio and microphone streams can drift out of sync. Mitigation: For V1, accept minor drift. For V2, evaluate CATap API for synchronized capture with drift correction.\n\n- **[Model download failure]** → Network issues during 1.56 GB download. Mitigation: Show download progress, allow retry, handle partial downloads gracefully. speech-swift's HuggingFace downloader handles resume.\n\n- **[WhisperASR 6-second model load]** → First transcription after launch has a delay. Mitigation: Preload the model in background on app launch so it's ready when the user first triggers dictation.\n\n- **[Meeting audio memory usage]** → Long meetings accumulate large PCM buffers in memory. Mitigation: Stream audio chunks to temp files on disk, transcribe in chunks, concatenate transcripts. Not in V1 — V1 keeps full buffer in memory for simplicity.\n\n- **[macOS 15 minimum]** → speech-swift requires macOS 15+ (Sequoia) for the MLState API. Users on macOS 14 cannot run the app. Mitigation: Document requirement clearly. macOS 15 has been available since September 2024.\n\n- **[Clipboard clobbering]** → Clipboard paste mode briefly overwrites the user's pasteboard. Mitigation: Save original pasteboard contents before paste, restore immediately after (100ms delay). This is the standard pattern used by all clipboard-manipulating tools.\n",
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/design.md"
}
```

**Output:**
```
Wrote file successfully.
```

---

## Assistant (Build · Big Pickle · 6.2s)

_Thinking:_

Good, design.md is created. Now I need to create the specs. There are 9 capabilities from the proposal:1. dictation2. whisper-stt3. meeting-recording4. text-cleanup5. menu-bar-app6. hotkey-system7. paste-engine8. settings-ui9. permissions

Each needs a spec file at `specs/<capability>/spec.md`. Let me create all of them. I'll create them in parallel batches to be efficient.Let me first create the directory structure, then write all spec files.

Now let me create all 9 spec files. I'll batch them for efficiency.

**Tool: bash**

**Input:**
```json
{
  "command": "mkdir -p /Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/{dictation,whisper-stt,meeting-recording,text-cleanup,menu-bar-app,hotkey-system,paste-engine,settings-ui,permissions}",
  "description": "Create spec directories for all capabilities"
}
```

**Output:**
```
(no output)
```

---

## Assistant (Build · Big Pickle · 85.6s)

_Thinking:_

Now let me create all 9 spec files. I'll write them all in parallel.

**Tool: write**

**Input:**
```json
{
  "content": "## ADDED Requirements\n\n### Requirement: System-wide dictation trigger\nThe system SHALL provide a global keyboard shortcut that triggers speech-to-text dictation from any application on macOS. The shortcut SHALL work regardless of which application has focus.\n\n#### Scenario: Dictation triggered from any app\n- **WHEN** the user presses the configured dictation shortcut in any application\n- **THEN** the system begins recording audio from the configured microphone device\n\n#### Scenario: Dictation shortcut does not interfere with apps\n- **WHEN** the user presses the dictation shortcut\n- **THEN** the key event is not forwarded to the frontmost application\n\n### Requirement: Push-to-talk mode\nThe system SHALL support push-to-talk dictation where holding the shortcut key records audio and releasing it stops recording and triggers transcription.\n\n#### Scenario: Push-to-talk recording\n- **WHEN** the user presses and holds the push-to-talk shortcut key\n- **THEN** the system begins recording audio and displays a floating HUD with a timer\n\n#### Scenario: Push-to-talk stop and transcribe\n- **WHEN** the user releases the push-to-talk shortcut key\n- **THEN** the system stops recording, transcribes the audio, runs text cleanup, and pastes the result into the frontmost application\n\n### Requirement: Hands-free mode\nThe system SHALL support hands-free dictation where tapping the shortcut key starts recording and tapping it again stops recording.\n\n#### Scenario: Hands-free start\n- **WHEN** the user taps the hands-free shortcut key\n- **THEN** the system begins recording audio and displays a floating HUD with a timer\n\n#### Scenario: Hands-free stop\n- **WHEN** the user taps the hands-free shortcut key while recording is active\n- **THEN** the system stops recording, transcribes the audio, runs text cleanup, and pastes the result into the frontmost application\n\n### Requirement: Recording indicator\nThe system SHALL display a floating HUD panel during active recording showing the recording status and elapsed time.\n\n#### Scenario: HUD displayed during recording\n- **WHEN** recording is active\n- **THEN** a small floating panel is displayed showing a recording indicator and elapsed time in MM:SS format\n\n#### Scenario: HUD dismissed after recording\n- **WHEN** recording stops\n- **THEN** the floating HUD panel is dismissed\n\n### Requirement: Transcription latency\nThe system SHALL complete transcription of recorded audio within 2 seconds for recordings up to 30 seconds long on Apple Silicon hardware.\n\n#### Scenario: Short dictation latency\n- **WHEN** the user completes a 10-second dictation\n- **THEN** the transcribed text is pasted into the frontmost application within 2 seconds of recording stopping\n\n### Requirement: Audio device selection\nThe system SHALL allow the user to select which microphone device to use for dictation from a list of available audio input devices.\n\n#### Scenario: Device list populated\n- **WHEN** the user opens Settings and navigates to Dictation\n- **THEN** the system displays a list of all available audio input devices\n\n#### Scenario: Device selection persisted\n- **WHEN** the user selects a different audio input device\n- **THEN** the selection is saved and used for all subsequent dictation sessions\n",
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/dictation/spec.md"
}
```

**Output:**
```
Wrote file successfully.
```

**Tool: write**

**Input:**
```json
{
  "content": "## ADDED Requirements\n\n### Requirement: WhisperASR integration\nThe system SHALL use speech-swift's WhisperASR module for on-device speech-to-text inference. The system SHALL load the aufklarer/Whisper-Large-v3-Turbo-CoreML bundle via `WhisperASRModel.fromPretrained()`.\n\n#### Scenario: Model loaded from custom cache directory\n- **WHEN** the application launches\n- **THEN** the WhisperASR model is loaded from ~/Library/Application Support/Whisptator/Models/ using `cacheDir:` parameter\n\n#### Scenario: Model preload on launch\n- **WHEN** the application launches\n- **THEN** the model is loaded in a background task so it is ready before the user first triggers dictation\n\n### Requirement: Transcription API\nThe system SHALL expose a `TranscriptionEngine` that wraps WhisperASR and provides a simple async transcription interface accepting audio samples and returning text.\n\n#### Scenario: Transcribe audio buffer\n- **WHEN** the system calls `TranscriptionEngine.transcribe(audio:sampleRate:language:)` with a Float32 audio buffer\n- **THEN** the system returns the transcribed text as a String\n\n#### Scenario: Language auto-detection\n- **WHEN** transcription is requested without a language hint\n- **THEN** WhisperASR auto-detects the language from the audio\n\n#### Scenario: Language hint\n- **WHEN** transcription is requested with a specific language code (e.g., \"en\", \"fr\")\n- **THEN** WhisperASR uses the specified language for decoding\n\n### Requirement: Model download management\nThe system SHALL provide a `ModelManager` that handles downloading, caching, and status tracking of the Whisper CoreML model bundle.\n\n#### Scenario: First launch download\n- **WHEN** the application launches for the first time and the model is not cached\n- **THEN** the system initiates a download of the CoreML bundle from HuggingFace to ~/Library/Application Support/Whisptator/Models/\n\n#### Scenario: Download progress reporting\n- **WHEN** a model download is in progress\n- **THEN** the system reports download progress (bytes downloaded / total bytes) to the Settings UI\n\n#### Scenario: Offline mode\n- **WHEN** the model is already cached and the device is offline\n- **THEN** the system loads the model from the local cache using `offlineMode: true`\n\n### Requirement: Audio preprocessing\nThe system SHALL convert captured audio to 16 kHz mono Float32 format before passing it to WhisperASR, as required by the model.\n\n#### Scenario: Sample rate conversion\n- **WHEN** audio is captured at 44.1 kHz or 48 kHz (typical microphone sample rates)\n- **THEN** the system resamples to 16 kHz mono Float32 before transcription\n",
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/whisper-stt/spec.md"
}
```

**Output:**
```
Wrote file successfully.
```

**Tool: write**

**Input:**
```json
{
  "content": "## ADDED Requirements\n\n### Requirement: Meeting recording start/stop\nThe system SHALL provide a global keyboard shortcut to start and stop meeting recording. The shortcut SHALL be configurable in Settings.\n\n#### Scenario: Start meeting recording\n- **WHEN** the user triggers the meeting start/stop shortcut while not recording\n- **THEN** the system begins capturing system audio and/or microphone audio based on the configured audio source setting\n\n#### Scenario: Stop meeting recording\n- **WHEN** the user triggers the meeting start/stop shortcut while recording is active\n- **THEN** the system stops audio capture, transcribes the accumulated audio, and saves the transcript to disk\n\n### Requirement: System audio capture\nThe system SHALL use ScreenCaptureKit with `capturesAudio: true` and `excludesCurrentProcessAudio: true` to capture system audio output.\n\n#### Scenario: System audio captured\n- **WHEN** meeting recording is active with system audio enabled\n- **THEN** all system audio output (except the app's own audio) is captured\n\n#### Scenario: Screen Recording permission required\n- **WHEN** the user enables system audio capture and Screen Recording permission has not been granted\n- **THEN** the system displays a permission prompt directing the user to System Settings\n\n### Requirement: Microphone audio capture\nThe system SHALL use AVFoundation to capture audio from the selected microphone device during meeting recording.\n\n#### Scenario: Microphone captured during meeting\n- **WHEN** meeting recording is active with microphone enabled\n- **THEN** audio from the configured microphone device is captured\n\n### Requirement: Audio source modes\nThe system SHALL support three audio source modes for meeting recording: system + microphone, microphone only, and system only.\n\n#### Scenario: System + microphone mode\n- **WHEN** the audio source is set to \"System + Microphone\"\n- **THEN** both system audio and microphone audio are captured and mixed into a single stream\n\n#### Scenario: Microphone only mode\n- **WHEN** the audio source is set to \"Microphone only\"\n- **THEN** only microphone audio is captured and no Screen Recording permission is required\n\n#### Scenario: System only mode\n- **WHEN** the audio source is set to \"System only\"\n- **THEN** only system audio is captured via ScreenCaptureKit\n\n### Requirement: Transcript saving\nThe system SHALL save the transcribed meeting text to ~/Documents/Whisptator/Meetings/ with a filename format of `meeting_YYYY-MM-DD_HH-MM.txt`.\n\n#### Scenario: Transcript saved to disk\n- **WHEN** meeting recording stops and transcription completes\n- **THEN** the transcript text is saved to a .txt file in the Meetings directory\n\n#### Scenario: Meeting directory created automatically\n- **WHEN** the Meetings directory does not exist\n- **THEN** the system creates it before saving\n\n### Requirement: Audio retention policy\nThe system SHALL support three audio retention modes: keep audio files, delete after transcription, or auto-delete after a configurable number of days.\n\n#### Scenario: Keep audio\n- **WHEN** retention is set to \"Keep\"\n- **THEN** the recorded audio .wav file is saved alongside the transcript\n\n#### Scenario: Delete after transcription\n- **WHEN** retention is set to \"Delete after transcription\"\n- **THEN** the audio file is deleted after the transcript is saved\n\n#### Scenario: Auto-delete after days\n- **WHEN** retention is set to auto-delete with N days\n- **THEN** audio files older than N days are deleted on app launch\n\n### Requirement: Meeting recording indicator\nThe system SHALL display a recording indicator in the menu bar during active meeting recording.\n\n#### Scenario: Menu bar shows recording state\n- **WHEN** meeting recording is active\n- **THEN** the menu bar status item displays a recording indicator (e.g., red dot or \"Recording\" text)\n",
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/meeting-recording/spec.md"
}
```

**Output:**
```
Wrote file successfully.
```

**Tool: write**

**Input:**
```json
{
  "content": "## ADDED Requirements\n\n### Requirement: Deterministic cleanup pipeline\nThe system SHALL apply text cleanup as an ordered pipeline: filler removal → word replacement → snippet expansion → whitespace normalization. Each step is independently togglable.\n\n#### Scenario: Full pipeline execution\n- **WHEN** transcription completes and cleanup mode is set to \"Clean\"\n- **THEN** the raw transcript passes through all enabled cleanup steps in order and the cleaned text is returned\n\n#### Scenario: Raw mode bypasses cleanup\n- **WHEN** cleanup mode is set to \"Raw\"\n- **THEN** the raw transcript is returned without any processing\n\n### Requirement: Filler word removal\nThe system SHALL remove filler words from the transcript. Default fillers include \"um\", \"uh\", and sentence-start fillers \"so\", \"well\", \"like\". The user SHALL be able to toggle individual fillers and add custom ones.\n\n#### Scenario: Default fillers removed\n- **WHEN** the transcript contains \"um\" or \"uh\" between words\n- **THEN** these words are removed and surrounding whitespace is collapsed\n\n#### Scenario: Sentence-start fillers removed\n- **WHEN** a sentence begins with \"So\", \"Well\", or \"Like\"\n- **THEN** the filler word is removed and the sentence starts with the next word\n\n#### Scenario: Custom fillers\n- **WHEN** the user adds a custom filler word in Settings\n- **THEN** that word is also removed from transcripts\n\n### Requirement: Word replacement\nThe system SHALL replace configured words/phrases in the transcript with their target replacements. Rules are case-insensitive with whole-word matching.\n\n#### Scenario: Word replacement applied\n- **WHEN** the transcript contains \"aye pee eye\" and a rule maps it to \"API\"\n- **THEN** the output contains \"API\"\n\n#### Scenario: Case-insensitive matching\n- **WHEN** the transcript contains \"Kubernetes\" (capitalized) and a rule maps \"kubernetes\" to \"K8s\"\n- **THEN** the output contains \"K8s\"\n\n#### Scenario: Toggle without deletion\n- **WHEN** the user disables a word replacement rule\n- **THEN** the rule is skipped during processing but remains in the list for re-enabling\n\n### Requirement: Snippet expansion\nThe system SHALL replace short trigger phrases with longer text expansions. Triggers are matched longest-first to prevent partial matches.\n\n#### Scenario: Snippet expanded\n- **WHEN** the transcript contains \"my signature\" and a snippet maps it to \"Best regards, Emile\"\n- **THEN** the output contains \"Best regards, Emile\"\n\n#### Scenario: Longest match wins\n- **WHEN** the transcript contains \"my signature\" and both \"my sig\" and \"my signature\" are defined as triggers\n- **THEN** the longer trigger \"my signature\" is expanded\n\n### Requirement: Whitespace normalization\nThe system SHALL collapse multiple spaces into one, fix spacing around punctuation, and capitalize the first letter of the output.\n\n#### Scenario: Multiple spaces collapsed\n- **WHEN** the transcript contains multiple consecutive spaces\n- **THEN** they are collapsed to a single space\n\n#### Scenario: Punctuation spacing fixed\n- **WHEN** the transcript contains a period, comma, or question mark preceded by a space\n- **THEN** the space before the punctuation is removed\n\n#### Scenario: First letter capitalized\n- **WHEN** the cleaned text starts with a lowercase letter\n- **THEN** the first letter is capitalized\n\n### Requirement: Pipeline performance\nThe entire text cleanup pipeline SHALL complete in under 1 millisecond for texts up to 5000 characters.\n\n#### Scenario: Pipeline speed\n- **WHEN** a 5000-character transcript is processed through all cleanup steps\n- **THEN** the total processing time is under 1 millisecond\n",
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/text-cleanup/spec.md"
}
```

**Output:**
```
Wrote file successfully.
```

**Tool: write**

**Input:**
```json
{
  "content": "## ADDED Requirements\n\n### Requirement: Menu bar status item\nThe system SHALL display a status item in the macOS menu bar when the application is running. The status item SHALL show the app icon and provide access to primary actions.\n\n#### Scenario: Status item visible\n- **WHEN** the application is running\n- **THEN** a status item with the app icon is visible in the menu bar\n\n#### Scenario: Status item menu\n- **WHEN** the user clicks the status item\n- **THEN** a popover or menu is displayed with options: Start Dictation, Start Meeting, History, Settings, Quit\n\n### Requirement: Floating recording HUD\nThe system SHALL display a small floating panel during active recording (dictation or meeting) showing the recording status and elapsed time.\n\n#### Scenario: HUD appearance\n- **WHEN** recording starts\n- **THEN** a floating panel appears near the top of the screen with a recording indicator and elapsed timer (MM:SS format)\n\n#### Scenario: HUD stays on top\n- **WHEN** the HUD is displayed\n- **THEN** the panel has `.floating` window level and stays above all other windows\n\n#### Scenario: HUD dismissed on stop\n- **WHEN** recording stops\n- **THEN** the HUD panel is dismissed after a 500ms delay\n\n### Requirement: Settings window\nThe system SHALL provide a Settings window accessible from the menu bar with tabbed sections: General, Dictation, Model, Cleanup, Meeting.\n\n#### Scenario: Settings opened from menu bar\n- **WHEN** the user clicks \"Settings\" in the menu bar menu\n- **THEN** the Settings window opens with the General tab selected\n\n#### Scenario: Settings persist across launches\n- **WHEN** the user changes a setting\n- **THEN** the change is persisted and applied on next launch\n\n### Requirement: Launch at login\nThe system SHALL optionally launch automatically at login using the ServiceManagement framework.\n\n#### Scenario: Launch at login enabled\n- **WHEN** the user enables \"Launch at login\" in Settings\n- **THEN** the app registers as a login item using SMAppService\n\n#### Scenario: Launch at login disabled\n- **WHEN** the user disables \"Launch at login\" in Settings\n- **THEN** the app is removed from login items\n\n### Requirement: Dock visibility toggle\nThe system SHALL allow the user to choose whether the app appears in the Dock.\n\n#### Scenario: Show in Dock enabled\n- **WHEN** the user enables \"Show in Dock\" in Settings\n- **THEN** the app icon appears in the Dock\n\n#### Scenario: Show in Dock disabled\n- **WHEN** the user disables \"Show in Dock\" in Settings\n- **THEN** the app runs as an agent (menu bar only, no Dock icon)\n",
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/menu-bar-app/spec.md"
}
```

**Output:**
```
Wrote file successfully.
```

**Tool: write**

**Input:**
```json
{
  "content": "## ADDED Requirements\n\n### Requirement: Global keyboard shortcut monitoring\nThe system SHALL monitor keyboard events system-wide using a CGEvent tap to detect configured shortcuts, regardless of which application has focus.\n\n#### Scenario: Event tap active\n- **WHEN** the application is running and Accessibility permission is granted\n- **THEN** a CGEvent tap is active on a dedicated thread with its own RunLoop\n\n#### Scenario: Event tap re-enabled periodically\n- **WHEN** 5 seconds have passed since the last tap re-enable\n- **THEN** the CGEvent tap is re-enabled to prevent macOS from disabling it\n\n### Requirement: Push-to-talk shortcut\nThe system SHALL support a configurable push-to-talk shortcut where holding the key starts recording and releasing it stops recording and triggers transcription.\n\n#### Scenario: Key down starts recording\n- **WHEN** the user presses the configured push-to-talk key\n- **THEN** audio recording begins and the floating HUD is displayed\n\n#### Scenario: Key up stops and transcribes\n- **WHEN** the user releases the push-to-talk key while recording\n- **THEN** recording stops, audio is transcribed, text is cleaned, and the result is pasted\n\n### Requirement: Hands-free shortcut\nThe system SHALL support a configurable hands-free shortcut where tapping the key toggles recording on and off.\n\n#### Scenario: First tap starts recording\n- **WHEN** the user taps the hands-free shortcut while not recording\n- **THEN** audio recording begins and the floating HUD is displayed\n\n#### Scenario: Second tap stops and transcribes\n- **WHEN** the user taps the hands-free shortcut while recording is active\n- **THEN** recording stops, audio is transcribed, text is cleaned, and the result is pasted\n\n### Requirement: Shortcut recording UI\nThe system SHALL provide a shortcut recorder control in Settings that captures a key combination when the user clicks a button and presses the desired keys.\n\n#### Scenario: Record shortcut\n- **WHEN** the user clicks the shortcut recorder button and presses a key combination\n- **THEN** the recorded combination is displayed in the button and saved to Settings\n\n#### Scenario: Modifier-only chords\n- **WHEN** the user presses a modifier-only combination (e.g., Control+Option)\n- **THEN** the shortcut is accepted and saved\n\n#### Scenario: Clear shortcut\n- **WHEN** the user clicks a clear/reset button next to a shortcut\n- **THEN** the shortcut is removed and no key combination triggers that action\n\n### Requirement: Shortcut persistence\nThe system SHALL persist all configured shortcuts in UserDefaults and restore them on application launch.\n\n#### Scenario: Shortcuts restored on launch\n- **WHEN** the application launches\n- **THEN** previously configured shortcuts are loaded from UserDefaults and the CGEvent tap is configured to match them\n",
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/hotkey-system/spec.md"
}
```

**Output:**
```
Wrote file successfully.
```

**Tool: write**

**Input:**
```json
{
  "content": "## ADDED Requirements\n\n### Requirement: Clipboard paste mode\nThe system SHALL support pasting transcribed text into the frontmost application using the clipboard (Cmd+V) mechanism. This SHALL be the default paste mode.\n\n#### Scenario: Clipboard paste execution\n- **WHEN** transcription completes and paste mode is \"Clipboard\"\n- **THEN** the system saves the current pasteboard, sets the pasteboard to the transcribed text, simulates Cmd+V, waits 100ms, and restores the original pasteboard\n\n#### Scenario: Pasteboard preserved\n- **WHEN** clipboard paste is executed\n- **THEN** the user's original clipboard contents are restored after the paste\n\n### Requirement: Typing paste mode\nThe system SHALL support pasting transcribed text by simulating keyboard input character-by-character using CGEvent.\n\n#### Scenario: Character-by-character typing\n- **WHEN** transcription completes and paste mode is \"Typing\"\n- **THEN** the system simulates keyboard events for each character in the transcribed text, appearing as if typed by the user\n\n#### Scenario: Special character handling\n- **WHEN** the transcribed text contains characters that require modifier keys (e.g., uppercase letters, punctuation)\n- **THEN** the system correctly generates the appropriate CGEvent with the required modifier flags\n\n### Requirement: Paste mode configuration\nThe system SHALL allow the user to select between Clipboard and Typing paste modes in Settings. The setting SHALL be persisted and applied immediately.\n\n#### Scenario: Change paste mode\n- **WHEN** the user changes the paste mode in Settings\n- **THEN** the new mode is used for all subsequent dictation sessions\n\n### Requirement: Paste into frontmost app\nThe system SHALL paste transcribed text into whichever application has focus at the time the paste is triggered.\n\n#### Scenario: Paste targets focused app\n- **WHEN** the user completes a dictation while a text editor is focused\n- **THEN** the transcribed text appears in the text editor's input field\n\n#### Scenario: Paste works across different app types\n- **WHEN** the user completes a dictation while a browser, terminal, or messaging app is focused\n- **THEN** the transcribed text is inserted at the cursor position in that application\n",
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/paste-engine/spec.md"
}
```

**Output:**
```
Wrote file successfully.
```

**Tool: write**

**Input:**
```json
{
  "content": "## ADDED Requirements\n\n### Requirement: General settings tab\nThe system SHALL provide a General settings tab with options for launch at login and dock visibility.\n\n#### Scenario: Launch at login toggle\n- **WHEN** the user toggles \"Launch at login\" in General settings\n- **THEN** the app is added to or removed from macOS login items via SMAppService\n\n#### Scenario: Show in Dock toggle\n- **WHEN** the user toggles \"Show in Dock\" in General settings\n- **THEN** the app's Dock visibility is updated (requires restart for some changes)\n\n### Requirement: Dictation settings tab\nThe system SHALL provide a Dictation settings tab with shortcut configuration, paste mode, audio device, and language settings.\n\n#### Scenario: Push-to-talk shortcut display\n- **WHEN** the user opens Dictation settings\n- **THEN** the current push-to-talk shortcut is displayed with a recorder button to change it\n\n#### Scenario: Hands-free shortcut display\n- **WHEN** the user opens Dictation settings\n- **THEN** the current hands-free shortcut is displayed with a recorder button to change it\n\n#### Scenario: Paste mode selection\n- **WHEN** the user opens Dictation settings\n- **THEN** radio buttons for \"Clipboard (Cmd+V)\" and \"Typing\" are displayed with the current selection\n\n#### Scenario: Audio device dropdown\n- **WHEN** the user opens Dictation settings\n- **THEN** a dropdown lists all available audio input devices with the current selection\n\n#### Scenario: Language selection\n- **WHEN** the user opens Dictation settings\n- **THEN** a dropdown shows \"Auto-detect\" and common language options\n\n### Requirement: Model settings tab\nThe system SHALL provide a Model settings tab showing the available Whisper models with download status and selection.\n\n#### Scenario: Model list display\n- **WHEN** the user opens Model settings\n- **THEN** a list shows available models with name, size, download status, and a download/select button\n\n#### Scenario: Model download trigger\n- **WHEN** the user clicks \"Download\" next to a model\n- **THEN** the model is downloaded from HuggingFace to the model cache directory\n\n#### Scenario: Download progress display\n- **WHEN** a model is downloading\n- **THEN** a progress indicator shows bytes downloaded and estimated time remaining\n\n### Requirement: Cleanup settings tab\nThe system SHALL provide a Cleanup settings tab with toggleable pipeline steps and configurable rules.\n\n#### Scenario: Pipeline mode selection\n- **WHEN** the user opens Cleanup settings\n- **THEN** radio buttons for \"Raw\" and \"Clean\" modes are displayed\n\n#### Scenario: Filler word configuration\n- **WHEN** the user opens Cleanup settings with Clean mode selected\n- **THEN** a list of filler words with toggle switches and an \"Add custom\" button is displayed\n\n#### Scenario: Word replacement table\n- **WHEN** the user opens Cleanup settings\n- **THEN** a table of word replacement rules (trigger → replacement) with add/edit/delete controls is displayed\n\n#### Scenario: Snippet table\n- **WHEN** the user opens Cleanup settings\n- **THEN** a table of snippet rules (trigger → expansion) with add/edit/delete controls is displayed\n\n### Requirement: Meeting settings tab\nThe system SHALL provide a Meeting settings tab with audio source, retention, shortcut, and save location configuration.\n\n#### Scenario: Audio source selection\n- **WHEN** the user opens Meeting settings\n- **THEN** radio buttons for \"System + Microphone\", \"Microphone only\", and \"System only\" are displayed\n\n#### Scenario: Audio retention selection\n- **WHEN** the user opens Meeting settings\n- **THEN** radio buttons for \"Keep audio\", \"Delete after transcription\", and \"Auto-delete after N days\" are displayed\n\n#### Scenario: Meeting shortcut configuration\n- **WHEN** the user opens Meeting settings\n- **THEN** a shortcut recorder for the meeting start/stop shortcut is displayed\n\n#### Scenario: Save location display\n- **WHEN** the user opens Meeting settings\n- **THEN** the save location path is displayed with a button to change it\n",
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/settings-ui/spec.md"
}
```

**Output:**
```
Wrote file successfully.
```

**Tool: write**

**Input:**
```json
{
  "content": "## ADDED Requirements\n\n### Requirement: Accessibility permission check\nThe system SHALL check whether Accessibility permission is granted on launch using `AXIsProcessTrusted()`. The system SHALL display a warning if the permission is not granted.\n\n#### Scenario: Permission granted\n- **WHEN** the application launches and Accessibility permission is granted\n- **THEN** the CGEvent tap is activated and global hotkeys function normally\n\n#### Scenario: Permission not granted\n- **WHEN** the application launches and Accessibility permission is not granted\n- **THEN** a warning is displayed in the menu bar and Settings, with a button to open System Settings > Privacy & Security > Accessibility\n\n### Requirement: Microphone permission check\nThe system SHALL check whether Microphone permission is granted when the user first attempts to record audio. The system SHALL request permission if not already granted.\n\n#### Scenario: Microphone permission granted\n- **WHEN** the user triggers dictation and Microphone permission is granted\n- **THEN** audio recording begins normally\n\n#### Scenario: Microphone permission not granted\n- **WHEN** the user triggers dictation and Microphone permission is not granted\n- **THEN** the system displays a prompt directing the user to System Settings > Privacy & Security > Microphone\n\n### Requirement: Screen Recording permission check\nThe system SHALL check whether Screen Recording permission is granted when the user attempts to start a meeting recording with system audio enabled.\n\n#### Scenario: Screen Recording permission granted\n- **WHEN** the user starts a meeting recording with system audio and Screen Recording permission is granted\n- **THEN** system audio capture begins normally via ScreenCaptureKit\n\n#### Scenario: Screen Recording permission not granted\n- **WHEN** the user starts a meeting recording with system audio and Screen Recording permission is not granted\n- **THEN** the system displays a prompt directing the user to System Settings > Privacy & Security > Screen Recording\n\n#### Scenario: Microphone-only meeting skips Screen Recording check\n- **WHEN** the user starts a meeting recording with \"Microphone only\" audio source\n- **THEN** the system does not check or require Screen Recording permission\n\n### Requirement: Permission onboarding flow\nThe system SHALL display a first-launch onboarding dialog that explains which permissions are needed and why, with buttons to grant each permission.\n\n#### Scenario: First launch onboarding\n- **WHEN** the application launches for the first time\n- **THEN** an onboarding dialog is displayed listing Accessibility, Microphone, and Screen Recording permissions with explanations and grant buttons\n\n#### Scenario: Skip onboarding\n- **WHEN** the user clicks \"Skip for now\" in the onboarding dialog\n- **THEN** the dialog is dismissed and the app continues with reduced functionality until permissions are granted\n\n### Requirement: Permission status in Settings\nThe system SHALL display the current status of all required permissions in the General settings tab.\n\n#### Scenario: Permission status indicators\n- **WHEN** the user opens General settings\n- **THEN** each permission shows \"✅ Granted\" or \"⚠️ Grant in System Settings\" with a link to the relevant System Settings pane\n",
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/permissions/spec.md"
}
```

**Output:**
```
Wrote file successfully.
```

---

## Assistant (Build · Big Pickle · 11.1s)

_Thinking:_

All 9 spec files are created. Now let me update the todo list and check the status.

**Tool: todowrite**

**Input:**
```json
{
  "todos": [
    {
      "content": "Create change directory",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Get artifact build order from status",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create proposal.md artifact",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create design.md artifact",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create specs artifacts (9 files)",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create tasks.md artifact",
      "priority": "high",
      "status": "in_progress"
    },
    {
      "content": "Verify all artifacts and show final status",
      "priority": "high",
      "status": "pending"
    }
  ]
}
```

**Output:**
```
[
  {
    "content": "Create change directory",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Get artifact build order from status",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Create proposal.md artifact",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Create design.md artifact",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Create specs artifacts (9 files)",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Create tasks.md artifact",
    "status": "in_progress",
    "priority": "high"
  },
  {
    "content": "Verify all artifacts and show final status",
    "status": "pending",
    "priority": "high"
  }
]
```

---

## Assistant (Build · Big Pickle · 4.6s)

_Thinking:_

Now I need to check if tasks is unblocked and get its instructions.

**Tool: bash**

**Input:**
```json
{
  "command": "openspec status --change \"v1-dictation-meeting\" --json",
  "description": "Check if tasks artifact is unblocked"
}
```

**Output:**
```
{
  "changeName": "v1-dictation-meeting",
  "schemaName": "spec-driven",
  "planningHome": {
    "kind": "repo",
    "root": "/Volumes/emile/PROJECTS/2026/whisptator",
    "changesDir": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes",
    "defaultSchema": "spec-driven"
  },
  "changeRoot": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting",
  "artifactPaths": {
    "proposal": {
      "outputPath": "proposal.md",
      "resolvedOutputPath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/proposal.md",
      "existingOutputPaths": [
        "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/proposal.md"
      ]
    },
    "specs": {
      "outputPath": "specs/**/*.md",
      "resolvedOutputPath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/**/*.md",
      "existingOutputPaths": [
        "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/dictation/spec.md",
        "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/hotkey-system/spec.md",
        "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/meeting-recording/spec.md",
        "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/menu-bar-app/spec.md",
        "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/paste-engine/spec.md",
        "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/permissions/spec.md",
        "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/settings-ui/spec.md",
        "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/text-cleanup/spec.md",
        "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/whisper-stt/spec.md"
      ]
    },
    "design": {
      "outputPath": "design.md",
      "resolvedOutputPath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/design.md",
      "existingOutputPaths": [
        "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/design.md"
      ]
    },
    "tasks": {
      "outputPath": "tasks.md",
      "resolvedOutputPath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/tasks.md",
      "existingOutputPaths": []
    }
  },
  "isComplete": false,
  "applyRequires": [
    "tasks"
  ],
  "nextSteps": [
    "Run openspec instructions tasks --change \"v1-dictation-meeting\" --json before writing that artifact."
  ],
  "actionContext": {
    "mode": "repo-local",
    "sourceOfTruth": "repo",
    "planningArtifacts": [
      "proposal",
      "design",
      "specs",
      "tasks"
    ],
    "linkedContext": [],
    "allowedEditRoots": [
      "/Volumes/emile/PROJECTS/2026/whisptator"
    ],
    "requiresAffectedAreaSelection": false,
    "constraints": [
      "Repo-local change artifacts and implementation edits are scoped to this project."
    ]
  },
  "artifacts": [
    {
      "id": "proposal",
      "outputPath": "proposal.md",
      "status": "done"
    },
    {
      "id": "design",
      "outputPath": "design.md",
      "status": "done"
    },
    {
      "id": "specs",
      "outputPath": "specs/**/*.md",
      "status": "done"
    },
    {
      "id": "tasks",
      "outputPath": "tasks.md",
      "status": "ready"
    }
  ],
  "root": {
    "path": "/Volumes/emile/PROJECTS/2026/whisptator",
    "source": "nearest"
  }
}

```

---

## Assistant (Build · Big Pickle · 3.9s)

_Thinking:_

Tasks is now ready. Let me get its instructions.

**Tool: bash**

**Input:**
```json
{
  "command": "openspec instructions tasks --change \"v1-dictation-meeting\" --json",
  "description": "Get tasks artifact instructions"
}
```

**Output:**
```
{
  "changeName": "v1-dictation-meeting",
  "artifactId": "tasks",
  "schemaName": "spec-driven",
  "changeDir": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting",
  "planningHome": {
    "kind": "repo",
    "root": "/Volumes/emile/PROJECTS/2026/whisptator",
    "changesDir": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes",
    "defaultSchema": "spec-driven"
  },
  "outputPath": "tasks.md",
  "resolvedOutputPath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/tasks.md",
  "existingOutputPaths": [],
  "description": "Implementation checklist with trackable tasks",
  "instruction": "Create the task list that breaks down the implementation work.\n\n**IMPORTANT: Follow the template below exactly.** The apply phase parses\ncheckbox format to track progress. Tasks not using `- [ ]` won't be tracked.\n\nGuidelines:\n- Group related tasks under ## numbered headings\n- Each task MUST be a checkbox: `- [ ] X.Y Task description`\n- Tasks should be small enough to complete in one session\n- Order tasks by dependency (what must be done first?)\n\nExample:\n```\n## 1. Setup\n\n- [ ] 1.1 Create new module structure\n- [ ] 1.2 Add dependencies to package.json\n\n## 2. Core Implementation\n\n- [ ] 2.1 Implement data export function\n- [ ] 2.2 Add CSV formatting utilities\n```\n\nReference specs for what needs to be built, design for how to build it.\nEach task should be verifiable - you know when it's done.\n",
  "template": "## 1. <!-- Task Group Name -->\n\n- [ ] 1.1 <!-- Task description -->\n- [ ] 1.2 <!-- Task description -->\n\n## 2. <!-- Task Group Name -->\n\n- [ ] 2.1 <!-- Task description -->\n- [ ] 2.2 <!-- Task description -->\n",
  "dependencies": [
    {
      "id": "specs",
      "done": true,
      "path": "specs/**/*.md",
      "description": "Detailed specifications for the change"
    },
    {
      "id": "design",
      "done": true,
      "path": "design.md",
      "description": "Technical design document with implementation details"
    }
  ],
  "unlocks": [],
  "root": {
    "path": "/Volumes/emile/PROJECTS/2026/whisptator",
    "source": "nearest"
  }
}

```

---

## Assistant (Build · Big Pickle · 32.0s)

_Thinking:_

Now let me create the tasks.md file. I need to break down the implementation into logical, ordered tasks based on the design and specs.

Let me think about the task ordering:

1. **Project setup** — Package.swift, directory structure, dependencies
2. **Core infrastructure** — AppSettings, App entry point, MenuBarExtra
3. **Hotkey system** — CGEvent tap, shortcut recorder, persistence
4. **Audio capture** — MicrophoneCapture, AudioDeviceManager
5. **STT engine** — TranscriptionEngine, ModelManager
6. **Paste engine** — ClipboardPaster, TypingPaster
7. **Text cleanup** — Pipeline and individual steps
8. **Dictation flow** — Orchestrator connecting hotkeys → audio → STT → cleanup → paste
9. **Meeting recording** — SystemAudioCapture, MeetingRecorder, TranscriptSaver
10. **Settings UI** — All settings tabs
11. **Permissions** — Permission checking and onboarding
12. **Floating HUD** — Recording indicator panelLet me create a comprehensive task list.

**Tool: write**

**Input:**
```json
{
  "content": "## 1. Project Setup\n\n- [ ] 1.1 Create Package.swift with Whisptator (app) and WhisptatorCore (library) targets, speech-swift dependency\n- [ ] 1.2 Create directory structure: Sources/Whisptator/, Sources/WhisptatorCore/{Audio,STT,Hotkeys,Paste,TextProcessing,Meeting,Settings}, Sources/WhisptatorTests/\n- [ ] 1.3 Create WhisptatorApp.swift with @main, MenuBarExtra scene, Settings scene\n- [ ] 1.4 Verify build compiles with `swift build`\n\n## 2. App Settings\n\n- [ ] 2.1 Create AppSettings.swift with UserDefaults wrapper for all settings (shortcuts, paste mode, audio device, language, cleanup rules, meeting config)\n- [ ] 2.2 Define settings keys and default values for all configuration options\n- [ ] 2.3 Add shortcut persistence (keyCode + modifier flags for push-to-talk, hands-free, meeting)\n\n## 3. Menu Bar App Shell\n\n- [ ] 3.1 Create MenuBarView.swift with status item popover: Start Dictation, Start Meeting, Settings, Quit\n- [ ] 3.2 Create NSStatusItem setup with app icon\n- [ ] 3.3 Add \"Show in Dock\" toggle using NSApp.setActivationPolicy\n- [ ] 3.4 Add \"Launch at login\" using SMAppService\n\n## 4. Hotkey System\n\n- [ ] 4.1 Create HotkeyMonitor.swift with CGEvent tap on dedicated thread with RunLoop\n- [ ] 4.2 Implement key-down/key-up event matching against saved shortcuts\n- [ ] 4.3 Add periodic tap re-enable (every 5 seconds) to prevent macOS from disabling it\n- [ ] 4.4 Create ShortcutRecorder.swift — NSViewRepresentable shortcut capture control for SwiftUI Settings\n- [ ] 4.5 Wire shortcut changes from Settings to HotkeyMonitor\n\n## 5. Audio Capture — Microphone\n\n- [ ] 5.1 Create AudioDeviceManager.swift — list available audio input devices using AVCaptureDevice\n- [ ] 5.2 Create MicrophoneCapture.swift — AVFoundation audio capture to in-memory Float32 buffer\n- [ ] 5.3 Implement start/stop recording, sample rate detection, audio format conversion\n- [ ] 5.4 Add audio preprocessing: convert captured audio to 16 kHz mono Float32 for WhisperASR\n\n## 6. STT Engine\n\n- [ ] 6.1 Create ModelManager.swift — download model via speech-swift's fromPretrained(cacheDir:) to ~/Library/Application Support/Whisptator/Models/\n- [ ] 6.2 Implement download progress reporting, offline mode, download status tracking\n- [ ] 6.3 Create TranscriptionEngine.swift — wrap WhisperASRModel, expose async transcribe(audio:sampleRate:language:) API\n- [ ] 6.4 Add background model preload on app launch\n\n## 7. Paste Engine\n\n- [ ] 7.1 Create ClipboardPaster.swift — save pasteboard, set text, simulate Cmd+V, wait 100ms, restore pasteboard\n- [ ] 7.2 Create TypingPaster.swift — CGEvent character-by-character typing with modifier key handling\n- [ ] 7.3 Add paste mode selection (clipboard vs typing) wired to AppSettings\n\n## 8. Text Cleanup Pipeline\n\n- [ ] 8.1 Create TextCleanupPipeline.swift — ordered pipeline orchestrator: fillers → replacements → snippets → whitespace\n- [ ] 8.2 Create FillerRemover.swift — remove configured filler words, sentence-start fillers\n- [ ] 8.3 Create WordReplacer.swift — case-insensitive whole-word replacement with toggle support\n- [ ] 8.4 Create SnippetExpander.swift — longest-first trigger matching for snippet expansion\n- [ ] 8.5 Create WhitespaceCleaner.swift — collapse spaces, fix punctuation spacing, capitalize first letter\n- [ ] 8.6 Add unit tests for each cleanup step and the full pipeline\n\n## 9. Dictation Flow Orchestrator\n\n- [ ] 9.1 Wire HotkeyMonitor → MicrophoneCapture start/stop on key down/up (push-to-talk)\n- [ ] 9.2 Wire HotkeyMonitor → MicrophoneCapture toggle on tap (hands-free)\n- [ ] 9.3 Wire MicrophoneCapture buffer → TranscriptionEngine → TextCleanupPipeline → PasteEngine\n- [ ] 9.4 Add error handling: model not loaded, audio capture failed, paste failed\n- [ ] 9.5 Add dictation status state machine: idle → recording → transcribing → pasting → idle\n\n## 10. Floating HUD\n\n- [ ] 10.1 Create FloatingHUD.swift — NSPanel with .floating level, recording indicator, elapsed timer\n- [ ] 10.2 Wire HUD show/hide to dictation and meeting recording state\n- [ ] 10.3 Position HUD near top-center of screen\n- [ ] 10.4 Add 500ms dismiss delay after recording stops\n\n## 11. Meeting Recording\n\n- [ ] 11.1 Create SystemAudioCapture.swift — ScreenCaptureKit with capturesAudio, excludesCurrentProcessAudio\n- [ ] 11.2 Create AudioMixer.swift — mix system audio and microphone streams via AVAudioEngine mixer\n- [ ] 11.3 Create MeetingRecorder.swift — orchestrate start/stop, accumulate mixed PCM buffer\n- [ ] 11.4 Create TranscriptSaver.swift — save transcript to ~/Documents/Whisptator/Meetings/ with timestamped filename\n- [ ] 11.5 Implement audio retention policies: keep, delete after transcription, auto-delete after N days\n- [ ] 11.6 Wire meeting shortcut from HotkeyMonitor to MeetingRecorder\n- [ ] 11.7 Add menu bar recording indicator during active meeting\n\n## 12. Settings UI\n\n- [ ] 12.1 Create SettingsView.swift — tabbed SwiftUI Settings scene with General, Dictation, Model, Cleanup, Meeting tabs\n- [ ] 12.2 Build General tab: launch at login, dock visibility, permission status indicators\n- [ ] 12.3 Build Dictation tab: shortcut recorders, paste mode radio, audio device dropdown, language dropdown\n- [ ] 12.4 Build Model tab: model list with download status, download button, progress indicator\n- [ ] 12.5 Build Cleanup tab: mode toggle, filler list with toggles, word replacement table, snippet table\n- [ ] 12.6 Build Meeting tab: audio source radio, retention radio, shortcut recorder, save location\n\n## 13. Permissions\n\n- [ ] 13.1 Create PermissionGate.swift — check AXIsProcessTrusted(), microphone permission, screen recording permission\n- [ ] 13.2 Create first-launch onboarding dialog explaining permissions with grant buttons\n- [ ] 13.3 Add permission status indicators in General Settings\n- [ ] 13.4 Handle permission-not-graced gracefully in dictation and meeting flows\n\n## 14. Integration Testing\n\n- [ ] 14.1 End-to-end dictation test: hotkey → record → transcribe → paste in a text editor\n- [ ] 14.2 Meeting recording test: start → capture system+mic → stop → transcript saved\n- [ ] 14.3 Text cleanup pipeline test with all steps enabled\n- [ ] 14.4 Settings persistence test: change settings → relaunch → settings preserved\n- [ ] 14.5 Permission denial test: revoke accessibility → app shows warning, dictation disabled\n",
  "filePath": "/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/tasks.md"
}
```

**Output:**
```
Wrote file successfully.
```

---

## Assistant (Build · Big Pickle · 8.4s)

_Thinking:_

All artifacts are created. Let me verify the final status.

**Tool: todowrite**

**Input:**
```json
{
  "todos": [
    {
      "content": "Create change directory",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Get artifact build order from status",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create proposal.md artifact",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create design.md artifact",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create specs artifacts (9 files)",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create tasks.md artifact",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Verify all artifacts and show final status",
      "priority": "high",
      "status": "in_progress"
    }
  ]
}
```

**Output:**
```
[
  {
    "content": "Create change directory",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Get artifact build order from status",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Create proposal.md artifact",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Create design.md artifact",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Create specs artifacts (9 files)",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Create tasks.md artifact",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Verify all artifacts and show final status",
    "status": "in_progress",
    "priority": "high"
  }
]
```

---

## Assistant (Build · Big Pickle · 6.8s)

_Thinking:_

Let me verify all files exist and check the final status.

**Tool: bash**

**Input:**
```json
{
  "command": "ls -la /Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/",
  "description": "Verify all artifact files exist"
}
```

**Output:**
```
total 64
drwxr-xr-x   7 emile.bassil  staff   224 15 Jul 15:49 .
drwxr-xr-x   4 emile.bassil  staff   128 15 Jul 15:45 ..
-rw-r--r--   1 emile.bassil  staff    40 15 Jul 15:45 .openspec.yaml
-rw-r--r--   1 emile.bassil  staff  9512 15 Jul 15:47 design.md
-rw-r--r--   1 emile.bassil  staff  4116 15 Jul 15:46 proposal.md
drwxr-xr-x  11 emile.bassil  staff   352 15 Jul 15:47 specs
-rw-r--r--   1 emile.bassil  staff  6370 15 Jul 15:49 tasks.md

```

**Tool: bash**

**Input:**
```json
{
  "command": "ls -la /Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/*/",
  "description": "Verify all spec files exist"
}
```

**Output:**
```
/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/dictation/:
total 8
drwxr-xr-x   3 emile.bassil  staff    96 15 Jul 15:47 .
drwxr-xr-x  11 emile.bassil  staff   352 15 Jul 15:47 ..
-rw-r--r--   1 emile.bassil  staff  3244 15 Jul 15:47 spec.md

/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/hotkey-system/:
total 8
drwxr-xr-x   3 emile.bassil  staff    96 15 Jul 15:48 .
drwxr-xr-x  11 emile.bassil  staff   352 15 Jul 15:47 ..
-rw-r--r--   1 emile.bassil  staff  2807 15 Jul 15:48 spec.md

/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/meeting-recording/:
total 8
drwxr-xr-x   3 emile.bassil  staff    96 15 Jul 15:47 .
drwxr-xr-x  11 emile.bassil  staff   352 15 Jul 15:47 ..
-rw-r--r--   1 emile.bassil  staff  3825 15 Jul 15:47 spec.md

/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/menu-bar-app/:
total 8
drwxr-xr-x   3 emile.bassil  staff    96 15 Jul 15:48 .
drwxr-xr-x  11 emile.bassil  staff   352 15 Jul 15:47 ..
-rw-r--r--   1 emile.bassil  staff  2553 15 Jul 15:48 spec.md

/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/paste-engine/:
total 8
drwxr-xr-x   3 emile.bassil  staff    96 15 Jul 15:48 .
drwxr-xr-x  11 emile.bassil  staff   352 15 Jul 15:47 ..
-rw-r--r--   1 emile.bassil  staff  2229 15 Jul 15:48 spec.md

/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/permissions/:
total 8
drwxr-xr-x   3 emile.bassil  staff    96 15 Jul 15:48 .
drwxr-xr-x  11 emile.bassil  staff   352 15 Jul 15:47 ..
-rw-r--r--   1 emile.bassil  staff  3281 15 Jul 15:48 spec.md

/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/settings-ui/:
total 8
drwxr-xr-x   3 emile.bassil  staff    96 15 Jul 15:48 .
drwxr-xr-x  11 emile.bassil  staff   352 15 Jul 15:47 ..
-rw-r--r--   1 emile.bassil  staff  3987 15 Jul 15:48 spec.md

/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/text-cleanup/:
total 8
drwxr-xr-x   3 emile.bassil  staff    96 15 Jul 15:48 .
drwxr-xr-x  11 emile.bassil  staff   352 15 Jul 15:47 ..
-rw-r--r--   1 emile.bassil  staff  3620 15 Jul 15:48 spec.md

/Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting/specs/whisper-stt/:
total 8
drwxr-xr-x   3 emile.bassil  staff    96 15 Jul 15:47 .
drwxr-xr-x  11 emile.bassil  staff   352 15 Jul 15:47 ..
-rw-r--r--   1 emile.bassil  staff  2602 15 Jul 15:47 spec.md

```

---

## Assistant (Build · Big Pickle · 7.3s)

_Thinking:_

All files are in place. Let me now run the final status check.

**Tool: bash**

**Input:**
```json
{
  "command": "openspec status --change \"v1-dictation-meeting\"",
  "description": "Show final change status"
}
```

**Output:**
```
- Loading change status...
Change: v1-dictation-meeting
Schema: spec-driven
Change root: /Volumes/emile/PROJECTS/2026/whisptator/openspec/changes/v1-dictation-meeting
Progress: 4/4 artifacts complete

[x] proposal
[x] design
[x] specs
[x] tasks

All artifacts complete!

```

---

## Assistant (Build · Big Pickle · 5.3s)

_Thinking:_

All artifacts are complete. Let me update the todo list and provide the final summary.

**Tool: todowrite**

**Input:**
```json
{
  "todos": [
    {
      "content": "Create change directory",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Get artifact build order from status",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create proposal.md artifact",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create design.md artifact",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create specs artifacts (9 files)",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Create tasks.md artifact",
      "priority": "high",
      "status": "completed"
    },
    {
      "content": "Verify all artifacts and show final status",
      "priority": "high",
      "status": "completed"
    }
  ]
}
```

**Output:**
```
[
  {
    "content": "Create change directory",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Get artifact build order from status",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Create proposal.md artifact",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Create design.md artifact",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Create specs artifacts (9 files)",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Create tasks.md artifact",
    "status": "completed",
    "priority": "high"
  },
  {
    "content": "Verify all artifacts and show final status",
    "status": "completed",
    "priority": "high"
  }
]
```

---

## Assistant (Build · Big Pickle · 10.7s)

_Thinking:_

All done. Let me provide the final summary.

All artifacts created. Here's what was produced:

**Change:** `v1-dictation-meeting`
**Location:** `openspec/changes/v1-dictation-meeting/`

| Artifact | Description |
|----------|-------------|
| `proposal.md` | Why Whisptator, what changes, 9 capabilities defined |
| `design.md` | 8 technical decisions with rationale, 7 risks with mitigations |
| `specs/dictation/spec.md` | Dictation trigger, push-to-talk, hands-free, HUD, latency |
| `specs/whisper-stt/spec.md` | WhisperASR integration, model download, audio preprocessing |
| `specs/meeting-recording/spec.md` | System+mic capture, audio source modes, transcript saving, retention |
| `specs/text-cleanup/spec.md` | Pipeline: fillers → replacements → snippets → whitespace |
| `specs/menu-bar-app/spec.md` | Status item, floating HUD, settings window, dock/login toggles |
| `specs/hotkey-system/spec.md` | CGEvent tap, push-to-talk, hands-free, shortcut recorder |
| `specs/paste-engine/spec.md` | Clipboard (Cmd+V) and typing (CGEvent) paste modes |
| `specs/settings-ui/spec.md` | 5-tab settings: General, Dictation, Model, Cleanup, Meeting |
| `specs/permissions/spec.md` | Accessibility, Microphone, Screen Recording permission flow |
| `tasks.md` | 14 task groups, 63 implementation tasks |

**All artifacts complete. Ready for implementation.**

Run `/opsx-apply` to start implementing.

---

