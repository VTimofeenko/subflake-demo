If one wants to reuse parent's `nixpkgs` instance in the subflake, there are (at
least?) two approaches:

1. Subflake has a `nixpkgs` input that follows `parent/nixpkgs`:

    ```nix
    inputs = {
      parent.url = ./..;
      nixpkgs.follows = "parent/nixpkgs"; # <- this
      devshell.url = "github:numtide/devshell";
      devshell.inputs.nixpkgs.follows = "nixpkgs";

      # As an example, the development flake runs tests on home manager modules
      # But the parent flake does not need to have home-manager as an input
      home-manager.url = "github:nix-community/home-manager";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";
    };


    ```

2. Subflake does *not* have a `nixpkgs` input. Other inputs follow the parent's
   input. The code looks like this:

    ```nix
    # subflake/flake.nix
    inputs = {
      parent.url = ./..;
      devshell.url = "github:numtide/devshell";
      devshell.inputs.nixpkgs.follows = "parent/nixpkgs";

      # As an example, the development flake runs tests on home manager modules
      # But the parent flake does not need to have home-manager as an input
      home-manager.url = "github:nix-community/home-manager";
      home-manager.inputs.nixpkgs.follows = "parent/nixpkgs";
    };
    ```

    However, `flake-parts` will get confused when looking for `nixpkgs` input in
    order to construct `pkgs` inside `perSystem`. We can help it by setting
    `pkgs` directly:

    ```nix
    # subflake/flake.nix
    perSystem = { system, ... }: {  
      # `flake-parts` demands an input called `nixpkgs`. Well, _this_ subflake does not have it
      # but the parent does.

      _module.args.pkgs = parentInputs.nixpkgs.legacyPackages.${system};
    };
    ```

Compared to the other approach, the subflake here does not have an explicit
`nixpkgs` input. The inputs of the subflake reuse parent's `nixpkgs` inputs and
`flake-parts` gets `nixpkgs` argument by passing it explicitly:

```nix
_module.args.pkgs = parentInputs.nixpkgs.legacyPackages.${system};

```

Note the differences. This subflake's inputs are:

```$ as json
jq < ./subflake/flake.lock '.nodes | keys'
```

```json
[
  "devshell",
  "flake-parts",
  "home-manager",
  "nixpkgs",
  "nixpkgs-lib",
  "parent",
  "root"
]
```

Whereas in the other example:

```$ as json
jq < ../parent-flake-distribute/subflake/flake.lock '.nodes | keys'
```

```json
[
  "devshell",
  "flake-parts",
  "home-manager",
  "nixpkgs",
  "nixpkgs-lib",
  "nixpkgs_2",
  "nixpkgs_3",
  "nixpkgs_4",
  "parent",
  "root"
]
```

And, the `nixpkgs` hashes match between parent and subflake:

```$ as shell
jq -r < ./flake.lock '.nodes.nixpkgs.locked.narHash | "Parent flake:\t" + .'
jq -r < ./subflake/flake.lock '.nodes.nixpkgs.locked.narHash | "Subflake:\t\t" + .'
```

```shell
Parent flake:	sha256-coBu0ONtFzlwwVBzmjacUQwj3G+lybcZ1oeNSQkgC0M=
Subflake:		sha256-coBu0ONtFzlwwVBzmjacUQwj3G+lybcZ1oeNSQkgC0M=
```

Using this approach, we can reduce the time it takes to evaluate the subflake
and have fewer inputs to care for.

The other flake's README follows for completeness:

[> README.md](../parent-flake-distribute/README.md)

<!-- BEGIN mdsh -->
In this pattern, the parent flake is used to distribute a thing(package) and a
home manager module, and a sub flake is used to develop that thing and to
run tests.

The point of this approach is that there may be development-only dependencies
that the consumers of the parent flake don't necessarily care about. The
author of the parent flake wants to relieve the consumers from having to
override those inputs.

The bundled `.envrc` loads the subflake with the development tools. A mock CI
uses the sub flake to test the parent's home manager module.

# Flake outputs

Parent flake:

<!-- `$ nix flake show | tail -n+2` as shell -->

```shell
├───homeManagerModules: unknown
└───packages
    ├───aarch64-darwin
    │   └───default omitted (use '--all-systems' to show)
    ├───aarch64-linux
    │   └───default omitted (use '--all-systems' to show)
    ├───x86_64-darwin
    │   └───default omitted (use '--all-systems' to show)
    └───x86_64-linux
        └───default: package 'hello-2.12.2'
```

Sub flake:

<!-- `$ nix flake show ./subflake | tail -n+2` as shell -->

```shell
├───checks
│   ├───aarch64-darwin
│   │   └───homeManagerModuleTest omitted (use '--all-systems' to show)
│   ├───aarch64-linux
│   │   └───homeManagerModuleTest omitted (use '--all-systems' to show)
│   ├───x86_64-darwin
│   │   └───homeManagerModuleTest omitted (use '--all-systems' to show)
│   └───x86_64-linux
│       └───homeManagerModuleTest: derivation 'vm-test-run-homeManagerModuleTest'
├───devShells
│   ├───aarch64-darwin
│   │   └───default omitted (use '--all-systems' to show)
│   ├───aarch64-linux
│   │   └───default omitted (use '--all-systems' to show)
│   ├───x86_64-darwin
│   │   └───default omitted (use '--all-systems' to show)
│   └───x86_64-linux
│       └───default: development environment 'devshell'
└───packages
    ├───aarch64-darwin
    │   └───default omitted (use '--all-systems' to show)
    ├───aarch64-linux
    │   └───default omitted (use '--all-systems' to show)
    ├───x86_64-darwin
    │   └───default omitted (use '--all-systems' to show)
    └───x86_64-linux
        └───default: package 'hello-2.12.2'
```
<!-- END mdsh -->

