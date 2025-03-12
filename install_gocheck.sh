#!/usr/bin/env bash
# install_gocheck.sh: Install gocheck in your PATH and set up shell aliases
# Usage: ./install_gocheck.sh [destination]

set -euo pipefail

# Default installation directory
INSTALL_DIR="${1:-$HOME/bin}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/gocheck.sh"
DEST_SCRIPT="$INSTALL_DIR/gocheck"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if source script exists
if [ ! -f "$SOURCE_SCRIPT" ]; then
  echo -e "${RED}Error: Source script not found at $SOURCE_SCRIPT${NC}"
  exit 1
fi

# Create installation directory if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
  echo -e "${YELLOW}Creating directory $INSTALL_DIR${NC}"
  mkdir -p "$INSTALL_DIR"
fi

# Check if directory is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo -e "${YELLOW}Warning: $INSTALL_DIR is not in your PATH.${NC}"
  echo -e "${YELLOW}Consider adding the following to your shell profile:${NC}"
  echo -e "${BLUE}export PATH=\"\$PATH:$INSTALL_DIR\"${NC}"
fi

# Copy the script
echo -e "${BLUE}Installing gocheck to $DEST_SCRIPT${NC}"
cp "$SOURCE_SCRIPT" "$DEST_SCRIPT"
chmod +x "$DEST_SCRIPT"

# Create shell aliases
SHELL_TYPE="$(basename "$SHELL")"
SHELL_PROFILE=""

case "$SHELL_TYPE" in
  bash)
    SHELL_PROFILE="$HOME/.bashrc"
    ;;
  zsh)
    SHELL_PROFILE="$HOME/.zshrc"
    ;;
  *)
    echo -e "${YELLOW}Unknown shell type: $SHELL_TYPE${NC}"
    echo -e "${YELLOW}Please manually add aliases to your shell profile.${NC}"
    ;;
esac

if [ -n "$SHELL_PROFILE" ]; then
  echo -e "${BLUE}Adding aliases to $SHELL_PROFILE${NC}"
  
  # Check if aliases already exist
  if grep -q "alias gck=" "$SHELL_PROFILE"; then
    echo -e "${YELLOW}Aliases already exist in $SHELL_PROFILE${NC}"
  else
    cat << EOF >> "$SHELL_PROFILE"

# gocheck aliases
alias gck='gocheck'
alias gckf='gocheck --focus=\$(go list)'
alias gckt='gocheck --no-lint --no-static --no-bench --no-vuln'
alias gckb='gocheck --no-lint --no-static --no-test --no-vuln'
EOF
    echo -e "${GREEN}Aliases added to $SHELL_PROFILE${NC}"
  fi
fi

# Create VS Code task configuration
if [ -d ".vscode" ]; then
  TASKS_FILE=".vscode/tasks.json"
  
  if [ ! -f "$TASKS_FILE" ]; then
    echo -e "${BLUE}Creating VS Code tasks configuration${NC}"
    mkdir -p ".vscode"
    cat << EOF > "$TASKS_FILE"
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Go Check",
      "type": "shell",
      "command": "gocheck",
      "group": {
        "kind": "test",
        "isDefault": true
      },
      "presentation": {
        "reveal": "always",
        "panel": "dedicated"
      },
      "problemMatcher": []
    },
    {
      "label": "Go Check (Tests Only)",
      "type": "shell",
      "command": "gocheck --no-lint --no-static --no-bench --no-vuln",
      "group": "test",
      "presentation": {
        "reveal": "always",
        "panel": "dedicated"
      },
      "problemMatcher": []
    },
    {
      "label": "Go Check (Benchmarks Only)",
      "type": "shell",
      "command": "gocheck --no-lint --no-static --no-test --no-vuln",
      "group": "test",
      "presentation": {
        "reveal": "always",
        "panel": "dedicated"
      },
      "problemMatcher": []
    }
  ]
}
EOF
    echo -e "${GREEN}VS Code tasks configuration created${NC}"
  else
    echo -e "${YELLOW}VS Code tasks.json already exists. Please add gocheck tasks manually.${NC}"
  fi
fi

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${BLUE}Usage:${NC}"
echo -e "  ${YELLOW}gocheck${NC} - Run all checks"
echo -e "  ${YELLOW}gck${NC} - Alias for gocheck"
echo -e "  ${YELLOW}gckf${NC} - Run checks on current package only"
echo -e "  ${YELLOW}gckt${NC} - Run tests only"
echo -e "  ${YELLOW}gckb${NC} - Run benchmarks only"
echo -e ""
echo -e "${BLUE}You may need to restart your shell or run 'source $SHELL_PROFILE' to use the aliases.${NC}" 