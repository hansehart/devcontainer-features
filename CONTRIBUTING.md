# Contributing

## Changes

- **Branches** ideally start from an issue, carry one change each, and land on main through a pull request as one squashed commit.
- **Commits** start with the kind of change and a scope from `.commitlintrc.json`, followed by a short summary.
- **Descriptions** of pull requests and issues stay slim and minimal, about 2–3 sentences on average.
- **Updates** of dependencies arrive from the Renovate bot, one pull request per update.

## Code

- **Comments** state a step's intent, in abstract terms, so they stay accurate as the concrete details change. Every branch and loop carries one, on the line above it.
- **Tests** come first, so a change starts with a test that fails without it, and the implementation then makes it pass.

## Releases

- **Versions** are left to the release-please bot, whose pull request raises the first number for breaking changes, the second for new features, and the third for fixes.
- **Releases** go out when that pull request merges.
- **Features** reach ghcr.io with every release, each tagged with its own version.
- **New** features register in `release-please-config.json` and add their name to the scopes in `.commitlintrc.json`.

## Tests

- **Layout** gives each feature `test/<feature>/`, with `test.sh` for the default install and `scenarios.json` for the rest, each scenario checked by the script of its name.
- **Options** are each tested at least once with a non-default value.
- **Versions** are tested by one `pinned_version` scenario with the newest releases, the companion programs pinned beside the main one.
- **State** is tested by a `state_dir` scenario that sets `stateDir` to `/home/ubuntu/.local/state/<feature-id>`, a nested path whose missing folders the guard creates for the dev user, with `remoteUser: ubuntu`.

## Interface

- **Features** all run through the shared library in `lib/`, which `lib/sync.sh` copies into each feature, since a feature can only ship its own files. CI checks that the copies match their source, and a library change reaches every feature that carries the changed file.
- **Installs** run `install.sh`, which names the feature, reads its options with `option`, adds its apt packages to `PACKAGES`, defines its own steps, then calls `feature_main`. The sequence claims the state dir, installs the packages, resolves, downloads and verifies the release, installs the program, writes the profile, the settings and the hooks, and confirms the program runs.
- **Steps** `resolve_version` and `install_program` are required and set the release and put the program in place. The optional `profile`, `settings`, `post_install` and `confirm` add profile lines, recorded settings, feature-specific work and a custom version check.
- **Values** reach a command as plain data: every feature declares exactly one of `checksums`, `checksum`, `unverified` or `delegated`, the last two with the reason the build log shows, and `require_version` and the state-dir guard check each option where `install.sh` reads it.
- **Hooks** start in `init.sh`, which sources `hook.sh`, defines what it prepares in `init_state`, then calls `init_main <feature>`. The shared part reads the recorded state dir and the profile, creates the state dir, warns when it sits on the container filesystem, and

## Layout

- **Files** go where the Filesystem Hierarchy Standard (FHS) puts them, so every feature lays out the same way.
- **Programs** made of a single binary go in `/usr/local/bin`, and a program made of many files goes in its own `/opt/<program>` tree, with its commands linked into `/usr/local/bin` and its config in `/etc/opt/<program>`. Apt packages keep the distribution's paths, with their signing keys in `/etc/apt/keyrings`.
- **Feature** files go in `/usr/local/libexec/<feature>` for the hook scripts and their shared code, `/usr/local/etc/<feature>` for the settings recorded at build time, and `/usr/local/share/<feature>` for the data shipped for others to reference.
- **Environment** variables with a fixed value go in `containerEnv`, and those whose value depends on an option go in `/etc/profile.d/<feature>.sh`.
- **State** a program changes while running goes in `/var/opt/<program>` or `/var/lib/<program>`, files that live only while it runs go in `/run`, and a declared volume carries the feature's name. Everything of the remote user stays in their home, including `~/.local/bin` and the feature's state dir.

## Options

- **Options** choose what gets installed and where its data lives, each of one kind below, listed with `version` first, then `stateDir` if the feature has one, then the rest alphabetically.
- **Defaults** come from each tool itself and the o3s metadata hardens them, and the tool reads its config from the files the o3s metadata names.
- **Version** picks the feature's main program through `version`, and a companion program's release through `<program>Version`. Each takes `latest` or a version, resolved to an exact release before installing and logged, and the description names the forms with placeholders, such as `major.minor.patch`.
- **State** lives in `stateDir`, which is opt-in, must be inside the remote user's home, and is meant to sit on a volume. The feature checks the path at build time, and its create hook creates the dir and warns when it sits on the container filesystem.
- **Feature-specific** options cover whatever is unique to the tool, and a list is a comma-separated string with a plural name.

## Metadata

- **Metadata** for o3s sits in `customizations.o3s`, the section o3s reads, as three lists whose entries each carry a `name` and a `description` of what the entry is for.
- **Hosts** in `hosts` are the ones the tool reaches at run time, with the fields of the o3s allowlist.
- **Variables** in `env` set the tool's hardened defaults and state paths, each with its `value`.
- **Files** in `files` are the config files o3s copies in, each with the `target` it lands at.
- **Values** may use `${stateDir}`, which o3s fills in with the state dir it chose, and a feature whose tool needs nothing of o3s carries an empty section.
