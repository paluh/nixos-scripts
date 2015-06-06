# nix-scripts

Utility scripts collection for working with nixos tools.

## Usage

Everything can be called by using the `nix-script` executeable:

```bash
$ nix-script show-commit
$ nix-script ls-profiles
# and so on
```

The `nix-script` executeable can be called with `-l` to list the available
commands or `-h` to get the help text. Calling `nix-script -v <something>`
will turn on verbosity and each script will explain what it does.

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
in "/home/myself/nixos-configuration/" on successfull build (including
generation number). Default format for the tag name is

```plain
  nixos-<generation>-<command>
```

Where <generation> is the generation which was just build
and <command> is the command for nixos-rebuild, so either switch or test
or... you get the point

You can, of course, override the tag name (no way to insert the generation
number by now) or the git command to use ('tag -a' be default).

```bash
nix-script switch -c switch -w /home/myself/nixos-configuration/
```

You can also provide flags for 'nixos-rebuild' like so:
(everything after the two dashes is appended to the nixos-rebuild command)

```bash
nix-script switch -c switch -w /home/myself/conf -- -I nixpkgs=/home/myself/pkgs
```

## License

This code is released under the terms of GNU GPL v2.
(c) 2015 Matthias Beyer

Feel free to buy me a pizza or Club-Mate if you meet me at a conference.

