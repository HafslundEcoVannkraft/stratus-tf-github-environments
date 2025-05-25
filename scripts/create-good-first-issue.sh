#!/bin/bash

# Helper script to create good first issues from the predefined list
# Usage: ./scripts/create-good-first-issue.sh [issue_number]
# Purpose: Maintainer tool for creating beginner-friendly contribution opportunities

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Show help if requested
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo -e "${BLUE}🌟 Good First Issue Creator${NC}"
    echo ""
    echo -e "${CYAN}PURPOSE:${NC}"
    echo "This script helps maintainers create predefined, beginner-friendly issues"
    echo "for new contributors. It focuses on safe, guided tasks that help people"
    echo "learn the codebase without risk of breaking anything."
    echo ""
    echo -e "${CYAN}USAGE:${NC}"
    echo "  ./scripts/create-good-first-issue.sh [issue_number]"
    echo "  ./scripts/create-good-first-issue.sh --help"
    echo ""
    echo -e "${CYAN}EXAMPLES:${NC}"
    echo "  ./scripts/create-good-first-issue.sh 1    # Create issue #1 (fix typos)"
    echo "  ./scripts/create-good-first-issue.sh      # Interactive mode"
    echo ""
    echo -e "${CYAN}LOOKING FOR SOMETHING ELSE?${NC}"
    echo "• 🐛 Bug reports: Use GitHub issue templates"
    echo "• ✨ Feature requests: Use GitHub issue templates"
    echo "• ❓ Questions: Check our Support documentation"
    echo "• 📚 Documentation: Check CONTRIBUTING.md"
    echo ""
    echo -e "${YELLOW}This script is specifically for maintainers creating beginner tasks.${NC}"
    exit 0
fi

echo -e "${BLUE}🌟 Good First Issue Creator${NC}"
echo -e "${CYAN}Maintainer tool for creating beginner-friendly contribution opportunities${NC}"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed.${NC}"
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ Not authenticated with GitHub CLI.${NC}"
    echo "Please run: gh auth login"
    exit 1
fi

echo -e "${GREEN}✅ GitHub CLI is ready!${NC}"
echo ""

# Show available issues from the list
echo -e "${YELLOW}📋 Available Good First Issues:${NC}"
echo ""
echo "📚 Documentation (Easy):"
echo "  1. Fix typos in README.md"
echo "  2. Add missing periods to bullet points"
echo "  3. Improve code block formatting"
echo ""
echo "📚 Documentation (Medium):"
echo "  4. Add more configuration examples"
echo "  5. Create troubleshooting FAQ"
echo "  6. Improve variable documentation"
echo ""
echo "🧪 Testing (Easy):"
echo "  7. Test example configurations"
echo "  8. Add comments to example YAML files"
echo ""
echo "🧪 Testing (Medium):"
echo "  9. Create minimal working example"
echo "  10. Add validation script for examples"
echo ""
echo "🎨 UX (Easy):"
echo "  15. Add more emoji to documentation"
echo "  16. Improve section headings"
echo ""
echo "🐛 Bug Fixes (Easy):"
echo "  19. Fix inconsistent naming in documentation"
echo "  20. Fix broken internal links"
echo ""

# Get issue number from user
if [ -z "$1" ]; then
    echo -e "${BLUE}Which issue would you like to create? (1-20):${NC}"
    read -r ISSUE_NUM
else
    ISSUE_NUM=$1
fi

# Create the issue based on selection
case $ISSUE_NUM in
    1)
        TITLE="[Good First Issue] Fix typos in README.md"
        BODY="## 🌟 Good First Issue - Fix Typos in README.md

**Difficulty**: 🟢 Easy (30 minutes or less)
**Category**: 📚 Documentation

### What needs to be done?
Scan through our README.md file and fix any spelling or grammar errors you find.

### Why is this important?
- Improves readability and professionalism
- Makes documentation more accessible
- Shows attention to detail

### Step-by-step guide:
1. Fork the repository
2. Open \`README.md\` in your editor
3. Read through the entire file carefully
4. Fix any typos, spelling errors, or grammar issues you find
5. Test that all links still work
6. Submit a pull request with your fixes

### Acceptance criteria:
- [ ] All obvious typos are fixed
- [ ] Grammar is improved where needed
- [ ] No new errors are introduced
- [ ] Links still work correctly

### Need help?
- Check our [Contributing Guide](./CONTRIBUTING.md)
- Ask questions in the comments below
- We're here to help! 🤝

**Ready to start?** Comment below to let us know you're working on this!"
        LABELS="good first issue,help wanted,documentation,easy"
        ;;
    2)
        TITLE="[Good First Issue] Add missing periods to bullet points"
        BODY="## 🌟 Good First Issue - Consistent Punctuation

**Difficulty**: 🟢 Easy (30 minutes or less)
**Category**: 📚 Documentation

### What needs to be done?
Ensure all bullet points in our documentation have consistent punctuation (periods at the end).

### Why is this important?
- Professional documentation standards
- Consistency improves readability
- Attention to detail matters

### Files to check:
- \`README.md\`
- \`CONTRIBUTING.md\`
- \`CONTRIBUTING_COMMUNITY.md\`

### Step-by-step guide:
1. Fork the repository
2. Open each documentation file
3. Look for bullet point lists
4. Add periods where missing (be consistent within each list)
5. Submit a pull request

### Acceptance criteria:
- [ ] All bullet points in lists have consistent punctuation
- [ ] No existing formatting is broken
- [ ] Changes follow the existing style

**Ready to start?** Comment below to claim this issue!"
        LABELS="good first issue,help wanted,documentation,easy"
        ;;
    7)
        TITLE="[Good First Issue] Test example configurations"
        BODY="## 🌟 Good First Issue - Test Example Configurations

**Difficulty**: 🟢 Easy (30 minutes or less)
**Category**: 🧪 Testing

### What needs to be done?
Run \`terraform validate\` on our example YAML files to ensure they work correctly.

### Why is this important?
- Ensures our examples actually work
- Prevents user frustration
- Maintains quality standards

### Step-by-step guide:
1. Fork the repository
2. Install Terraform (if not already installed)
3. Navigate to the \`examples/\` directory
4. For each YAML file, run: \`terraform validate\`
5. Report any errors you find as comments
6. If everything works, confirm in a comment

### Files to test:
- \`examples/minimal.yaml\`
- \`examples/complete.yaml\`
- Any other \`.yaml\` files in examples/

### Acceptance criteria:
- [ ] All example files have been tested
- [ ] Any errors are documented
- [ ] Working examples are confirmed

### Need Terraform help?
- [Terraform Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- Ask questions in the comments!

**Ready to start?** Comment below to claim this issue!"
        LABELS="good first issue,help wanted,testing,easy"
        ;;
    *)
        echo -e "${RED}❌ Invalid issue number. Please choose 1-20.${NC}"
        exit 1
        ;;
esac

# Create the issue
echo -e "${BLUE}Creating issue: $TITLE${NC}"
echo ""

gh issue create \
    --title "$TITLE" \
    --body "$BODY" \
    --label "$LABELS"

echo ""
echo -e "${GREEN}✅ Issue created successfully!${NC}"
echo ""
echo -e "${BLUE}🔗 View all good first issues:${NC}"
echo "https://github.com/HafslundEcoVannkraft/stratus-tf-aca-gh-vending/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22"
echo ""
echo -e "${CYAN}💡 Need to create other types of issues?${NC}"
echo "• 🐛 Bug reports: https://github.com/HafslundEcoVannkraft/stratus-tf-aca-gh-vending/issues/new?template=bug-report.yml"
echo "• ✨ Feature requests: https://github.com/HafslundEcoVannkraft/stratus-tf-aca-gh-vending/issues/new?template=feature-request.yml"
echo "• 🌟 More good first issues: Use this script again!"
echo ""
echo -e "${YELLOW}This script focuses on beginner-friendly tasks to welcome new contributors.${NC}" 