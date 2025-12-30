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
