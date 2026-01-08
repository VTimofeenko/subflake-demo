This is a repository that illustrates how parent/child flakes can work.

Patterns:

- Parent flake used for distribution, subflake for development: [parent-flake-distribute](./parent-flake-distribute/)
- Parent flake used for distribution, subflake for development, but subflake
  uses inputs from parent: [parent-flake-distribute-reuse-inputs](./parent-flake-distribute-reuse-inputs/)
