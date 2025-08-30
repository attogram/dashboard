# Testing

The Dashboard project uses a robust testing suite to ensure code quality and prevent regressions. We use the [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core) to test our shell scripts.

## Running the Tests

To run the full test suite, you need to have Node.js and npm installed. The test runner is defined as a development dependency in `package.json`.

1.  Install the development dependencies:

    ```bash
    npm install
    ```

2.  Run the tests:
    ```bash
    npm test
    ```

The `npm test` command will execute all the `.bats` files found in the `test/` directory.

## Testing Strategy

Our testing strategy is divided into two main categories:

### 1. Module Tests

Each module has its own corresponding test file in the `test/` directory (e.g., `test/hackernews.bats`). These tests are responsible for verifying the correctness of a single module.

Module tests should:

- Ensure the module produces the correct output for all 8 supported formats.
- Check that the module handles missing or invalid configuration gracefully.
- Verify that the module exits with the correct status code in both success and failure cases.

### 2. Integration Tests

The `test/dashboard.bats` file contains integration tests for the main `dashboard.sh` script. These tests are responsible for verifying that the script correctly orchestrates the execution of the modules and assembles the final report.

Integration tests should:

- Verify that the aggregated output for structured formats (`json`, `xml`, `html`) is well-formed.
- Check that command-line arguments and flags are parsed correctly.
- Ensure that the script handles errors, such as missing dependencies or invalid module names, correctly.

## Writing Tests

When contributing new code, please ensure you add corresponding tests. For a new module, you should create a new `test/your-module.bats` file. For changes to the main script, you should add new tests to `test/dashboard.bats`.
