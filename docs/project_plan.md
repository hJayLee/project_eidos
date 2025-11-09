# Project Eidos – Implementation Plan

_Last updated: 2025-11-09_

---

## 1. UI / Layout Stabilization

- **Architecture documentation**  
  Maintain `lib/core/app_architecture.md` with latest layout diagrams, provider dependencies, and data flow.
- **Shared components**  
  Extract frequently used widgets (cards, tab headers, buttons) into reusable components under `lib/presentation/widgets/common`.
- **State wiring**  
  Confirm Riverpod providers (project, slides, auth, Firebase) and document event flows for CRUD and AI updates.

## 2. Editor Feature Enhancements

1. **Slide content editing**
   - Stabilize key point add/edit/reorder behaviour.
   - Introduce text styling controls and support for additional element types (image, chart, icon placeholders).
2. **Script tooling**
   - Implement script history (AI/manual versions) and restoration.
   - Provide tone/style variations for regenerated scripts.
   - Integrate avatar audio preview with future TTS providers.
3. **Design & Asset tabs**
   - Prepare design template selection workflow.
   - Start asset library management (upload, reuse per project).

## 3. Service Layer Integration

- **AI services**  
  Finalise API contracts for slide & script generation. Consume runtime keys (`--dart-define=OPENAI_API_KEY`) and handle errors.
- **Avatar/TTS**  
  Replace stubbed preview with actual HeyGen/TTS integration. Support inline playback and fallback messaging.
- **Storage & security**  
  Harden Firestore rules, monitor usage, and provide offline/local fallback behaviour.

## 4. Video Pipeline & Collaboration

- **Rendering pipeline**  
  Design export workflow combining slides, scripts, avatar audio/video. Decide on backend worker/queue requirements.
- **Collaboration roadmap**  
  Draft models for project sharing, roles, and commenting.
- **Testing**  
  Add unit tests for providers/services and end-to-end scenarios covering Firebase and AI calls.

---

### Working Practices

- Track each enhancement with dedicated commits/PRs.
- Update this plan (and `app_architecture.md`) whenever scope or workflow changes.
- Review milestones at the start/end of each development session.***

