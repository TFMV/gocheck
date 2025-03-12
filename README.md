# GoCheck

GoCheck is a comprehensive testing and quality assurance tool for Go projects. It combines linting, static analysis, testing, benchmarking, profiling, and more into a single command.

## Features

- **Linting**: Uses golangci-lint to check code quality
- **Static Analysis**: Runs go vet and staticcheck
- **Vulnerability Scanning**: Checks for security vulnerabilities with govulncheck
- **Testing**: Runs tests with race detection and generates coverage reports
- **Profiling**: Creates CPU, memory, block, and mutex profiles
- **Benchmarking**: Runs benchmarks with memory allocation statistics
- **Additional Checks**: Finds large files, TODOs, and FIXMEs

## Installation

### Option 1: Using the installation script

```bash
# Clone the repository or download the scripts
git clone https://github.com/TFMV/gocheck.git

# Run the installation script
./gocheck/install_gocheck.sh

# This will:
# 1. Copy gocheck.sh to ~/bin/gocheck
# 2. Add shell aliases to your .bashrc or .zshrc
# 3. Create VS Code tasks if applicable
```

### Option 2: Manual installation

```bash
# Copy the script to a directory in your PATH
cp gocheck.sh ~/bin/gocheck
chmod +x ~/bin/gocheck

# Add aliases to your shell profile (.bashrc, .zshrc, etc.)
echo 'alias gck="gocheck"' >> ~/.zshrc
echo 'alias gckf="gocheck --focus=$(go list)"' >> ~/.zshrc
echo 'alias gckt="gocheck --no-lint --no-static --no-bench --no-vuln"' >> ~/.zshrc
echo 'alias gckb="gocheck --no-lint --no-static --no-test --no-vuln"' >> ~/.zshrc
```

## Usage

### Basic Usage

```bash
# Run all checks on the current project
gocheck

# Run checks on a specific package
gocheck --focus="github.com/yourusername/yourproject/pkg/subpackage"

# Run only tests
gocheck --no-lint --no-static --no-bench --no-vuln

# Run only benchmarks
gocheck --no-lint --no-static --no-test --no-vuln
```

### Command-line Options

```bash
--no-lint         Skip linting step
--no-static       Skip static analysis (go vet / staticcheck)
--no-test         Skip unit tests
--no-bench        Skip benchmarks
--no-vuln         Skip vulnerability scanning
--focus="pkg"     Focus on specific package(s)
--bench-only="X"  Run only benchmarks matching X
--test-only="X"   Run only tests matching X
--profile-view    View profiles after generation
--open-coverage   Open coverage report in browser
--ci-mode         CI-friendly output (no colors, more verbose)
--timeout="2m"    Set timeout for tests (default: 2m)
```

### Shell Aliases

The installation script sets up the following aliases:

- `gck`: Short alias for `gocheck`
- `gckf`: Run checks on the current package only
- `gckt`: Run tests only
- `gckb`: Run benchmarks only

### VS Code Integration

The installation script creates VS Code tasks that you can run from the Command Palette (Ctrl+Shift+P):

1. **Go Check**: Run all checks
2. **Go Check (Tests Only)**: Run only tests
3. **Go Check (Benchmarks Only)**: Run only benchmarks

## Output and Artifacts

GoCheck creates a directory called `gocheck_artifacts` in the current directory with the following files:

- `coverage.html`: HTML coverage report
- `cpu.prof`: CPU profile
- `mem.prof`: Memory profile
- `block.prof`: Block profile (for concurrency analysis)
- `mutex.prof`: Mutex profile (for concurrency analysis)
- `lint.log`: Linting results
- `vet.log`: go vet results
- `staticcheck.log`: staticcheck results
- `vulncheck.log`: Vulnerability scanning results
- `tests.log`: Test output
- `benchmarks.log`: Benchmark results
- `large_files.log`: List of large files
- `todos.log`: List of TODOs and FIXMEs

## Requirements

- Go 1.16 or later
- golangci-lint (optional, for linting)
- staticcheck (optional, for static analysis)
- govulncheck (optional, for vulnerability scanning)

## License

[MIT License](LICENSE)
