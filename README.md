# nix-scripts

Utility scripts collection for working with nixos tools.

## Usage

### CLI

Everything can be called by using the `nix-script` executable:

```bash
$ nix-script show-commit
$ nix-script ls-profiles
# and so on
```

The `nix-script` executable can be called with `-l` to list the available
commands or `-h` to get the help text. Calling `nix-script -v <something>`
will turn on verbosity and each script will explain what it does.

### Install

There is `default.nix` expression which allows you to build this package.
Just choose `rev` and provide appropriate `sha256`:

```nix
nixos-scripts = pkgs.callPackage (pkgs.fetchFromGitHub {
  owner = "matthiasbeyer";
  repo = "nixos-scripts";
  rev = "...";
  sha256 = "...";
}) {}
```

## Examples

Show the numbers of the available system-profile generations. Use
without -n to get the full name (in form "system-<n>-link"):

```bash
nix-script ls-profiles -s -n
```

Show a diff which stuff got installed and which stuff got removed:

```bash
nix-script diff-generations -s -n 114..115
```

Execute "nixos-rebuild switch" and tags the current checked-out commit
in "/home/myself/nixos-configuration/" on successful build (including
generation number). Format for the tag name is

```plain
  nixos-[<hostname>-]<generation>-<command>
```

Where <generation> is the generation which was just build
and <command> is the command for nixos-rebuild, so either switch or test
or... you get the point

```bash
nix-script switch -c switch -w /home/myself/nixos-configuration/
```

Add a `-n` to include the hostname into the tag name (useful if you share
your configuration over several hosts, as I do).

You can also provide flags for 'nixos-rebuild' like so:
(everything after the two dashes is appended to the nixos-rebuild command)

```bash
nix-script switch -c switch -w /home/myself/conf -- -I nixpkgs=/home/myself/pkgs
```

Dive into the code or use the `-h` flags for getting more help.

## Branches

`master` is the branch for development. Features and fixes are added via PRs
to the `master` branch, small fixes are pushed onto master directly. Using
latest `master` should be safe most of the time, though bugs may be there.
Using a release version should always be safe, but not as long as a `0` is the
major number. So, `0.1` should be safe, but it won't get any bug fixes if
there bugs. `1.0` should be safe and bug fixes will be pushed to `1.x`
releases if there are any.

## License

This code is released under the terms of GNU GPL v2.
(c) 2015 Matthias Beyer

Feel free to buy me a pizza or Club-Mate if you meet me at a conference.

