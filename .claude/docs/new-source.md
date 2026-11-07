# Adding a source

1. `mkdir <name>/` and lay out files relative to `~`.
1. Register it: `sources:` in `mate.yaml`, or a profile's `sources:` if it is
   machine-specific.
1. Add `<name>/.mate.yaml` for its packages.
1. `mate status` — a half-built source in `sources:` breaks apply on every machine.

