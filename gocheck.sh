#!/usr/bin/env bash
# gocheck: Run linting, static checks, tests, benchmarks, profiling and more.
# Usage: gocheck [options]
# Options:
#   --no-lint         Skip linting step
#   --no-static       Skip static analysis (go vet / staticcheck)
#   --no-test         Skip unit tests
#   --no-bench        Skip benchmarks
#   --no-vuln         Skip vulnerability scanning
#   --focus="pkg"     Focus on specific package(s)
#   --bench-only="X"  Run only benchmarks matching X
#   --test-only="X"   Run only tests matching X
#   --profile-view    View profiles after generation
#   --open-coverage   Open coverage report in browser
#   --ci-mode         CI-friendly output (no colors, more verbose)
#   --help            Show this help

set -euo pipefail

# Defaults – all steps enabled
DO_LINT=true
DO_STATIC=true
DO_TEST=true
DO_BENCH=true
DO_VULN=true
FOCUS_PKG="./..."
BENCH_PATTERN="."
TEST_PATTERN=""
PROFILE_VIEW=false
OPEN_COVERAGE=false
CI_MODE=false
TIMEOUT="2m"
START_TIME=$(date +%s)

# Colors for output (disable in CI mode)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-lint)
      DO_LINT=false
      shift
      ;;
    --no-static)
      DO_STATIC=false
      shift
      ;;
    --no-test)
      DO_TEST=false
      shift
      ;;
    --no-bench)
      DO_BENCH=false
      shift
      ;;
    --no-vuln)
      DO_VULN=false
      shift
      ;;
    --focus=*)
      FOCUS_PKG="${1#*=}"
      shift
      ;;
    --bench-only=*)
      BENCH_PATTERN="${1#*=}"
      shift
      ;;
    --test-only=*)
      TEST_PATTERN="${1#*=}"
      shift
      ;;
    --profile-view)
      PROFILE_VIEW=true
      shift
      ;;
    --open-coverage)
      OPEN_COVERAGE=true
      shift
      ;;
    --ci-mode)
      CI_MODE=true
      RED=""
      GREEN=""
      YELLOW=""
      BLUE=""
      CYAN=""
      BOLD=""
      NC=""
      shift
      ;;
    --timeout=*)
      TIMEOUT="${1#*=}"
      shift
      ;;
    --help)
      echo "Usage: gocheck [options]"
      echo "Options:"
      echo "  --no-lint         Skip linting step"
      echo "  --no-static       Skip static analysis (go vet / staticcheck)"
      echo "  --no-test         Skip unit tests"
      echo "  --no-bench        Skip benchmarks"
      echo "  --no-vuln         Skip vulnerability scanning"
      echo "  --focus=\"pkg\"     Focus on specific package(s)"
      echo "  --bench-only=\"X\"  Run only benchmarks matching X"
      echo "  --test-only=\"X\"   Run only tests matching X"
      echo "  --profile-view    View profiles after generation"
      echo "  --open-coverage   Open coverage report in browser"
      echo "  --ci-mode         CI-friendly output (no colors, more verbose)"
      echo "  --timeout=\"2m\"    Set timeout for tests (default: 2m)"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}" >&2
      exit 1
      ;;
  esac
done

# Function to print section headers
print_header() {
  echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}"
}

# Function to print success/failure
print_result() {
  if [ $1 -eq 0 ]; then
    echo -e "${GREEN}✓ $2${NC}"
  else
    echo -e "${RED}✗ $2${NC}"
    return 1
  fi
}

# Function to open a file in the default browser
open_file() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$1"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v xdg-open > /dev/null; then
      xdg-open "$1"
    else
      echo -e "${YELLOW}Cannot open file: xdg-open not found${NC}"
    fi
  elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    start "$1"
  else
    echo -e "${YELLOW}Cannot open file: unsupported OS${NC}"
  fi
}

# Function to show elapsed time
show_elapsed() {
  local end_time=$(date +%s)
  local elapsed=$((end_time - START_TIME))
  local mins=$((elapsed / 60))
  local secs=$((elapsed % 60))
  echo -e "${CYAN}Time elapsed: ${mins}m ${secs}s${NC}"
}

# Trap for cleanup on exit
cleanup() {
  # Kill any background processes we started
  if [ -n "${PPROF_PID:-}" ]; then
    kill $PPROF_PID 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Check Go version
GO_VERSION=$(go version | awk '{print $3}')
echo -e "${YELLOW}Go version: ${GO_VERSION}${NC}"
echo -e "${YELLOW}Running checks on: ${FOCUS_PKG}${NC}"

# Create output directory for artifacts
ARTIFACTS_DIR="gocheck_artifacts"
mkdir -p "$ARTIFACTS_DIR"

print_header "Running Go Checks"

# Check dependencies
check_dependency() {
  if ! command -v "$1" &> /dev/null; then
    echo -e "${YELLOW}$1 not found. $2${NC}" >&2
    return 1
  fi
  return 0
}

# Track overall success/failure
OVERALL_SUCCESS=true

# 1. Linting
if $DO_LINT; then
  print_header "Running golangci-lint"
  if check_dependency golangci-lint "Please install it from https://golangci-lint.run/."; then
    echo ">> Running golangci-lint..."
    golangci-lint run "$FOCUS_PKG" | tee "$ARTIFACTS_DIR/lint.log"
    RESULT=${PIPESTATUS[0]}
    if ! print_result $RESULT "Linting"; then
      OVERALL_SUCCESS=false
    fi
  fi
fi

# 2. Static analysis
if $DO_STATIC; then
  print_header "Running static analysis"
  
  echo ">> Running go vet..."
  go vet "$FOCUS_PKG" 2>&1 | tee "$ARTIFACTS_DIR/vet.log"
  VET_RESULT=${PIPESTATUS[0]}
  if ! print_result $VET_RESULT "go vet"; then
    OVERALL_SUCCESS=false
  fi
  
  if check_dependency staticcheck "Consider installing it with: go install honnef.co/go/tools/cmd/staticcheck@latest"; then
    echo ">> Running staticcheck..."
    staticcheck "$FOCUS_PKG" 2>&1 | tee "$ARTIFACTS_DIR/staticcheck.log"
    STATICCHECK_RESULT=${PIPESTATUS[0]}
    if ! print_result $STATICCHECK_RESULT "staticcheck"; then
      OVERALL_SUCCESS=false
    fi
  fi
fi

# 3. Vulnerability scanning
if $DO_VULN; then
  print_header "Running vulnerability scanning"
  if check_dependency govulncheck "Consider installing it with: go install golang.org/x/vuln/cmd/govulncheck@latest"; then
    echo ">> Running govulncheck..."
    govulncheck "$FOCUS_PKG" 2>&1 | tee "$ARTIFACTS_DIR/vulncheck.log"
    VULN_RESULT=${PIPESTATUS[0]}
    if ! print_result $VULN_RESULT "govulncheck"; then
      OVERALL_SUCCESS=false
    fi
  fi
fi

# 4. Testing (with race detector, coverage and profiles)
if $DO_TEST; then
  print_header "Running tests"
  
  # Clean up old profiles
  rm -f "$ARTIFACTS_DIR/coverage.out" "$ARTIFACTS_DIR/cpu.prof" "$ARTIFACTS_DIR/mem.prof" "$ARTIFACTS_DIR/block.prof" "$ARTIFACTS_DIR/mutex.prof"
  
  # Check if we're testing multiple packages
  IS_MULTIPLE_PACKAGES=false
  if [[ "$FOCUS_PKG" == *"..."* ]]; then
    IS_MULTIPLE_PACKAGES=true
  fi
  
  # Build test flags
  TEST_FLAGS="-race -timeout=$TIMEOUT -coverprofile=$ARTIFACTS_DIR/coverage.out"
  
  # Only add profiling flags when testing a single package
  if ! $IS_MULTIPLE_PACKAGES; then
    TEST_FLAGS="$TEST_FLAGS -cpuprofile=$ARTIFACTS_DIR/cpu.prof -memprofile=$ARTIFACTS_DIR/mem.prof"
    TEST_FLAGS="$TEST_FLAGS -blockprofile=$ARTIFACTS_DIR/block.prof -mutexprofile=$ARTIFACTS_DIR/mutex.prof"
  else
    echo -e "${YELLOW}Note: Profiling disabled for multiple packages. Use --focus to specify a single package for profiling.${NC}"
  fi
  
  # Add test pattern if specified
  if [ -n "$TEST_PATTERN" ]; then
    TEST_FLAGS="$TEST_FLAGS -run=$TEST_PATTERN"
  fi
  
  echo ">> Running tests with race detector and profiling..."
  go test $TEST_FLAGS -v "$FOCUS_PKG" | tee "$ARTIFACTS_DIR/tests.log"
  TEST_RESULT=${PIPESTATUS[0]}
  if ! print_result $TEST_RESULT "Tests"; then
    OVERALL_SUCCESS=false
  fi
  
  # Generate HTML coverage report
  if [ -f "$ARTIFACTS_DIR/coverage.out" ]; then
    go tool cover -html="$ARTIFACTS_DIR/coverage.out" -o "$ARTIFACTS_DIR/coverage.html"
    COVERAGE=$(go tool cover -func="$ARTIFACTS_DIR/coverage.out" | grep total | awk '{print $3}')
    echo -e "${YELLOW}Code coverage: $COVERAGE${NC}"
    
    # Open coverage report if requested
    if $OPEN_COVERAGE; then
      echo ">> Opening coverage report in browser..."
      open_file "$ARTIFACTS_DIR/coverage.html"
    fi
  fi
fi

# 5. Benchmarks
if $DO_BENCH; then
  print_header "Running benchmarks"
  
  # Build benchmark flags
  BENCH_FLAGS="-bench=$BENCH_PATTERN -benchmem -benchtime=1s"
  
  echo ">> Running benchmarks..."
  go test $BENCH_FLAGS "$FOCUS_PKG" | tee "$ARTIFACTS_DIR/benchmarks.log"
  BENCH_RESULT=${PIPESTATUS[0]}
  if ! print_result $BENCH_RESULT "Benchmarks"; then
    OVERALL_SUCCESS=false
  fi
fi

# 6. View profiles if requested
if $PROFILE_VIEW && $DO_TEST; then
  if [ -f "$ARTIFACTS_DIR/cpu.prof" ]; then
    echo ">> Opening CPU profile..."
    go tool pprof -http=:8080 "$ARTIFACTS_DIR/cpu.prof" &
    PPROF_PID=$!
    echo -e "${YELLOW}Profile server running at http://localhost:8080/ (PID: $PPROF_PID)${NC}"
    echo -e "${YELLOW}Press Ctrl+C when done viewing profiles${NC}"
  fi
fi

# 7. Check for common issues
print_header "Additional checks"

# Check for large files
echo ">> Checking for large files in the repo..."
find . -type f -not -path "*/\.*" -not -path "*/vendor/*" -not -path "*/node_modules/*" -size +1M | tee "$ARTIFACTS_DIR/large_files.log"

# Check for TODOs and FIXMEs
echo ">> Checking for TODOs and FIXMEs..."
grep -r "TODO\|FIXME" --include="*.go" . | tee "$ARTIFACTS_DIR/todos.log"

print_header "Summary"
show_elapsed

if $OVERALL_SUCCESS; then
  echo -e "${GREEN}${BOLD}✓ All checks completed successfully${NC}"
else
  echo -e "${RED}${BOLD}✗ Some checks failed${NC}"
fi

echo ""
echo "Artifacts available in $ARTIFACTS_DIR:"
echo "- Coverage report: $ARTIFACTS_DIR/coverage.html"
echo "- CPU profile: $ARTIFACTS_DIR/cpu.prof (analyze with: go tool pprof $ARTIFACTS_DIR/cpu.prof)"
echo "- Memory profile: $ARTIFACTS_DIR/mem.prof (analyze with: go tool pprof $ARTIFACTS_DIR/mem.prof)"
echo "- Block profile: $ARTIFACTS_DIR/block.prof (analyze with: go tool pprof $ARTIFACTS_DIR/block.prof)"
echo "- Mutex profile: $ARTIFACTS_DIR/mutex.prof (analyze with: go tool pprof $ARTIFACTS_DIR/mutex.prof)"

# Exit with appropriate status code
if ! $OVERALL_SUCCESS; then
  exit 1
fi 