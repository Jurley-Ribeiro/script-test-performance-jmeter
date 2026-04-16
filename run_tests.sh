#!/bin/bash
# =============================================================================
# BlazeDemo Performance Test Runner
# Executes Load Test and Spike Test, then generates HTML reports
# =============================================================================

set -e

# ── Config ────────────────────────────────────────────────────────────────────
JMETER_VERSION="5.6.3"
JMETER_DIR="$HOME/apache-jmeter-${JMETER_VERSION}"
JMETER_BIN="${JMETER_DIR}/bin/jmeter"
JMETER_ZIP="apache-jmeter-${JMETER_VERSION}.zip"
JMETER_URL="https://archive.apache.org/dist/jmeter/binaries/${JMETER_ZIP}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="${SCRIPT_DIR}/tests"
RESULTS_DIR="${SCRIPT_DIR}/results"
REPORTS_DIR="${SCRIPT_DIR}/reports"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
log()     { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
section() { echo -e "\n${BLUE}══════════════════════════════════════${NC}"; \
            echo -e "${BLUE}  $1${NC}"; \
            echo -e "${BLUE}══════════════════════════════════════${NC}\n"; }

# ── Check Java ────────────────────────────────────────────────────────────────
check_java() {
  section "Checking Java"
  if ! command -v java &>/dev/null; then
    error "Java not found. Install with: sudo apt install default-jdk"
  fi
  JAVA_VER=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
  log "Java version: ${JAVA_VER}"
}

# ── Install JMeter ────────────────────────────────────────────────────────────
install_jmeter() {
  section "Setting up JMeter ${JMETER_VERSION}"
  if [ -f "${JMETER_BIN}" ]; then
    log "JMeter already installed at ${JMETER_DIR}"
    return
  fi

  log "Downloading JMeter ${JMETER_VERSION}..."
  if command -v wget &>/dev/null; then
    wget -q --show-progress "${JMETER_URL}" -O "/tmp/${JMETER_ZIP}"
  elif command -v curl &>/dev/null; then
    curl -L --progress-bar "${JMETER_URL}" -o "/tmp/${JMETER_ZIP}"
  else
    error "Neither wget nor curl found. Install one of them."
  fi

  log "Extracting JMeter to $HOME..."
  unzip -q "/tmp/${JMETER_ZIP}" -d "$HOME"
  rm "/tmp/${JMETER_ZIP}"
  chmod +x "${JMETER_BIN}"
  log "JMeter installed successfully!"
}

# ── Prepare directories ───────────────────────────────────────────────────────
prepare_dirs() {
  section "Preparing directories"
  mkdir -p "${RESULTS_DIR}" "${REPORTS_DIR}/load_test" "${REPORTS_DIR}/spike_test"
  # Remove old results to avoid JMeter conflicts
  rm -f "${RESULTS_DIR}/load_test_results.jtl"
  rm -f "${RESULTS_DIR}/spike_test_results.jtl"
  rm -rf "${REPORTS_DIR}/load_test"/*
  rm -rf "${REPORTS_DIR}/spike_test"/*
  log "Directories ready."
}

# ── Run Load Test ─────────────────────────────────────────────────────────────
run_load_test() {
  section "Running LOAD TEST"
  log "Target: 250 req/s | Threads: 300 | Ramp: 60s | Duration: 6 min"
  log "Results: ${RESULTS_DIR}/load_test_results.jtl"

  "${JMETER_BIN}" -n \
    -t "${TESTS_DIR}/load_test.jmx" \
    -l "${RESULTS_DIR}/load_test_results.jtl" \
    -e -o "${REPORTS_DIR}/load_test" \
    -j "${RESULTS_DIR}/load_test.log" \
    2>&1 | grep -E "(summary|ERROR|WARN|Starting)" || true

  log "Load test completed! Report: ${REPORTS_DIR}/load_test/index.html"
}

# ── Run Spike Test ────────────────────────────────────────────────────────────
run_spike_test() {
  section "Running SPIKE TEST"
  log "Baseline: 50 threads → Spike: 500 threads at 60s → Recovery"
  log "Results: ${RESULTS_DIR}/spike_test_results.jtl"

  "${JMETER_BIN}" -n \
    -t "${TESTS_DIR}/spike_test.jmx" \
    -l "${RESULTS_DIR}/spike_test_results.jtl" \
    -e -o "${REPORTS_DIR}/spike_test" \
    -j "${RESULTS_DIR}/spike_test.log" \
    2>&1 | grep -E "(summary|ERROR|WARN|Starting)" || true

  log "Spike test completed! Report: ${REPORTS_DIR}/spike_test/index.html"
}

# ── Print Summary ─────────────────────────────────────────────────────────────
print_summary() {
  section "Test Execution Summary"
  echo -e "  📁 JTL Results:"
  echo -e "     Load  → ${RESULTS_DIR}/load_test_results.jtl"
  echo -e "     Spike → ${RESULTS_DIR}/spike_test_results.jtl"
  echo ""
  echo -e "  📊 HTML Reports:"
  echo -e "     Load  → ${REPORTS_DIR}/load_test/index.html"
  echo -e "     Spike → ${REPORTS_DIR}/spike_test/index.html"
  echo ""
  echo -e "  💡 Open the reports in a browser:"
  echo -e "     xdg-open ${REPORTS_DIR}/load_test/index.html"
  echo -e "     xdg-open ${REPORTS_DIR}/spike_test/index.html"
  echo ""
}

# ── Argument Parsing ──────────────────────────────────────────────────────────
usage() {
  echo "Usage: $0 [--load-only | --spike-only | --install-only | --help]"
  echo ""
  echo "  (no args)      Install JMeter + run both tests"
  echo "  --load-only    Run only the load test"
  echo "  --spike-only   Run only the spike test"
  echo "  --install-only Install JMeter only, do not run tests"
  echo "  --help         Show this help"
}

RUN_LOAD=true
RUN_SPIKE=true

for arg in "$@"; do
  case $arg in
    --load-only)   RUN_SPIKE=false ;;
    --spike-only)  RUN_LOAD=false ;;
    --install-only) RUN_LOAD=false; RUN_SPIKE=false ;;
    --help) usage; exit 0 ;;
    *) warn "Unknown argument: $arg"; usage; exit 1 ;;
  esac
done

# ── Main ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   BlazeDemo Performance Test Suite       ║${NC}"
echo -e "${BLUE}║   blazedemo.com | JMeter ${JMETER_VERSION}          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"

check_java
install_jmeter
prepare_dirs

$RUN_LOAD  && run_load_test
$RUN_SPIKE && run_spike_test

print_summary
