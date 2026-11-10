# Contributing

## ASE standards

### Changes

- **Branches** ideally start from an issue, carry one change each, and land on main through a pull request as one squashed commit.
- **Commits** start with the kind of change and a scope from `.commitlintrc.json`, followed by a short summary.
- **Descriptions** of pull requests and issues stay slim and minimal, about 2–3 sentences on average.
- **Updates** of dependencies arrive from the Renovate bot, one pull request per update.

### Code

- **Comments** state a step's intent, in abstract terms, so they stay accurate as the concrete details change. Every branch and loop carries one, on the line above it.
- **Tests** come first, so a change starts with a test that fails without it, and the implementation then makes it pass.

### Releases

- **Versions** are left to the release-please bot, whose pull request raises the first number for breaking changes, the second for new features, and the third for fixes.
- **Releases** go out when that pull request merges, and publish the artifacts the repository standards name.

## Repository standards

### Tests

- **Layout** gives each feature `test/<feature>/`, with `test.sh` for the default install and `scenarios.json` for the rest, each scenario checked by the script of its name.
- **Options** are each tested at least once with a non-default value.
- **Versions** are tested by one `pinned_version` scenario with the newest releases, the companion programs pinned beside the main one.
- **State** is tested by a `state_dir` scenario that sets `stateDir` to `/home/ubuntu/.local/state/<feature-id>`, a nested path whose missing folders the guard creates for the dev user, with `remoteUser: ubuntu`.

### Artifacts

- **Features** reach the registry with every release, each under its own version. A new feature joins by adding itself to `release-please-config.json` and its name to the scopes in `.commitlintrc.json`.

### Interface

- **Features** all run through the shared library in `lib/`, so they install and prepare their state the same way.
- **Copies** of the library reach each feature through `lib/sync.sh`, since a feature can only ship its own files, and CI checks that they match their source.
- **Installs** run `install.sh`, which names the feature, reads its options with `option`, adds its apt packages to `PACKAGES`, defines its own steps, then calls `feature_main`. The sequence claims the state dir, installs the packages, resolves and logs the release, downloads and verifies it, installs the program, then writes the profile, the settings and the hooks, and confirms the program runs.
- **Required** steps are `resolve_version`, which sets the exact release and how its download is verified, and `install_program`, which puts the program in place.
- **Optional** steps are `profile`, which prints the profile lines, `settings`, which records what the hooks apply, `post_install`, which covers what is unique to the feature, and `confirm`, which replaces the default version check.
- **Verification** takes exactly one of `checksums`, `checksum`, `unverified` or `delegated` per feature, the last two with the reason, which the build log shows.
- **Option** checks run through `require_version`, which matches a version, or any value under its option's name, against the feature's format right where `install.sh` reads it. The state-dir guard accepts plain paths, so every value reaches a command as plain data.
- **Hooks** start in `init.sh`, which sources `hook.sh`, defines what it prepares in `init_state`, then calls `init_main <feature>`. The shared part reads the recorded state dir and the profile, creates the state dir, and warns when it sits on the container filesystem. `apply_config` writes a recorded user config to where the tool reads it.
- **Library** changes reach every feature that carries the changed file, which the release-please bot's pull request then releases.

### Layout

- **Files** go where the Filesystem Hierarchy Standard (FHS) puts them, so every feature lays out the same way.
- **Environment** variables with a fixed value go in `containerEnv`, and those whose value depends on an option go in `/etc/profile.d/<feature>.sh`.
- **Hook** scripts the feature runs at build, create or start, and the code they share, go in `/usr/local/libexec/<feature>`.
- **Packages** from apt keep the distribution's paths, and their signing keys go in `/etc/apt/keyrings`.
- **Programs** made of a single binary go in `/usr/local/bin`. A program made of many files goes in its own `/opt/<program>` tree, with its commands linked into `/usr/local/bin` and its own config in `/etc/opt/<program>`.
- **Runtime** state, the data a program changes while running, goes in `/var/opt/<program>` for a program in `/opt` and in `/var/lib/<program>` for any other program, and files that live only while it runs go in `/run`.
- **Settings** the feature records at build time for its hooks to apply go in `/usr/local/etc/<feature>`.
- **Shipped** data, the fixed files the feature ships for others to reference, goes in `/usr/local/share/<feature>`.
- **User** data stays in the remote user's home, including per-user installs in `~/.local/bin` and the feature's state dir, which holds data only.
- **Volumes** a feature declares are named after the feature, and hold the runtime state of a program.

### Options

- **Options** choose what gets installed and where its data lives, and each belongs to one of the kinds below.
- **Defaults** come from each tool itself and the o3s metadata hardens them, and the tool reads its config from the files the o3s metadata names.
- **Order** lists `version` first, then `stateDir` if the feature has one, then the rest alphabetically.
- **Version** picks the feature's main program through `version`, and a companion program's release through `<program>Version`. Each takes `latest` or a version, resolved to an exact release before installing, and that release is logged. The description names the forms with placeholders, such as `major.minor.patch`.
- **State** lives in `stateDir`, which is opt-in, must be inside the remote user's home, and is meant to sit on a volume. The feature checks the path at build time, and its create hook creates the dir and warns when it sits on the container filesystem.
- **Feature-specific** options cover whatever is unique to the tool. A list is a comma-separated string with a plural name.

### Metadata

- **Metadata** for o3s sits in `customizations.o3s`, the section o3s reads, as three lists whose entries each carry a `name` and a `description` of what the entry is for.
- **Hosts** in `hosts` are the ones the tool reaches at run time, with the fields of the o3s allowlist (`ports`, `secret`, `inject`).
- **Variables** in `env` set the tool's hardened defaults and state paths, each with its `value`.
- **Files** in `files` are the config files o3s copies in, each with the `target` it lands at.
- **Values** may use `${stateDir}`, which o3s fills in with the state dir it chose.
- **Empty** sections mark a feature whose tool needs nothing of o3s.
