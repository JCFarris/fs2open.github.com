# Unreal migration content tools

The current target is the private, noncommercial proof of concept of **Surrender, Belisarius! (`SM1-01.fs2`)** with existing content and UE lighting. See [the roadmap](../../UnrealRoadmap.md) for milestone status and [the migration plan](../../UnrealMigration.md) for format-to-asset conversion details.

The agreed order is UE project setup, then the existing textured Myrmidon rendering in a UE level, then expanded mission content and gameplay. This scanner supports source discovery; completing a universal content pipeline is not a prerequisite for the first ship rendering milestone.

## Inspect the local content

From the repository root in PowerShell:

```powershell
.\tools\migration\Inspect-Content.ps1 -OutputPath .\tools\migration\content-inventory.local.json
```

Defaults: content root `C:\dev\fs2-content`, mission `SM1-01.fs2`. Override the root or explicitly inspect other missions when needed:

```powershell
.\tools\migration\Inspect-Content.ps1 -ContentRoot 'C:\path\to\FreeSpace2' -MissionNames 'SM1-01.fs2' -OutputPath .\tools\migration\content-inventory.local.json
```

The scanner reads VP version 2 archive indexes and loose files under `data`, checks archive entry ranges/directory structure, records source paths/offsets/sizes, reports extension counts, reads retail campaign order, and fingerprints mission bytes with SHA-256. It also reports lexical ship-class, object/wing/event name, resource and expression candidates. The output file includes the full file inventory; console output is a shorter summary. Generated `*.local.json` reports are ignored by Git. It does not extract or modify the game content.

## Limits and next pipeline work

This is discovery tooling, not an FSO parser or importer. It does not reproduce mod/search precedence, merge modular tables, resolve POF texture dependencies, execute expressions, create UE packages or prove a complete dependency closure. Mission candidates must be unique; campaign duplicates and all other file duplicates remain in the report for explicit resolution. Unique-name summaries omit duplicate records, and lexical scans may include strings/comments or miss indirect references. Section annotations are not reliable counts of parsed runtime records.

For M2, add source resolution for the Myrmidon, POF geometry/material extraction, PCX decoding and a UE editor import path that serializes native assets. Validate rendering, units/orientation, material slots, lighting response and stable reimport. For M3, expand semantic metadata, table/mission parsing and indirect references to the remaining selected-mission content. Record support per format and per mission operator rather than marking the entire pipeline complete after a successful file scan.
