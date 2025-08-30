# Contributing to Dashboard

We welcome contributions from the community! Whether you're fixing a bug, adding a new module, or improving the documentation, your help is appreciated.

## Getting Started

- If you are proposing a new feature or a significant change, please **open an issue first** to discuss it with the maintainers.
- Make sure you have read the project's [`README.md`](./README.md) to understand its purpose and functionality.

## Development Workflow

1.  **Fork the repository** on GitHub.
2.  **Clone your fork** to your local machine.
3.  **Create a new branch** for your changes.
    ```bash
    git checkout -b feature/your-awesome-feature
    ```
4.  **Make your changes**. See the "Technical Guidelines" below.
5.  **Add tests** for your changes in the `test/` directory.
6.  **Run the test suite** to ensure everything is working correctly.
    ```bash
    npm test
    ```
7.  **Commit your changes** with a clear and descriptive message.
8.  **Push your branch** to your fork on GitHub.
9.  **Open a Pull Request** to the `main` branch of the original repository.

## Technical Guidelines

- **Bash v3.2 Compatibility**: All shell scripts must be compatible with Bash version 3.2. This is the default version on macOS, so it's important for cross-platform compatibility.
- **POSIX Compliance**: Use standard POSIX-compliant tools and shell features where possible. Avoid Bash-specific features that are not available in other shells unless necessary.
- **Minimal Dependencies**: The core application should only depend on `curl` and `jq`. New modules should not add new system-level dependencies.
- **Style**: Follow the existing code style. Use comments to explain complex parts of the code.

## Testing

- All new features and bug fixes must be accompanied by tests.
- We use the [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core) for testing.
- Module tests are located in `test/`. Please add a new `.bats` file for your new module or add tests to an existing one.
- To run the tests, use the `npm test` command.
