FreeSpace2 *S*ource *C*ode *P*roject
==
[![Coverity](https://img.shields.io/coverity/scan/870.svg)](https://scan.coverity.com/projects/870)

Building
--
Before you do anything, make sure you have updated your git submodules, either by running `git submodule update --init --recursive` or by cloning the repository with the `--recursive` flag.<br/>

The main instructions for building can be found at our github wiki, on the [Building](https://github.com/scp-fs2open/fs2open.github.com/wiki/Building) page.

Personal Unreal proof of concept
--
The local experiment targets **Surrender, Belisarius!** with existing content and UE lighting. The implementation order is UE project setup, an existing Myrmidon rendering in a UE level, then full mission content and gameplay. See the [roadmap](UnrealRoadmap.md), [detailed migration plan](UnrealMigration.md), and [content tools](tools/migration/README.md). This is a private, noncommercial proof of concept; production and release planning are deferred.
