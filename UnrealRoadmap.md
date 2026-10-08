# Unreal proof-of-concept roadmap

Updated October 7, 2026. Detailed technical planning: [UnrealMigration.md](UnrealMigration.md). Content inspection: [tools/migration/README.md](tools/migration/README.md).

## Agreed target

This is a private, personal, noncommercial experiment with no release in its current form. The target is **Surrender, Belisarius! (`SM1-01.fs2`)**, the first combat mission in the retail FreeSpace 2 campaign. Use existing content and Unreal materials/lighting, and make the mission playable from briefing through its required encounter stages to success/failure, debrief and retry/exit. Tutorials, full campaign progression, broad mod compatibility, multiplayer implementation, legal review and release planning are outside the current commitment.

## Milestones in execution order

| Milestone | Work | Acceptance | Status |
| --- | --- | --- | --- |
| M0: reference and mission selection | Keep working FSO build; locate retail content; confirm campaign order and mission identity | Selected SM1-01 and reproducible source inventory/fingerprint | Selection and initial inventory complete; dependency closure still pending |
| M1: UE project setup | Verify installed engine/toolchain; create independent desktop C++ project and minimal lighting test level; document build/run | Project builds, editor opens, PIE works, local package runs | Planned; first implementation task |
| M2: existing ship rendering | Resolve/import GTF Myrmidon POF and existing textures into native UE mesh/material/texture assets; place in saved level | Correct scale/orientation, normals and materials; visible UE lighting response; stable reimport and cooked run | Planned; first content milestone |
| M3: mission content scene | Complete resolved dependency manifest; add Psamtik/remaining ships, required tables/metadata, environment and starting placements | UE-lit initial scene; hardpoints/subsystems and references validate; remaining format/operator support is explicit | Planned |
| M4: playable encounter | Movement/collision, player weapons, damage, required AI/wings/turrets, arrivals/departures and event execution | SM1-01's required combat, docking/cargo/beam and objective behavior works on actual imported content | Planned |
| M5: end-to-end mission proof | Complete briefing/loadout, messages/audio/effects, mission ending, debrief and retry/exit; verify local package | Recorded success and failure/retry runs, correct objective/debrief outcomes and UE-lit presentation | Planned; completes current goal |

M1 does not depend on finishing the importer or mission inventory. M2 requires only the Myrmidon's source dependencies; Psamtik, full mission parsing, flight controls and gameplay metadata execution cannot block this first visual milestone. Preserve metadata during conversion so M3 can interpret it later. Expand content coverage before broad gameplay development; remaining content and runtime work can proceed together after the initial imported scene exists.

Unreal lighting is required. Lumen, ray tracing and other expensive rendering features are experiments to measure, not mandatory milestones. Keep lighting tuning separate from generated imports. Temporary geometry supports project setup; M2 and later acceptance use existing ship content.

## Current evidence and next action

The FSO reference build works. Retail content is available at `C:\dev\fs2-content`. The content scanner validates VP indexes and reports inventory, campaign order and lexical SM1-01 references; it is not yet a table resolver, POF converter or complete dependency analyzer. There is no verified UE project, imported ship or playable UE mission yet.

**Next action: M1, set up and verify the UE project.** Record its exact engine version, toolchain, location and reproducible commands as implementation establishes them. Then execute M2 before expanding the mission pipeline.

Project location, installed UE version and binary storage policy are setup tasks to resolve from the environment. Controls, movement and lighting tuning can be evaluated at the relevant prototypes. A change to the chosen mission or a production/distribution commitment requires a new scope decision; broader migration ideas in the detailed plan are future reference.
