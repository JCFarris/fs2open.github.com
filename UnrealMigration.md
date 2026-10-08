# Unreal Engine 5.8 migration analysis

Planning revision: October 7, 2026. This is a personal, private, noncommercial proof of concept. It will not be released in this form. The immediate goal is to test gameplay, conversion, and Unreal workflows; legal review, distribution planning, and release readiness are deferred and are not prototype gates. This is a proposed implementation plan, not evidence that a UE project, importer, or migrated mission already exists. The working FSO build is the reference implementation. Windows single-player and curated content are recommended initial scope; platform and content choices remain open until Phase 0 resolves them. Production and release sections below describe optional future work beyond the proof of concept.

The executable milestone sequence and current status are tracked in [UnrealRoadmap.md](UnrealRoadmap.md). Content inspection usage and limitations are documented in [tools/migration/README.md](tools/migration/README.md). This document holds the detailed architecture and format migration plan.

## Executive assessment

**Current proof-of-concept goal:** play one existing FreeSpace mission end to end in UE5 using its existing ships, textures, weapons, mission logic, and required presentation/audio, while taking advantage of Unreal materials and lighting. End to end means launch/briefing and required loadout selection → all required encounter stages → success or failure → appropriate debrief and retry/exit. A disconnected combat sandbox or a lit model viewer is an intermediate milestone, not completion. Full campaign progression and a broad new asset roster are outside this goal.

**Implementation priority:** set up and verify the UE project first. Next establish the content pipeline and a lit scene containing actual imported mission assets before developing the playable systems against them. Enumerate all formats now, but implement conversion for the chosen mission's resolved dependency set first. Temporary primitives are acceptable for project setup and isolated experiments; gameplay acceptance uses existing content.

### First-mission investigation (local content verified)

The owner has selected **Surrender, Belisarius! (`SM1-01.fs2`)** as the proof-of-concept mission. Inspection of `C:\dev\fs2-content\Root_fs2.vp` confirms that this is the first combat mission in `FreeSpace2.fc2`, following three tutorials. The target is its complete briefing-to-debrief flow with existing content and UE lighting. Tutorial migration is outside the current scope.

The local baseline contains nine retail VP archives and loose movie files. A validated VP index scan finds 90 mission files, two campaigns, 176 POF models, 30 tables, 3,334 PCX images, 702 ANI animations, 2,651 WAV files, six NEB files, three VF fonts, and ten loose MVE movies. These are whole-installation counts, including duplicate candidates; they are not the chosen mission's dependency closure. This installation currently has no inventoried DDS/KTX/TBM/Lua files, so PCX/ANI conversion should precede optional modern-format support. Additional `.frc` and `.scc` files occur outside the earlier registry inventory; classify their actual consumers before deciding whether to skip them.

Run `tools/migration/Inspect-Content.ps1 -OutputPath tools/migration/content-inventory.local.json` to reproduce the local inventory, campaign ordering and lexical mission analysis. The generated report is ignored by Git, and the scanner does not extract/copy game assets. It validates VP headers, directory stacks and data ranges and records source offsets/sizes. It intentionally does not implement FSO search precedence or table merges; duplicate mission candidates cause a failure requiring explicit resolution. Its expression/reference results are discovery candidates, not a semantic parser or completeness claim.

For SM1-01, the verified mission SHA-256 is `17d7fc1d707bcd102631b70fb44c688f78a0790bda8097642118a089887c09c0`. It declares six ship classes: GTF Myrmidon, GTF Hercules, GVF Serapis, GVFr Satis, GTCv Deimos and GVD Hatshepsut. The mission's section annotations report 28 objects, ten wings, 62 events, one primary goal, and four waypoint lists; these comments must be checked against parsed records before becoming validation assertions. Required model paths are still to be resolved from `ships.tbl`, and model material textures from the POF metadata.

Its lexical expression inventory includes chase/guard/waypoint orders, docking/undocking and their delay conditions, cargo transfer, scripted beam fire, self-destruction, vulnerability changes, secondary-fire timing, messages, random choices, and event/goal/arrival/departure/destruction conditions. These are concrete investigation items for the end-to-end runtime, not optional polish. The campaign transition checks the `Protect Iota` goal; mission goal/event and debrief semantics need to be traced before defining victory. Briefing/debrief voice references, weapon banks, `SunGold`, nebula background bitmaps and `planetf`, `Brief1` and `1: Genesis` music references also appear in the mission.

The first content batch resolves only the player Myrmidon's class/model and converts its POF geometry and PCX material dependencies into UE mesh/texture/material assets for the ship-rendering milestone. After that visual gate, resolve Psamtik and the remaining ship classes, effective ship/weapon defaults and mission overrides, gameplay metadata, ANI effects, WAV cues, environment/background definitions, briefing/debrief resources, and loadout alternatives. Event-referenced entities/assets must be included even when absent from the initial scene. Make the expanded resolved manifest and operator support sheet the inputs to the gameplay work packages.

Training-1 was inventoried for comparison but is not selected. Its input-history conditions, HUD flashing, training messages, training-speed context and `special-check` do not need implementation for this proof unless SM1-01's resolved dependencies independently require them.

Moving FreeSpace Open (FSO) to Unreal Engine 5.8 is feasible as a remaster and modernization effort. The aim would be to preserve the core FreeSpace experience and its strongest ideas while using Unreal's systems and conventions by default. Unreal can take over rendering, audio, input, UI, physics, networking, packaging, and editor workflows. The remaining work is still substantial: deciding which FSO gameplay rules define the experience, rebuilding those systems around Unreal, and moving the selected content and campaign material.

The gameplay code is not currently a clean library that can be lifted into Unreal. It operates on FSO-owned object and ship arrays, global mission state, custom math and physics, and frame processing that also triggers rendering and effects. Some algorithms, parsers, and authored data may be reusable after isolation, but gameplay systems should be redesigned around Unreal actors, components, assets, and lifecycle. A useful initial target is a single-player vertical slice that captures the FreeSpace feel in a representative encounter, then tests modern Unreal movement, collision, AI, and content workflows. It should measure whether the result feels right and supports the desired mission design; matching every FSO value or outcome is not the goal.

Unreal Engine 5.8 is an available release as of June 2026. Epic describes it as the last planned major UE5 release on its current roadmap, with continued fixes and the possibility of another 5.x release. Pinning to 5.8 therefore gives a concrete target, but the project should record its engine fork or launcher build and plan for maintenance of that version. See Epic's [UE 5.8 announcement](https://www.unrealengine.com/news/unreal-engine-5-8-is-now-available) and [5.8 documentation](https://dev.epicgames.com/documentation/en-us/unreal-engine).

## What would move

The Unreal project would own the player experience and platform integration:

| Area | Likely Unreal-side responsibility | FSO material to preserve or port |
| --- | --- | --- |
| Game flow | Unreal GameMode, GameInstance, levels, UI, input, save/config integration | Campaign rules, mission transitions, briefing/debrief semantics, pilot progression |
| Simulation | Actor/component lifecycle, collision, movement scheduling, replication primitives | Flight model, ship state, subsystem damage, weapons, AI, mission objectives and event semantics |
| Content | Unreal assets and Asset Manager loading | Model/table/mission/campaign metadata, names and stable identifiers, mod override rules |
| Rendering and audio | Unreal renderer, materials, effects, sound, animation and audio mixing | Source asset interpretation and gameplay events that request effects or sounds |
| Authoring | Unreal Editor tools, data validation, mission preview | Relevant FRED workflows and file compatibility, if existing mission authors must be supported |
| Networking | Unreal networking and replication, if multiplayer remains in scope | FSO multiplayer rules, protocol behavior, authoritative simulation and compatibility expectations |

The first release should define what makes the remaster recognizably FreeSpace: for example, the scale and presentation of capital-ship battles, squadron command, mission-driven storytelling, weapon roles, and the campaign's pivotal choices. Then define which original missions, assets, and mod formats are worth carrying forward. Full support for every historical mod feature, multiplayer mode, editor workflow, and platform is a separate compatibility commitment, not a prerequisite for a successful remaster. A sensible first milestone is a focused single-player experience built around a selected mission set.

## Codebase fit and likely boundaries

The repository groups code into gameplay-oriented areas such as `ai`, `mission`, `object`, `physics`, `ship`, `weapon`, `events`, `actions`, `scripting`, `network`, and `pilotfile`, alongside engine-facing areas such as `graphics`, `render`, `sound`, `bmpman`, `io`, `ui`, and platform/OS code. The CMake target links these areas into a single `code` library with SDL, OpenAL, Lua, image libraries, parsers, and other platform services. The directory names are useful inventory, not proof of independent modules.

The highest-value experience to preserve is likely:

* Mission-driven squadron combat: clear objectives, useful wingmate commands, dramatic capital-ship encounters, and a satisfying rhythm from arrival through combat to departure.
* Distinctive ship and weapon roles, readable subsystem damage, tactical choices, and responsive fighter control. Their implementation and tuning can change to improve the experience.
* Selected campaign stories, character dialogue, and authored encounters, migrated into a maintainable Unreal-native content model.
* Player progression and multiplayer if they are part of the chosen remaster scope.

S-expression evaluation, Lua APIs, table override semantics, and mod support are means of preserving and authoring content, rather than goals in themselves. Keep or adapt them where they materially reduce migration cost or retain useful community content. Otherwise, convert the selected behavior into Unreal-native mission data, C++ systems, Blueprints, or editor tooling.

The main porting obstacle is that these systems share engine data structures. `object` instances are processed in a central pre/post movement loop; ship, weapon, AI, physics, collision, and effect code all touch that lifecycle. Physics uses FSO's own integrator and mission gravity, while AI and weapons call one another through object indices and global registries. Unreal should be the default choice for actor lifecycle, movement, collision, animation, input, UI, audio, rendering, asset loading, and networking. Preserve custom FSO behavior selectively when it creates a defining gameplay quality or when a prototype demonstrates that Unreal's standard system cannot deliver the desired result. Evaluate those exceptions case by case. A focused slice will expose the meaningful tradeoffs without assuming that all existing systems need replacement on a one-for-one basis.

Unreal's tick, physics, collision, and networking choices will produce different behavior from FSO. That is acceptable when the new behavior improves responsiveness, reliability, or maintainability while preserving the intended experience. Use Unreal's standard systems first, then tune them against player-facing goals such as intuitive fighter control, readable combat, credible large-ship encounters, and useful squad commands. Add custom simulation only for specific qualities that cannot be reached through Unreal configuration or extensions. Multiplayer, if selected, should use Unreal networking as its starting point and define new expectations rather than promising wire-level or outcome equivalence with FSO.

## Content and conversion strategy

FSO content is not limited to meshes and textures. The runtime's virtual file system indexes separate content families, including `.pof` models, `.tbl`/`.tbm` tables and Lua, `.fs2`/`.fc2` missions, `.vp` archives, image formats, sounds, movies, and scripts. `cfile` defines search paths and extension groups and supports packaged/overridden data. Keeping this content behavior matters for mods: an Unreal asset registry alone will not reproduce FSO's filename lookup and layered override rules.

The repository contains source and parser tests, but generally not the retail game data needed for representative asset conversion. Before estimating conversion coverage, assemble a locally available sample selected for the proof of concept: a range of ship types, mission scenarios, campaign data, and any community-created material useful to the experiment. The importer can read loose files and VP archives when needed, but it should focus on extracting the selected content and report fields that need redesign or manual review. It does not need to support every legacy file or mod feature to be useful.

Use a two-stage import pipeline:

1. **Read selected legacy formats into a neutral intermediate representation.** Reuse or extract FSO parsers where the license permits, and preserve the data needed to reconstruct the chosen content: identifiers, coordinate systems, hierarchy, hardpoints, subsystem paths, shields, collision volumes, LODs, material slots, thruster/glow points, animation data, and table references. Allow the conversion step to normalize or redesign data where a direct mapping would preserve an obsolete implementation detail. Keep source provenance and conversion notes alongside generated outputs.
2. **Create Unreal-native assets through the Unreal Editor.** An editor plugin or commandlet turns the intermediate representation into meshes, materials, textures, animation/rig assets where appropriate, and typed data assets. Use native Unreal conventions for asset organization and gameplay data. Do not attempt to write `.uasset` files in a standalone converter; let the target engine serialize its own packages.

For `.pof` models, the converter must account for FSO-specific subobjects and ship metadata, not just produce a visually similar mesh. It may emit a skeletal hierarchy for moving subobjects, one or more static meshes for fixed geometry, collision representations, and a metadata asset consumed by a ship Blueprint or C++ actor. Material and texture conversion needs explicit mapping for diffuse, glow, specular, normal, transparency, and other supported legacy maps. Unreal's [Interchange Framework](https://dev.epicgames.com/documentation/unreal-engine/interchange-framework-in-unreal-engine) is customizable and extensible, and its [Python import workflow](https://dev.epicgames.com/documentation/unreal-engine/importing-assets-using-interchange-in-unreal-engine?lang=en-US) can help automate supported interchange formats. A POF-to-intermediate converter remains project-specific. Unreal [Data Assets](https://dev.epicgames.com/documentation/unreal-engine/data-assets-in-unreal-engine?application_version=5.8) provide a reasonable native home for ship, weapon, species, and mission definitions; `UPrimaryDataAsset` and Asset Manager bundles can support discovery and selective loading.

Tables should first become validated structured data, then map to typed Unreal data assets or tables. Carry forward only the override behavior needed by the selected content and mod policy; Unreal asset references and native data ownership should be the default. For missions, prefer a custom `UPrimaryDataAsset` or equivalent schema with stable IDs and references to ships, weapons, waypoints, goals, and events. An importer can map FSO mission concepts into this schema, with a review step for concepts that need redesign. Unreal assets and mission tooling should become the source of truth for new content, while the original files remain import sources where useful.

Possible content migration modes are:

* **Curated remaster (recommended starting point):** import a selected set of legacy content, then maintain and extend it as Unreal assets and mission data. This supports deliberate redesign and keeps runtime behavior native to Unreal.
* **Mod import path:** retain an editor-side import workflow for community content the project chooses to support. It can surface unsupported constructs and guide authors through conversion without promising drop-in compatibility.
* **Legacy runtime compatibility:** load legacy files and VP archives directly only if continued use of unconverted mods becomes a product requirement. This has the highest compatibility cost and should be evaluated separately.

Epic documents Unreal's standard [asset import pipeline](https://dev.epicgames.com/documentation/unreal-engine/fbx-content-pipeline?lang=en-US) for common mesh formats. It can handle interchange outputs, but it does not replace the custom readers and semantic conversion required for POF, VP, table, mission, and campaign data.

## High-level implementation plan

### Phase 0: Define the proof-of-concept scope and success criteria

Define a bounded personal experiment: the core experience to preserve, changes to test, target platform and controls, one representative encounter, its selected content, minimum import/debug tooling, and the multiplayer decision. State that Unreal-native systems are the default and document the criteria for custom exceptions. Inventory the code and content each required mechanic touches. Decide which campaign/save behaviors are needed to prove the encounter and defer the rest. Legal perimeter, counsel review, asset clearance, distribution, and release planning are outside the current workstream.

Write down the questions the prototype must answer: can the fighter handling and capital-ship combat feel right; can POF/table/mission data retain required gameplay semantics; can imported events run and be debugged; and can the encounter run as a local packaged build? Select a small content set already available locally and record its paths, versions, and hashes for reproducibility. Source tracking here serves conversion/debugging, not a clearance audit. The owner can hold all project roles; formal staffing and production estimates are unnecessary until the proof provides useful evidence.

**Exit check:** a short experiment brief, a chosen encounter and available dependency set, required versus deferred mechanics, control/platform and compatibility decisions, and observable acceptance criteria. No legal or release approval is required to pass this planning gate.

### Phase 0.1: Set up and verify the Unreal project

This is the first implementation task and does not depend on completing the mission dependency inventory or importer design. Locate and record the installed UE version; use the planned 5.8 build if available, and resolve an engine-version change explicitly if it is not. Verify its required Visual Studio/MSVC and Windows SDK toolchain. Create a minimal desktop C++ project in an agreed workspace location, with `.uproject`, runtime module, editor/game targets, source/config directories, and appropriate generated-file ignores. Keep its build independent of FSO's CMake targets.

Create an empty lighting test map with a camera/player start, simple geometry, a directional light, environment fill and explicit exposure settings. Establish the initial renderer configuration and record it; advanced rendering choices can wait for imported content. Provide reproducible build/open/run instructions and confirm that the project compiles, opens in the editor, runs in Play In Editor, and cooks/packages/runs locally. Commit the reproducible project files under the chosen binary-asset storage policy. Add the editor importer module in the next step; a converter is not a prerequisite for accepting project setup.

**Exit check:** a fresh project build succeeds, the editor opens its test map, Play In Editor works, and a local packaged executable runs the map. Record the exact engine/toolchain, project path and commands. This establishes the host for all subsequent content and gameplay work.

### Phase 0.2: Render the existing Myrmidon in a UE level

This is the first content milestone, immediately after project setup. Resolve the GTF Myrmidon's model and texture references from the existing ship definition and POF metadata; convert its visible geometry, normals, UVs and material slots plus existing PCX textures into native UE mesh/texture/material assets. Place the ship in a saved UE level at verified scale/orientation under the project lighting profile. Implement only the discovery/conversion/import functionality needed for this ship now; the complete mission dependency graph, Psamtik, hardpoint/subsystem runtime, flight controls, weapons and AI are not prerequisites for this visual milestone.

**Exit check:** the existing textured Myrmidon renders in a saved UE level, responds to changes in UE lighting, and has correct normals, material assignments, scale and orientation. Record the source/model identity, import commands and comparison screenshots. Reimport updates the same assets without duplicates, and the level runs in a local cooked build. Geometry preservation should not depend on finishing gameplay metadata interpretation; retain unresolved source metadata for the next milestone.

### Phase 0.5: Expand to the mission's content and lighting scene

Expand Phase 0.2's working Myrmidon import with source discovery manifests, semantic schemas, gameplay metadata and repeatable package creation for the remaining content. Inventory the selected mission before implementing its gameplay. Resolve ships/weapons/tables and their model, texture, effects, sound, background, briefing, and debrief dependencies, including dependencies reached through events, reinforcements, messages, and scripts. Add Psamtik and the other required ships, table definitions, hardpoints/subsystems and mission placement data as native UE assets. Implement other format families as soon as the inventory shows they are required.

First deliver a repeatably imported lighting test map showing those ships at correct scale and orientation with UE materials, direct light/shadows, background/environment lighting, and emissive surfaces. Then expand that map to the chosen mission's starting arrangement. This gives movement, targeting, weapons, AI, and collision work real content to test against from the beginning. Geometry/material/metadata import and mission semantic analysis take precedence over broad gameplay implementation.

**Exit check:** actual mission models and textures can be inspected under UE lighting; required hardpoints/subsystems and placements validate; imported data assets resolve stable references; unchanged-source reimport preserves identity; a local cooked build loads this initial content without FSO files at runtime. The inventory identifies every remaining mission dependency and its conversion/support status. This is a content readiness gate, not a requirement to finish all event execution before gameplay work starts.

### Phase 1: Establish a minimal foundation and prove one mission

Use the selected SM1-01 encounter and capture reference footage, mission intent, and selected gameplay metrics such as player handling, time-to-kill, wing survival, weapon usefulness, and event outcomes. Build on the existing UE project using Unreal movement, collision, AI, animation, effects, and audio workflows. Implement player control, required ship classes, weapons, wings/turrets, capital-ship interaction, damage, and every required mission stage. Tune and judge the result as a remaster. Record intentional differences from FSO and whether they improve the target experience.

Before building the encounter, establish only the foundation it needs: a pinned UE project, runtime/editor module separation, stable entity IDs, movement and damage interfaces, mission lifecycle, a minimal importer, and an automated packaged smoke test. Content ingestion and gameplay prototyping must run together here; a hand-built slice alone cannot prove that selected legacy content is convertible. Use placeholders to unblock handling experiments, then replace them with representative imported assets before accepting the slice. Phase 2 hardens these interfaces rather than introducing them after the proof.

Build on Phase 0.5's imported content and lighting baseline. Implement SM1-01's complete flow rather than substituting a new encounter with easier logic. If a required mechanic is too costly, report the limitation and revise its implementation plan; changing the selected mission is a scope decision for the owner. Do not silently remove required events and call the original mission migrated.

**Exit check:** the UE slice delivers the intended FreeSpace encounter and demonstrates that its content can be authored and iterated efficiently. The review identifies which custom FSO systems are worth retaining and which Unreal systems meet the goal. This is the main go/no-go point for the larger effort.

### Phase 2: Establish the Unreal gameplay foundation

Beyond the initial proof unless a specific slice requirement needs this work. Harden only the interfaces demonstrated by the slice before committing to broader production architecture.

Implement Unreal C++ modules and assets around clear domains: mission runtime, ship and subsystem components, weapons/projectiles, AI orders, data definitions, campaign state, and Unreal-native mission scripting or event authoring. Define stable gameplay IDs and explicit adapters at legacy import boundaries. Reuse isolated FSO algorithms and parsers when they save effort or preserve valued behavior; otherwise implement the feature in Unreal idioms. Use Unreal ownership and subsystem patterns instead of carrying over central globals. Set tick and simulation policies based on the desired game feel, with measured custom code only where needed.

Do not port renderers, sound backends, SDL input, or FRED's desktop UI. Translate gameplay requests into Unreal-facing interfaces for effects, sound, HUD, and input, then implement those through Unreal systems.

### Phase 3: Scale content ingestion and asset production

Implement archive and loose-file discovery, parsers, an intermediate representation, reference validation, deterministic naming, conversion manifests, and repeatable editor import. Start with POF models and the table families required by the vertical slice. Add mission and campaign import next. Track unsupported fields and lossy conversions in machine-readable reports. Make reimport safe and stable so updated source files update the intended Unreal assets rather than creating duplicates.

### Phase 4: Build out the remaster

Add the chosen ship and weapon roster, mission events, campaign progression, player progression, HUD-facing state, and other defining features in priority order. Convert selected S-expression and Lua behavior into the new mission authoring model where that keeps content understandable and maintainable; implement compatibility interpreters only where conversion is impractical or community support warrants them. Validate with representative authored missions, play sessions, and focused regressions. If multiplayer is included, decide its authority and movement strategy in Phase 0 and prove a small networked encounter in Phase 1 or 2. Expand multiplayer as its own production workstream once the gameplay interfaces stabilize; deferring all network design until single-player is finished risks rewriting movement, damage, mission events, and persistence.

### Phase 5: Authoring, packaging, and release readiness

Provide Unreal Editor tools for authoring missions, placing and debugging mission entities, validating assets and references, and importing selected legacy content. Treat FRED as a source of proven workflows and design ideas, then implement the editor experience that suits Unreal and the remaster. Add cook and package validation, asset dependency audits, save/campaign migration, performance budgets, and clear mod creation or import guidance for the supported scope. Maintain a representative content and gameplay regression set for each release.

## Key risks and how to retire them

The largest risks are the boundaries between FSO gameplay and its engine, and the effort required to turn selected legacy content into a strong Unreal-native experience. Asset import by itself is not the main measure of feasibility. The first playable slice should test combat feel and implementation seams; a small set of content imports should test whether the campaign and ship data can move into the new authoring model without losing the qualities the remaster wants to preserve.

### Combat feel and Unreal system choices

FSO's flight response, combat pacing, weapon roles, and the scale of fighter-versus-capital-ship encounters contribute to its identity. Unreal supplies movement, physics, collision, animation, and networking, but using those systems does not automatically reproduce a compelling space-combat experience. Start with Unreal defaults, tune them against clear player-facing goals, and add custom simulation only when a specific prototype shows that built-in systems cannot deliver the intended result. Test fighter control, weapon usefulness, damage readability, wingmate utility, and capital-ship interaction in one representative encounter.

### Gameplay code is not a set of independent modules

The gameplay and engine-facing code share object lifecycles, global state, and update loops. Ship, weapon, AI, physics, collision, and effects code depend on common FSO data structures; the directory layout does not define safe porting boundaries. The CMake build also combines much of this code into one static `code` library. Estimate the work from traced feature flows and prototypes, not by counting files in gameplay-named folders. For the vertical slice, map one encounter from mission load through simulation and mission completion, then decide what to reuse, adapt, or rebuild in Unreal.

### Mission and campaign conversion can require redesign

FSO missions encode behavior through objectives, events, timing, AI orders, S-expressions, and Lua hooks. Translating a mission file into a new data asset may preserve its placements while losing the logic that makes the encounter work. Convert one representative mission and document where manual redesign is needed. For selected campaign content, treat mission intent and story as the preservation target; carry forward legacy scripting only when it makes migration simpler or retains valuable community-authored behavior.

### Ship conversion must preserve useful gameplay semantics

A POF converter has to account for hardpoints, turret paths, moving subobjects, collision shapes, and other gameplay data, as well as visible geometry and materials. A model can look correct and still behave incorrectly in combat. Prototype conversion with unlike ships, such as a fighter, a turreted capital ship, and a ship with animated subobjects. Validate each in Unreal for visual quality, flight or collision behavior, weapon placement, and mission use before estimating batch conversion.

### Compatibility scope can dominate the effort

FSO's VP archives, file lookup, override rules, table formats, scripts, and editor workflows support a broad mod ecosystem. A curated remaster can select content and avoid drop-in compatibility, but supporting arbitrary existing mods adds long-tail parsing, conversion, and support requirements. State which campaigns and community content are in scope. Treat a legacy runtime loader as a separate product decision; an editor-side importer with clear unsupported-feature reports is a more bounded starting point.

### Rights apply to code and content separately

Deferred for this private proof of concept. If the project later changes to a distributable prototype or release, revisit source-code and content rights as a separate workstream. This is not a current feasibility gate.

| Risk | Why it matters | Early evidence to seek |
| --- | --- | --- |
| Gameplay is coupled to FSO engine structures | A large amount of nominally gameplay code may need adaptation or rewriting | Trace one encounter's call/data flow and implement the vertical slice before estimating by folder size |
| Unreal defaults do not produce the intended game feel | Modern engine behavior can change control response, combat pacing, and large-ship encounters | Tune a representative encounter with players and retain custom behavior only when it materially improves the result |
| Content conversion loses useful model semantics | POF stores hierarchy, hardpoints, paths, and collision data that may matter to gameplay | Convert several ship types and validate visual quality, handling, weapons, and mission use |
| Scope expands into full legacy compatibility | Overrides, scripts, custom tables, and VP archives have broad behavior and long-tail cases | Decide which community content to support; build import reports for that corpus and defer unsupported runtime compatibility |
| Mission conversion loses authored intent | SEXP and Lua behaviors are embedded in mission/mod ecosystems | Inventory selected campaigns, map their intent into Unreal-native mission logic, and flag cases requiring manual redesign |
| Licensing or asset rights limit distribution | The source tree has mixed terms and the game data is separate from the code | Complete a file and asset provenance audit before a distributable prototype |
| Editor scope becomes a second project | FRED contains substantial mission-authoring functionality | Decide the minimum authoring requirement and test an import-and-debug workflow with mission authors |

## Detailed engineering and delivery plan

The following decisions and acceptance criteria make the high-level phases actionable. Proposed defaults are starting hypotheses to validate, not approved scope or measured performance claims.

### Scope contract and decision register

Maintain a decision register with an owner, alternatives, evidence, chosen option, review date, and downstream consequences. Record deliberate gameplay changes separately from importer limitations and defects. Every selected mission needs an acceptance sheet describing its story beats, required mechanics, permitted redesign, and expected success/failure paths.

| Decision | Proposed starting point | When it must be resolved |
| --- | --- | --- |
| Product and content | Curated single-player remaster; select one actual encounter and its complete dependency closure | Before slice implementation |
| Platforms and controls | Windows desktop; keyboard/mouse and one gamepad baseline, with joystick/HOTAS requirements explicitly decided | Phase 0; input abstraction before slice |
| Engine and renderer | Pin an exact 5.8 patch/build and Windows toolchain; benchmark a conventional desktop rendering baseline before enabling expensive features | Project creation |
| Movement | Compare a Pawn with a project movement component against a Chaos-driven prototype | Slice handling gate |
| Compatibility | Editor import of selected legacy content; no promise of arbitrary mod, save, or multiplayer protocol compatibility | Before converter schema stabilizes |
| Multiplayer | Excluded from first release unless explicitly selected; if selected, prototype authority and prediction early | Phase 0 |
| Mission logic | Typed conditions/actions with explicit lifecycle and debugging; use Blueprints for bounded extensions | Before importing event logic |
| Save policy | New versioned campaign/profile format; separate decision for legacy progress import | Before campaign production |
| Authoring ownership | Generated import assets plus separate hand-authored overrides; UE-native data owns new missions | Before first reimport |
| Distribution and rights | Private, personal, noncommercial proof of concept; no release in this form | Resolved for current scope; reopen only if distribution is proposed |

Explicitly decide whether red-alert carryover, escort/protection, docking/rearm, scanning/cargo, beams, stealth/sensors, nebula missions, support ships, training, command briefings, fiction, medals, branching campaigns, and player ship selection belong in the first release. These are common sources of dependencies hidden behind a simple phrase such as “port the campaign.” VR, dedicated servers, console support, runtime mod loading, full FRED replacement, and broad Lua compatibility should be separately estimated scope additions.

### Repository evidence and reuse investigation

Use the following source areas as investigation entry points. They identify behavior to trace, not components ready to link into Unreal.

| Source area | Questions to answer before reuse or redesign |
| --- | --- |
| `code/object/object.cpp`: `obj_move_all`, `obj_move_all_pre`, `obj_move_all_post` | Which behaviors depend on movement order, deferred creation/deletion, subsystem animation, countermeasures, collision, or script hooks? |
| `code/physics/physics.cpp`: `physics_sim`, `physics_sim_vel`, `physics_sim_rot` | Which acceleration, damping, turning, afterburner, and impulse characteristics define handling? Which constants carry units? |
| `code/ship`, `code/weapon`, `code/ai`, `code/object` collision code | Which shield/subsystem/weapon/AI rules are required by the selected encounter, and which cross subsystem boundaries? |
| `code/mission/missionparse.cpp`, `code/mission/missioncampaign.cpp`, `code/parse/sexp.cpp` | How do arrival/departure, event evaluation, terminal expression states, campaign variables, and branching interact? |
| `code/model/modelread.cpp`, `test/src/model/test_modelread.cpp` | Which POF versions/chunks are used by the corpus, and what model metadata is required beyond geometry? |
| `code/cfile`, `test/src/cfile`, `code/ship` and `code/weapon` table parsing | What is the effective source after search paths, archives, modular tables, and overrides are applied? |
| `code/scripting`, `code/actions`, `code/events` | Which selected scripts/hooks/actions depend on FSO globals, object handles, frame timing, or rendering? |
| `code/missionui`, `code/pilotfile` | What briefing, loadout, debrief, scoring, campaign, and red-alert state must survive transitions? |
| `code/CMakeLists.txt` | Which reused files drag in engine/platform dependencies? The static `code` target links SDL3, OpenAL, Lua, image libraries, and additional services. |

Produce a feature-by-feature reuse ledger: source files and provenance, required behavior, dependencies, proposed extraction boundary, retained tests, and estimated extraction versus rewrite cost. Do not link the entire FSO `code` library into UE as the default shortcut. Parsers may initialize tables, models, logging, or globals; demonstrate that an extracted reader runs on fixture data without initializing FSO rendering/audio before calling it independent.

Freeze a reference manifest containing the FSO Git commit, executable/build configuration, command line, mod stack and ordering, content hashes, settings, difficulty, random seed where controllable, and capture hardware. Keep the existing FSO build usable throughout discovery. Do not assume the current test suite is a complete gameplay oracle; reuse format fixtures and add reference captures for behaviors that selected missions actually exercise.

### Unreal project structure and ownership

Start in a separately buildable UE project, with a recorded repository/location decision. Keep FSO's CMake build and UnrealBuildTool targets independent. Establish Git LFS or another agreed binary-asset storage policy before importing large assets. Ignore generated `Binaries`, `Intermediate`, local `Saved`, and local derived-data outputs; version project configuration, source, import schemas, manifests, and required source/generated assets under the chosen policy. Do not commit licensed engine source or retail content by accident.

Suggested boundaries, which can initially be folders within a few modules rather than many tiny modules:

* **Runtime core:** stable IDs, typed data definitions, save schemas, mission conditions/actions, and shared gameplay contracts. Avoid editor dependencies and central mutable global registries.
* **Ship/combat runtime:** ship Pawn/Actor composition, movement, weapons, shields, subsystem state, sensors/targeting, AI orders, collision, and damage resolution.
* **Mission runtime:** a world-scoped mission subsystem and entity registry, encounter lifecycle, objectives, event scheduling, and presentation requests.
* **Player/presentation runtime:** PlayerController, input actions, camera, HUD/view models, audio/VFX adapters, menus, briefing, and debriefing.
* **Campaign/profile services:** GameInstance-scoped state for progression and selection; persistence stores serializable state, never live Actor pointers.
* **Editor import/authoring:** readers or an adapter to an external converter, factories/commandlets, validators, previews, mission tools, and source provenance. Editor modules must not be dependencies of packaged runtime modules.

Use immutable authored definitions and separate mutable runtime state. Ship and weapon definitions reference assets through deliberate loading contracts; Actors own instances. A subsystem's identity must remain stable when its mesh changes. Resolve gameplay handles through mission IDs and generation/lifetime checks rather than copying FSO array indices into the new engine. Presentation consumes state/events and cannot become the authoritative source for damage or mission progress. Pooling must reset timers, subscriptions, ownership, hit history, and mission IDs before reuse.

Use C++ for core rules and hot paths, data assets for authored tuning, and Blueprints for ship composition and presentation. Select Gameplay Ability System, Mass, StateTree, Behavior Trees, World Partition, or other larger frameworks only after a specific requirement and prototype justify the dependency. Space AI needs three-dimensional steering and tactical logic; a ground navigation mesh or a behavior graph alone does not supply those systems.

### Movement, units, timing, and collision

“Use Unreal physics” needs a concrete interpretation. Actor ownership and UE collision queries can be used with a custom movement component without simulating the fighter as a rigid body. Compare two small prototypes: controlled kinematic movement with sweeps, and force/torque-driven Chaos movement. Judge acceleration/deceleration, angular response, lateral movement, afterburner, collision recovery, AI steering, and input latency. Choose the simpler approach that achieves the intended handling; rigid-body realism is not itself an acceptance criterion.

Define the import transform once, then apply it to geometry, normals/tangents, pivots, hardpoints, paths, velocities, angular quantities, and mission placements. UE uses a left-handed, Z-up coordinate system; see Epic's [coordinate-system documentation](https://dev.epicgames.com/documentation/en-us/unreal-engine/coordinate-system-and-spaces-in-unreal-engine). Verify the FSO basis from its matrices and fixtures instead of assuming it matches UE. A starting conversion to test is FSO forward/right/up to UE X/Y/Z; prove axis signs, winding, quaternion conversion, and parent-local transforms using an asymmetric fixture. Adopt UE centimeters and seconds internally, documenting and verifying the source-unit scale. Convert distances, velocities, accelerations, ranges, radii, and damping parameters consistently; damage and abstract gameplay values need semantic mapping rather than a length multiplier.

Establish a simulation scheduling contract before adding many independent Actor ticks:

1. Collect player/AI intents and validate queued mission commands.
2. Advance movement, moving subobjects, and weapon state under the chosen timestep policy.
3. Resolve collision/hits into immutable hit records and apply authoritative damage once.
4. Commit destruction, arrivals/departures, subsystem changes, and registry mutations at defined boundaries.
5. Evaluate mission conditions against the documented state snapshot; queue resulting actions.
6. Publish HUD/audio/VFX events and interpolate presentation as appropriate.

This is a proposed order, not a claim that FSO executes exactly this sequence. Trace selected mechanics and choose explicit same-step/next-step semantics. Specify tick prerequisites, simulation versus wall-clock time, pause/time dilation, hitch handling, maximum catch-up steps, and random-stream ownership. Physics substepping does not automatically make every gameplay timer or AI update fixed-step. Epic also documents delayed/multiple collision callbacks in [physics substepping](https://dev.epicgames.com/documentation/unreal-engine/physics-sub-stepping-in-unreal-engine); normalize callbacks and deduplicate authoritative damage by attack/hit identity.

Use separate collision channels/policies for hulls, shields, projectiles, sensor queries, beams, docking, and debris. Decide shield quadrant selection and shield-to-hull penetration explicitly. Validate continuous sweeps or another suitable high-speed hit method against thin geometry and moving targets; endpoint overlaps are insufficient. Define beam sampling, piercing and area-damage rules, friendly fire, source attribution, and how an impact identifies a moving subsystem. Do not assume render LOD or Nanite geometry is the gameplay collision representation.

For capital ships, prototype convex/compound hulls or query-only detailed geometry with simpler physical interaction shapes. Test approach, collision, turret tracking, destroyed-subsystem behavior, and departure near other vessels. Docked assemblies need explicit parent/relative-motion ownership and collision suppression rules. A fighter must not gain unpredictable energy from a moving capital ship or rotating turret.

Measure the maximum supported mission extent and projectile range. UE's [Large World Coordinates](https://dev.epicgames.com/documentation/en-us/unreal-engine/large-world-coordinates-in-unreal-engine-5) helps CPU coordinate precision, but it is not evidence that every physics, material, effect, or replication path remains accurate at arbitrary distances. Test the actual mission envelope and local-coordinate effects; choose origin management only if measurements require it. Use sky/background representations for distant scenery instead of inflating playable geometry unnecessarily.

### Mission semantics, AI, and campaign continuity

Inventory the selected corpus before designing a universal mission interpreter. Generate operator/hook usage counts and a dependency graph for missions, campaigns, tables, models, media, and scripts. Classify each used construct as automatic conversion, supported runtime behavior, manual redesign, or blocking unsupported behavior. Unsupported event logic must prevent acceptance of the mission; silently dropping it is not a successful import.

The mission schema should cover stable mission/entity/wing/event IDs, placements, waves and reinforcements, arrival/departure rules, loadouts, teams and relationships, waypoints and docking links, objectives and dependencies, messages, timers, variables, and campaign output. Distinguish definitions from spawned instances: a not-yet-arrived ship, a destroyed ship, and a departed ship are different states, even though all may lack a live Actor.

Define conditions and actions with explicit types and state. Preserve selected semantics for repeating events, trigger limits, delays, event ordering, one-shot actions, terminal true/false or unavailable values, persistent variables, and mission logs used by later conditions. A direct conversion of every S-expression to a boolean Blueprint expression loses these distinctions. Blueprint callbacks should invoke typed mission actions through the same validation path as imported events. Document how imported Lua hooks are rewritten or supported; arbitrary Lua compatibility remains a separate commitment.

Keep gameplay events separate from cosmetic messages. Specify whether newly spawned entities become visible to conditions immediately or at the next evaluation boundary, and define cancellation when an entity dies/departs while a delayed action is pending. Provide a mission debugger with active conditions, evaluation values/reasons, queued actions, entity lifecycle, timers, and a timestamped event log. Authors need to diagnose why a wing did not arrive without stepping through C++.

AI requires perception, target selection, tactical state, steering, firing authorization, and squad command acceptance. Cover attack/guard/escort, subsystem targeting, evasive behavior, formation, disengage, turret arcs and line of fire, and docking/rearm only as required by scope. Schedule costly decisions at lower frequencies while retaining responsive movement and firing checks. Validate commands when targets disappear or relationships change; show rejected/accepted orders to the player. Match encounter intent and tactical usefulness rather than copying every historical AI quirk.

Implement a complete front-end-to-debrief path before multiplying missions: briefing, ship/weapon selection, mission launch, pause/retry, success/failure, debrief, and next-mission selection. Campaign branch evaluation must use persisted output, not Actors from an unloaded world. Separate immutable campaign definitions, profile preferences, and mutable campaign state. Decide red-alert transfer of hull, subsystem, ammunition, and survivor state explicitly. Adopt versioned saves, schema migrations, stable content IDs, atomic writes with recovery, and a missing-content policy. Mid-mission saves/checkpoints require serializing mission evaluator/timer/random/entity state and are a separate feature from between-mission campaign saves.

### Content conversion contract and safe reimport

#### Existing format inventory and Unreal asset destinations

This inventory is grounded in `code/cfile/cfile.cpp`'s `Pathtypes`, plus the model, bitmap/animation, mission, table, and scripting loaders. The path registry lists candidate formats, not a guarantee that every format occurs in the selected installation or has a complete reader. The first pipeline job must enumerate the actual loose/archive contents and identify loader variants. Where semantics are uncertain, inspect the reader and classify the file before promising conversion.

Priority is dependency-driven: **early** establishes the first real-content lighting scene; **mission** is required before end-to-end acceptance when referenced; **deferred** is outside the single-mission goal unless the inventory proves otherwise. All `.uasset` packages are serialized by UE editor factories/commandlets, not written by the external converter. A level is a `.umap`; media can also require separately staged non-package files. Not every source file should become its own `.uasset`.

| Existing file family | Legacy role and discovery | Conversion plan and UE destination | Priority and proof |
| --- | --- | --- | --- |
| `.vp` archives and loose directories | Content containers and layered lookup; `code/cfile` and archive tools | Read/index archives and loose roots, reproduce selected lookup precedence, export resolved source files plus manifest. No VP asset/runtime mount needed; contained data becomes native assets | Early: same logical reference selects the same source as the reference FSO setup |
| `.tbl`, `.tbm` | Base and modular definitions in `data/tables`; also config tables | Parse and merge supported families into typed IR, then ship/weapon/species/AI/sound/environment/HUD/animation data assets or typed DataTables. Preserve effective values, units, identifiers, provenance, and references; table scripts are separate work | Early: ships/weapons/material dependencies; mission: remaining families used by the chosen mission |
| `.pof` | Ship, weapon, asteroid, debris, cockpit and other model geometry/metadata | Custom reader to geometry plus semantic IR; editor creates `UStaticMesh`, optional `USkeletalMesh`/rig, collision, and ship/model metadata assets. Build reusable ship composition from these; do not bake runtime health into meshes | Early: correct textured fighter and large ship; mission: all referenced models and gameplay metadata |
| `.png`, `.tga`, `.jpg`, `.pcx` | Maps, HUD/interface, portraits, insignia, background and effects images | Import supported images through UE; decode PCX to lossless PNG/TGA with palette/transparency rules. Create `UTexture2D`, UI brush references, or background textures. Preserve alpha and role-specific color-space settings | Early: hull/background textures; mission: interface and effects images |
| `.dds`, `.ktx` | Compressed 2D textures, mip chains and possibly cube/environment textures | Inspect dimensions, compression, mip/color/alpha data and cube layout. Try verified UE DDS import where supported; otherwise decode to lossless intermediate images/HDR-capable outputs as needed. KTX requires a verified decoder/custom path. Create `UTexture2D`/`UTextureCube`, letting UE build platform compression | Early: required material maps; validate decoded channels, cube faces, and mip behavior |
| Material map naming/table bindings | Diffuse/glow/specular/normal/height/ambient or other maps, transparent model slots | Build UE master materials plus `UMaterialInstanceConstant` per resolved material. Map legacy channels explicitly; derive reviewed roughness/metallic defaults, preserve normals/emissive/alpha, and expose lighting tuning overrides | Early: existing surfaces respond to UE light and shadows, with no missing slots |
| `.ani` | Legacy packed frame animations used by effects and UI | Decode frame pixels, palette/transparency, dimensions, frame rate and key/loop behavior using animation readers. Emit atlas/flipbook textures plus timing metadata; use Niagara sprite/sub-UV materials for effects and UMG frame playback for UI | Mission when referenced; prove duration, transparency and frame order |
| `.eff` and referenced image sequences | Text animation descriptor referencing separately stored frames | Parse descriptor and resolve every frame; use the same atlas/sequence and timing asset path as ANI. Preserve looping/frame timing and avoid duplicate frame imports | Mission when referenced; missing frames block required animation acceptance |
| POF moving subobjects and table-defined model animations | Turrets, doors, rotating parts, scripted transform sequences; not a separate universal animation file | Convert transforms/pivots and animation definitions into component drivers or skeletal animation assets where appropriate, with typed trigger metadata. Retain subsystem/hardpoint association | Early metadata; mission playback for required moving parts |
| `.fs2` | Mission placements, wings, goals, events/SEXPs, messages, brief/debrief, environmental settings | Parse to versioned mission IR; create `UMissionDefinition`-style primary data asset and referenced definitions, plus a generated preview/lighting `.umap` where useful. Runtime spawns from mission data; preview Actors must not also spawn duplicate runtime ships | Early: dependency graph and starting placements; mission: full logic and flow |
| `.fc2` | Campaign graph, variables, branching and mission selection | Parse enough to obtain selected mission context/defaults; create campaign data asset only if required. For an isolated mission, use a recorded initial-state fixture instead of implementing the entire campaign | Deferred except required entry-state data |
| `.lua`, `.fnl`, `.lc` | Table scripts/hooks, Lua/Fennel source or compiled scripts | Inventory actual hook/operator use and obtain readable source when available. Translate required behavior into typed mission actions/C++/bounded Blueprints, with source-to-behavior reports. Compiled code is not an automatic Blueprint conversion; unavailable required logic is a blocker | Mission when used; broad script VM compatibility deferred |
| `.wav`, audio `.ogg` | Weapon/engine/effect sounds, radio/brief/debrief voice and music | UE audio import to `USoundWave`; normalize to verified WAV if a source variant fails. Create Sound Cue/MetaSound or data-driven playback definitions, attenuation/concurrency and voice/music metadata. Preserve loops, channel layout, gain and message association | Mission: reference-triggered playback and full brief/debrief audio where present |
| `.mve`, movie `.ogg`, `.mp4`, `.webm`, `.msb`, movie `.png` sequences | Cutscenes and related video assets; OGG role depends on path/content | Identify codec/container and inspect MSB reader/use before classifying. Transcode required clips to a codec verified on the pinned Windows player, or create an image sequence. Use MediaPlayer/MediaTexture plus FileMediaSource or image media source; stage media files explicitly | Deferred unless required by the selected mission's flow; packaged playback is the gate |
| `.srt` | Subtitle timing/text associated with movies | Parse to localized subtitle/caption timing data or UE overlay assets after verifying chosen playback path; associate with media and audio timeline | Mission if a required clip uses subtitles |
| `.vf`, `.ttf`, `.otf` | Legacy bitmap/vector fonts | Decode VF glyph metrics/atlas into a project bitmap-font UI path if fidelity is needed; otherwise deliberately substitute a readable UE font. Import supported TTF/OTF into Font/FontFace assets with composite-font fallback | Mission: readable briefing/HUD/debrief; exact VF reproduction optional |
| `.rml`, `.rcss` | libRocket markup and styles | Rebuild the required screen layouts/interactions as UMG Widget Blueprints/styles; retain text/image references through the manifest. No direct CSS-to-UMG asset importer assumed | Mission when required screens depend on these; full UI recreation deferred |
| `.txt`, `.net`, `.xml`, `.csv`, `.cfg` | Fiction, text/localization and configuration; interpretation depends on path/reader | Classify by actual consumer, then create StringTables/localization data, typed config/data assets or UE configuration. Fiction becomes text content for a widget; machine/user settings stay config rather than content assets | Mission for referenced text/defaults; do not import unrelated settings blindly |
| `.neb` and table/mission environment definitions | Legacy nebula/background data plus stars, suns, fog and environment references | Inspect legacy nebula reader; convert required spatial/color settings into environment data assets and UE scene/fog/Niagara/material settings. Background images and sky models use image/POF paths above | Early: chosen mission background and sun direction; nebula fidelity only if required |
| `.sdr`, `.vert`, `.frag`, `.glsl` | FSO shader sources/effect implementation | Reimplement required appearance in UE materials, Niagara or project shaders; retain source as reference, not an executable shader `.uasset`. Do not port the FSO renderer | Early master material; mission required visual effects |
| `.ntl`, `.ssv` | Additional mission-path formats in registry | Inspect their actual readers and enumerate corpus occurrences; document semantics, then map required data to typed assets or config. Do not infer meaning from extension alone | Deferred unless referenced/required; unknown required data stays visible as a blocker |
| `.pl2`, `.cs2`, `.plr`, `.csg`, `.css`, player/bind `.json`, `.hcf` | Pilot/campaign/profile/HUD/control state | Record only the initial state needed by the mission; use new UE settings/SaveGame structures for the prototype. Legacy save/preference import is a separate adapter, not authored `.uasset` content | Deferred; explicit mission entry defaults are in scope |
| `.fsd`, `.clr`, `.tmp`, `.bx`, multiplayer cache, FRED `.html`/`.css` docs | Demos, generated caches, downloaded data and tool documentation | Skip/regenerate engine caches; record reference runs separately; keep docs as docs. No conversion to content assets | Deferred; must not enter runtime dependency closure accidentally |

Epic documents UE's [texture formats](https://dev.epicgames.com/documentation/unreal-engine/textures-in-unreal-engine?lang=en-US) and [audio import](https://dev.epicgames.com/documentation/unreal-engine/importing-audio-files?lang=en-US). Those establish editor capabilities, but every decoder/container variant in the selected FSO corpus still needs an import proof on the pinned build. In particular, do not apply older UE DDS restrictions or assume every KTX/legacy video variant imports directly.

#### Pipeline deliverables and execution order

Prerequisite: Phase 0.1's UE project has already passed its build/editor/PIE/local-package checks. The sequence below covers content work within that project.

1. **Inventory and resolution:** begin with the Myrmidon's model/textures for Phase 0.2. Expand the machine-readable inventory with extension, semantic family, archive/root, selected/shadowed status, size/hash, and parser support in Phase 0.5. Traverse the chosen mission's dependency closure, including dynamically named references in scripts/events. Mark unresolved dynamic references for manual review instead of claiming complete coverage. The full closure is not a gate for first-ship rendering.
2. **Asset contract and import runner:** define stable source IDs/package paths, schema versions, conversion reports and generated/override ownership; create an editor commandlet that produces and saves native packages. A dry run lists outputs and blockers before import. This is the minimum skeleton needed before real content arrives.
3. **First ship rendering, then scene expansion:** first import the existing Myrmidon's mesh/textures/materials and render it in a saved, cooked UE-lit level (Phase 0.2). This does not require a large ship or full mission semantics. After that gate, add Psamtik, required definitions/metadata and mission environment; inspect silhouettes, texture channels, normal orientation, hardpoints, scale and moving-part pivots.
4. **Mission data and remaining assets:** import placements, waves/events, briefing/debrief/messages and all referenced weapons, effects, sounds and UI resources. Produce a support report keyed to specific mission fields/operators. The data can be imported before all corresponding runtime mechanics exist; distinguish successfully parsed data from implemented gameplay.
5. **Playable integration:** use those same assets and definitions for movement, weapons, damage, AI and event execution. Require every mechanic used by the selected mission, with explicit initial-state defaults for campaign-dependent conditions. Update the dependency report when runtime testing reveals implicit assets.
6. **Repeatability and end-to-end proof:** reimport without identity churn, launch a clean local package, play success and failure/retry paths, and verify briefing/debrief, objectives, messages, audio and UE-lit presentation. Preserve reference screenshots and event logs for both runs.

Every format family gets a support record containing corpus examples, reader entry point, resolved semantics, decoder/intermediate format, target UE asset class, package naming, preserved/lossy fields, required runtime consumer, validation evidence, and pending blockers. The inventory matrix above is the plan; the support records become measured implementation coverage. Avoid a single “imported” status that hides whether an asset is merely decoded, serialized, cooked, visually reviewed, or actually working in the mission.

#### Unreal lighting acceptance for existing content

Create a project-owned lighting profile applied to the imported mission environment: movable sun/directional light with recorded source direction/color, controlled sky/environment fill, UE shadowing/reflections, explicit exposure/postprocess settings, and emissive ship/effect materials. Keep existing geometry and images as the visual source; material parameter adjustment is expected to make them work under UE lighting. A legacy glow map is an emissive surface input, not a guarantee of useful scene illumination.

Use explicit, budgeted light sources for important muzzle flashes, explosions, and other local illumination. Benchmark Lumen as an optional enhancement to the baseline and record the chosen GI/reflection method; “UE lighting” does not require every UE rendering feature. Measure bright moving effects, dark hull readability, shadowing near large ships, material response and temporal artifacts using actual imported content. Store lighting settings separately from regenerated assets so reimport cannot erase the experiment's tuning.

Accept the lighting milestone when an imported ship visibly responds to changing UE light direction/intensity, produces appropriate shadows/reflections, retains readable texture/normal/emissive details, and remains readable during combat in a cooked build at the recorded target settings. Capture matching camera views for the FSO reference and UE baseline, plus UE lighting variants. Visual changes should be attributable to the new lighting/material treatment rather than missing textures, reversed normals, a changed model, or an uncontrolled exposure shift.

The converter must resolve the effective legacy content environment before exporting individual files. Preserve source roots, mod dependencies/order, chosen file for each lookup, table merge operations, and shadowed alternatives in a manifest. Filename matching, case collisions across platforms, duplicate identifiers, and modular-table precedence need fixture tests derived from the supported corpus. Do not assume sorting files alphabetically reproduces FSO's lookup and merge behavior.

Define a versioned intermediate representation with source hashes, parser/converter version, source location, stable IDs, source units/basis, references, unsupported fields, and conversion diagnostics. Use a structured interchange for semantic data alongside a suitable mesh interchange or direct editor mesh construction. Geometry interchange alone cannot carry all POF semantics. Keep unknown source fields visible in reports rather than silently discarding them. Bound archive/chunk sizes and validate paths, counts, offsets, and references when processing imported community files.

POF coverage should be measured against a declared version/chunk support matrix. Validate parent hierarchies and local pivots, LODs, normals/UVs/material slots, moving subobjects, turret bases/barrels/arcs, gun/missile banks, thrusters, docking points, paths/bay exits, shield mesh/quadrants, debris, and subsystem associations. Legacy BSP/polygon data and shield/collision data may need separate conversion paths. Moving subobjects can use a skeletal rig or composed static components; choose based on animation/collision requirements and measured cost. Preserve semantic metadata independently of that choice.

Material conversion needs visual approval, not just file-format acceptance. Record sRGB versus linear interpretation, normal-map orientation, alpha modes, UV scrolling/animation, emissive intensity, specular-to-roughness approximation, glow/thruster effects, and texture compression/mips. Inventory animated textures, legacy animation/image formats, video/codecs, font/localization data, and audio loops/attenuation as separate jobs. Legacy specular or glow maps do not have a universally lossless mapping to modern physically based materials.

Use a generated-asset namespace and a manifest mapping source IDs to Unreal package paths. Keep artist-authored materials, tuning, collision overrides, and Blueprint composition in separate assets or explicit preserved override fields. Reimport should stage and validate changes before committing package updates. It must preserve stable references, report deletes/renames, remove stale generated outputs only deliberately, and support recovery from failure. Avoid filesystem ordering and timestamps as semantic inputs. Repeatability means equivalent resolved data and stable asset identity; do not promise byte-identical Unreal packages across engine/toolchain versions.

Accept an import batch only after reference validation, visual review for representative assets, gameplay metadata checks, and an unchanged-input reimport that creates no duplicates or unintended overrides. Test a source change, source deletion, renamed asset, case conflict, failed import, and converter schema upgrade. Retain the source/manifest needed to reproduce a batch under the content-rights policy.

Cooking is part of ingestion, starting with the slice. Editor lookup success does not prove a soft-referenced asset is packaged. Configure primary asset discovery, bundles, soft references, cook rules, and asynchronous mission dependency loading explicitly; Epic's [Asset Manager API](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/UAssetManager) exposes these management/cook concepts. Validate on a packaged build without loose source files or editor caches. Define loading progress, failure messages, cancellation, and unloading at mission transitions.

### Rendering, presentation, and input production

Prototype a dark-space scene with a fighter, a large ship, beams, explosions, and a dense projectile field. Fix exposure and assess scale cues, silhouette visibility, targeting readability, temporal ghosting on fast objects, transparency/overdraw, emissive effects, and distant backgrounds. Compare quality tiers on the minimum target hardware. Treat Lumen, Nanite, hardware ray tracing, volumetrics, and advanced effects as measured options, not mandatory benefits of the migration.

Separate authoritative projectile/beam state from Niagara presentation. Prioritize and pool cosmetic effects, with budgets for distant debris, particles, lights, trails, and decals. Damage cannot disappear because an effect is culled. Use audio buses and priorities so mission dialogue remains understandable over weapon/explosion activity; specify spatialization, loops, occlusion, ducking, subtitle timing, and cutscene transitions.

The HUD needs targeting and subsystem selection, radar/sensors, lead indicators, shields/hull, weapon/ammunition/lock state, squad commands, objectives, messages, and appropriate threat warnings. Validate high-DPI scaling, ultrawide/safe areas, localization expansion, subtitle size, color accessibility, and keyboard/gamepad focus. Input must support rebinding, contexts for flight/menu/briefing, dead zones, sensitivity, inversion, and device disconnection. Decide joystick/HOTAS axis and device support explicitly; adopting Enhanced Input alone does not establish that hardware coverage.

### Validation and performance gates

Create a small supported regression corpus with source paths/versions for every fixture: a fighter; a turreted capital ship; moving subobjects; docking/path data if selected; a simple combat mission; an arrival-wave/escort encounter; and a short branching campaign if campaign behavior is being tested. Include missing references, duplicate IDs, malformed files, and unsupported operators. Use synthetic fixtures where practical and locally available sample content for integration/visual checks.

| Gate | Required evidence |
| --- | --- |
| Discovery | Experiment brief, scope/decision register, reference manifest, available content dependency and operator inventory; project owner holds required roles |
| Project skeleton | Fresh checkout builds; runtime has no editor dependency; placeholder mission cooks and launches; logs report build/content versions |
| First ship rendering | Existing textured Myrmidon renders at verified scale/orientation in a saved UE-lit level; material/normal review and lighting response pass; repeatable import and local cooked run |
| Early content and lighting | Real mission meshes/textures/materials and starting placements import/reimport; semantic metadata validates; UE-lit preview cooks and loads; complete dependency/support report exists |
| Handling/collision | Agreed controls pass player review; 30/60/120 fps and a hitch case have acceptable behavior; fast hits and moving-subsystem impacts resolve once |
| Slice | Selected existing mission playable from launch/briefing through every required stage to success/failure and debrief/retry; required existing models, textures, logic, effects/audio and UI work under UE lighting; recorded playtest findings |
| Import pipeline | No unresolved required references/unsupported logic; stable reimport; override preservation; packaged asset closure |
| Campaign pilot | Two or more missions exercise a branch, persistent variables and profile save/reload; red-alert carryover if selected |
| Production | Supported feature coverage and mission acceptance sheets pass; throughput and manual conversion effort measured; no unexplained mission failures |
| Release | Clean-machine packaged run, full selected campaign traversal, save recovery/migration, settings/input, licenses, crash reporting, and target hardware performance |

Measure gameplay intent rather than require identical simulation trajectories. Use strict tests for supported parser semantics, IDs, units, event transitions, duplicate-hit rejection, and save migrations. Use tolerances for movement/aiming/timing, scenario outcomes for AI, and curated visual captures for presentation. Record intentional differences and accepted ranges before interpreting a test result as a regression. Seeded randomness improves reproducibility but does not guarantee cross-platform or Chaos determinism.

Define minimum and recommended hardware, output resolution, quality tier, frame target, mission entity counts, memory/VRAM ceiling, load-time limit, and network budget if relevant. A provisional planning target is 60 fps (16.7 ms frame time) on the eventual minimum machine; it is not a benchmark result. Game-thread and GPU time must each fit the frame envelope, with headroom for bursts; they should not simply be added together as a frame total. Report p95/p99 frame times and hitch frequency as well as averages, with cold and warm loading separated.

Benchmark three named workloads: the slice, the largest selected battle, and a defined stress case beyond production density. Track active ships/subsystems/turrets/projectiles, AI time, collision query count/cost, mission evaluation, Actor/component count, effects/overdraw, draw calls, memory, and streaming stalls. Use Unreal Insights and GPU profiling to choose optimizations. Start with ordinary actors/components and deliberate tick rates; introduce pooling, batching, instancing, or data-oriented simulation when a measured bottleneck justifies the complexity.

CI should run schema/parser tests and source builds frequently, editor import/validation and a cook/package smoke test on appropriate runners, and representative gameplay/performance checks on scheduled hardware. Pin engine/toolchain and converter versions, preserve failure logs/import reports, and report missing licensed fixtures rather than silently skipping critical coverage. Shipping-package validation must cover maps and dynamic/soft-referenced content that editor tests can accidentally hide.

### Optional multiplayer workstream

If multiplayer is chosen, specify cooperative versus competitive modes, player count, listen/dedicated servers, joining in progress, reconnect, hosting/session services, progression ownership, and supported latency/loss before implementation. Unreal uses an authoritative server model; see Epic's [networking overview](https://dev.epicgames.com/documentation/unreal-engine/networking-overview-for-unreal-engine?lang=en-US). Reusing its replication does not automatically provide prediction/reconciliation for a custom six-degree-of-freedom spacecraft.

Prototype two clients and an authority with movement under latency, packet loss, collisions, missile launch/lock, subsystem damage, arrival waves, and mission success. Define input commands, snapshot frequency, prediction/reconciliation, interpolation, relevancy, dormancy, RPC validation, reliable-event limits, and late-join mission reconstruction. Replicate compact authoritative combat/mission state and derive cosmetic effects locally. Decide whether physical interactions require server correction, avoidance of client prediction, or a dedicated prediction implementation. Set bandwidth and correction tolerances from this experiment.

Network acceptance must include rapid projectile density, simultaneous deaths, disconnect/reconnect, conflicting orders, malicious/invalid commands, and campaign completion ownership. FSO clients and protocol compatibility remain outside the proposed scope. If multiplayer is deferred, retain clear authority boundaries in gameplay APIs but avoid building an unrequested networking framework.

### Deferred distribution review and ongoing prototype maintenance

The distribution-related items in this subsection are future reference only. Do not schedule them, request approvals for them, or use them to block the current personal proof of concept. Maintain only the source/version records needed for reproducibility now; reopen distribution review if the project scope changes.

`Copying.md` says the original Volition restriction continues to apply to all fs2_open code; the post-November-2020 Unlicense language must not be treated as relicensing the whole combined codebase. Record source provenance at the extraction boundary, contribution history where needed, third-party notices, and content permissions separately. A rewrite based on gameplay intent is not by itself clearance for campaign text, characters, trademarks, or retail assets.

Review the applicable [Unreal EULA](https://www.unrealengine.com/eula/unreal), including code/content license compatibility and permitted distribution of engine/editor tooling. Epic's non-compatible-license terms and FSO's noncommercial restriction require separate analysis; neither “free project” nor “Unlicense contributions” alone settles the distribution plan. Counsel/rights holders should resolve project-specific conclusions. Keep this as a defined release dependency rather than assuming Unreal integration changes existing rights.

Decide whether authors use an installed Unreal Editor plus the project/plugin, or a separately distributed tool. Do not assume an Unreal-based FRED replacement can ship as an ordinary unrestricted standalone editor. Define how imported mod content is cooked, versioned, validated, and delivered under the chosen engine and content terms. If runtime mod loading is later approved, add mount/package compatibility, dependency resolution, trust/security, update conflicts, and dedicated-server content matching as a separate design.

Maintain an engine-update policy: exact patch/fork commit, permitted plugins, regression requirements, rollback procedure, and criteria for leaving 5.8. A roadmap statement does not guarantee a support period. Store release manifests, symbols and crash diagnostics, save-schema versions, known importer limits, and reproducible package instructions. Plan one maintenance owner for converter/schema compatibility as well as gameplay; imported content is a long-lived dependency.

### Work packages, dependencies, and estimating

Do not publish a full migration date based on folder size or hypothetical parser reuse. Track responsibilities even when the project owner holds all roles: technical direction, gameplay/AI, importer/tools, art, mission design, and validation/build. Formal staffing and rights/release review are deferred. Parallelize only once interfaces and fixture ownership are explicit.

| Work package | Depends on | Reviewable output |
| --- | --- | --- |
| D0: scope and inventory | Working FSO reference build | Experiment brief, available content/operator graph, decision register and reference manifest |
| D1: UE project setup (first implementation task) | Installed engine/toolchain and project location; no completed importer or dependency inventory required | Buildable C++ project, editor/PIE lighting test map, runnable local package and reproducible setup instructions |
| D1a: first ship rendering | D1; Myrmidon model/texture source resolution only | Existing Myrmidon mesh/textures/materials rendering in a saved UE-lit level, stable reimport and local cooked run |
| D3: expanded mission content and lighting | D1a; D0 mission dependency inventory | Remaining mission meshes/textures/materials, definitions/metadata and starting scene, repeatable reimport, UE lighting and local cook |
| D2: handling/collision experiment | D3 first real-content scene; reference metrics | Compared movement prototypes against imported content and accepted handling/collision policy |
| D4: mission evaluator and combat slice | D2; D3; required event inventory | One imported encounter with debugger, win/fail/retry, and recorded acceptance |
| D5: campaign/tooling pilot | D4 accepted; save and authoring decisions | Small mission chain, branch/save/reload, author iteration and packaged closure |
| D6: production conversion | D5; approved roster/campaign | Batch content plus per-mission acceptance and throughput reports |
| D7: release hardening | D6; platform/distribution approval | Release candidate, performance and compatibility evidence, notices and maintenance plan |

D3 precedes gameplay integration: establish its first real-content lighting scene before D2, then continue remaining mission asset conversion alongside gameplay development. The package IDs retain their earlier names for traceability; table order gives the execution order. Mission semantics discovery starts in D0 and continues throughout. Build/debug/cook capability runs through every package. If multiplayer is selected, add its early feasibility package alongside D2 and a production package before release. The current dependency chain is mission selection/inventory → minimum UE/import skeleton → existing-content lighting scene → handling/combat plus remaining content and event support → end-to-end mission proof. Campaign production and release remain optional future work.

The current proof-of-concept commitment ends at D4 and the slice acceptance review. D5 is optional if campaign continuity is a question the owner wants to test; D6–D7 and production/release gates are deferred. Local cooking and packaging remain in scope because they verify runtime asset loading and editor independence, not because this prototype will be published.

Estimate each package with optimistic/likely/pessimistic effort, staffing assumptions, reusable evidence, and unresolved risks. During the slice, measure conversion time per asset family, manual repair time, authoring/debug time per mission mechanic, and QA/playthrough time. Extrapolate using the selected content counts and complexity classes, adding explicit integration, iteration, and contingency rather than a generic “porting” multiplier. Re-estimate after the slice and again after the campaign pilot. No staffing or calendar commitment is implied by this document.

The next implementation step is to set up and verify the UE C++ project: engine/toolchain, project files, lighting test map, editor/PIE and local packaging. SM1-01 is already selected and fingerprinted. The next milestone is the existing Myrmidon rendering in a UE-lit level; complete only its required import path first. Then expand the mission dependency inventory/importer and starting scene, implement movement/combat, and complete required event/presentation support. End the proof with a full mission playthrough and review of gameplay, UE lighting, conversion effort, and local packaged behavior. If a gate fails, revise the specific design or scope and repeat the affected proof. Decide whether to pursue further experiments only after reviewing those results.

## Recommendation (delivery decision)

Proceed with a personal, noncommercial proof of concept of Surrender, Belisarius! playable end to end using existing content and UE lighting. Deliver the UE project setup first, then the existing textured Myrmidon rendering in a UE-lit level, then expand to the full mission content and runtime behavior, including briefing, success/failure, debrief and retry. These proofs answer whether the gameplay feels right, required legacy semantics survive conversion, and UE lighting improves presentation with the existing assets. Legal perimeter and release planning are deferred.

If the slice succeeds, estimate the remaining work from the experience brief, selected content, Unreal feature plan, and conversion results. If it falls short, use playtest findings to revise the design or decide whether another engine better serves the remaster goal.
