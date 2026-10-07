---
name: fs2open-build
description: Configure and build this FreeSpace Open project on Windows in a requested CMake configuration, diagnose build failures, and install or run the result when requested.
---

# Build FreeSpace Open

Use the project root containing `CMakeLists.txt`. Read `BuildingOnWindowsWithVSCode.md` for local setup and content instructions when needed. Treat paths and tool versions in that guide as defaults to verify, not requirements for every build.

## Delegate execution

When subagents with model selection are available, delegate the build workflow to one `gpt-6-luna` subagent. Use a focused task with `fork_turns: "none"`, passing the project root, this skill's absolute path, the requested configuration/target, content path, and any authorized install or launch steps. Have Luna read this skill and perform the workflow below. A Luna worker already executing this skill should perform the work directly rather than delegate again.

The parent should avoid simultaneous build-directory mutations and review the worker's result. Luna should diagnose ordinary failures from actual output and report concrete blockers. Return failures requiring substantial source changes, uncertain toolchain changes, or unresolved diagnosis to the parent for further work. Delegation does not expand authorization or bypass execution approvals. If Luna or delegation is unavailable, perform the workflow directly and disclose that fallback.

## Determine the build

- This workspace's prepared game-content directory is `C:\dev\fs2-content`. Use `C:/dev/fs2-content` for `CMAKE_INSTALL_PREFIX` and `FSO_FREESPACE_PATH` by default; honor explicit overrides and verify existing cache paths before installation.
- Use the user's requested configuration and build target. Discover available configurations and targets from the project and existing build configuration. If no configuration is specified, use `Release` for playing and `Debug` for engine debugging; otherwise use the existing configuration when clear.
- Locate CMake and the installed compiler toolchain. If CMake is absent from PATH, check the usual installation location before requesting installation.
- Inspect the selected build directory's `CMakeCache.txt` for generator, architecture, options, and content/install paths. Preserve existing options unless the user requests a change or a diagnosed problem justifies proposing one.
- Use an out-of-source build directory. Reuse a compatible directory; choose a new one when changing generator or architecture. Verify that the installed CMake supports the selected generator.
- After an interrupted operation, check whether a build is still running and inspect its outputs before resuming. Do not configure or build concurrently in the same directory.

## Configure and compile

Configure with `cmake -S <source> -B <build>` and the selected generator, architecture, and options. Initialize required Git submodules if missing. Avoid installing optional tools or changing project features speculatively.

Build using:

```powershell
& $cmakeExecutable --build $buildDirectory --config $configuration --target $target --parallel
if ($LASTEXITCODE -ne 0) { throw 'Build failed; inspect the build output' }
```

`Freespace2` is the game's CMake target; use other targets or the default build when requested. Omit `--target` for a default build. Resolve the PowerShell variables before execution. Check `$LASTEXITCODE` immediately after every native configure, build, or install command; stop dependent steps on failure.

Capture lengthy output in the ignored build directory. Diagnose failures from the first substantive compiler, linker, or configuration error. Determine whether the cause is source code, a missing dependency, configuration, or execution permissions. Preserve requested functionality: explain any proposed feature change before applying it. Fix only within the authorized scope. Use the environment's escalation mechanism when sandbox restrictions prevent a necessary operation.

## Install or run when requested

Build success is required before installation. Confirm the requested configuration's game executable exists; discover its generated filename rather than hard-coding a version or instruction-set suffix.

Install with `cmake --install <build> --config <configuration>`. This copies existing outputs and does not compile missing targets. Verify the install destination before writing, use required filesystem approval, and confirm the installed executable and runtime files.

For game launch, use the prepared content directory and the requested mod arguments. Obtain GUI execution approval if required. Set the debugger's working directory explicitly when debugging. Do not treat a successful build or installation as proof that the game runs.

Report the configuration, target, output path, and verification actually performed. On failure, report the concrete error and log location, and identify what is needed to proceed. Do not repeat builds or broaden validation without a reason.
