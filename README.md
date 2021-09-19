# SteamPawn

A SourceMod plugin that provides access to certain Steam functionality.

Requires [DHooks][].

⚠ This plugin's update check hook is known to have compatibility problems with SteamTools.  If
you reload / update the plugin with SteamTools running, the server may crash.

[DHooks]: https://github.com/peace-maker/DHooks2/

## Building

This project is configured for building via [Ninja][]; see `BUILD.md` for detailed
instructions on how to build it.

If you'd like to use the build system for your own projects,
[the template is available here](https://github.com/nosoop/NinjaBuild-SMPlugin).

[Ninja]: https://ninja-build.org/
