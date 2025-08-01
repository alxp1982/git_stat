#!/bin/bash

# Quick Git Stats Script
# Simple version for quick statistics
# Usage: ./quick_git_stats.sh <username> [--start-date YYYY-MM-DD] [--end-date YYYY-MM-DD]

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
start_date=""
end_date=""
username=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --start-date)
            start_date="$2"
            shift 2
            ;;
        --end-date)
            end_date="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 <username> [--start-date YYYY-MM-DD] [--end-date YYYY-MM-DD]"
            echo ""
            echo "Options:"
            echo "  --start-date YYYY-MM-DD  Filter commits from this date (inclusive)"
            echo "  --end-date YYYY-MM-DD    Filter commits until this date (inclusive)"
            echo "  --help, -h               Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 john.doe"
            echo "  $0 john.doe --start-date 2024-01-01"
            echo "  $0 john.doe --start-date 2024-01-01 --end-date 2024-12-31"
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            if [ -z "$username" ]; then
                username="$1"
            else
                echo "Multiple usernames specified. Use --help for usage information"
                exit 1
            fi
            shift
            ;;
    esac
done

if [ -z "$username" ]; then
    echo "Usage: $0 <username> [--start-date YYYY-MM-DD] [--end-date YYYY-MM-DD]"
    echo "Use --help for more information"
    exit 1
fi

# Build date filter
date_filter=""
if [ -n "$start_date" ] || [ -n "$end_date" ]; then
    if [ -n "$start_date" ] && [ -n "$end_date" ]; then
        date_filter="--since=\"$start_date\" --until=\"$end_date\""
        echo -e "${YELLOW}Filtering commits from $start_date to $end_date${NC}"
    elif [ -n "$start_date" ]; then
        date_filter="--since=\"$start_date\""
        echo -e "${YELLOW}Filtering commits from $start_date onwards${NC}"
    elif [ -n "$end_date" ]; then
        date_filter="--until=\"$end_date\""
        echo -e "${YELLOW}Filtering commits until $end_date${NC}"
    fi
fi

echo -e "${BLUE}Quick Git Stats for: $username${NC}"
echo "=================================="

# Try to find git repository from current directory or parent directories
current_dir=$(pwd)
git_root=""

# Check current directory and parent directories for .git
while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.git" ]; then
        git_root="$current_dir"
        break
    fi
    current_dir=$(dirname "$current_dir")
done

if [ -z "$git_root" ]; then
    echo "Not a Git repository. Please run this script from within a Git repository."
    exit 1
fi

# Navigate to git repository root if not already there
if [ "$(pwd)" != "$git_root" ]; then
    echo -e "${YELLOW}Navigating to Git repository root: $git_root${NC}"
    cd "$git_root"
fi

# Check if user exists with date filter
if ! eval "git log --author=\"$username\" $date_filter --oneline -1" > /dev/null 2>&1; then
    echo "No commits found for user '$username'"
    if [ -n "$date_filter" ]; then
        echo "in the specified date range"
    fi
    exit 1
fi

# Quick stats with date filter
total_commits=$(eval "git log --all --author=\"$username\" $date_filter --oneline" | wc -l)
recent_commits=$(eval "git log --all --author=\"$username\" $date_filter --since=\"30 days ago\" --oneline" | wc -l)
files_modified=$(eval "git log --all --author=\"$username\" $date_filter --name-only --pretty=format:" | sort -u | wc -l)

echo -e "${GREEN}Total Commits: $total_commits${NC}"
echo -e "${GREEN}Recent Commits (30 days): $recent_commits${NC}"
echo -e "${GREEN}Files Modified: $files_modified${NC}"

# Lines of code (simplified) with date filter
total_additions=0
total_deletions=0

# Use a different approach to avoid subshell issues
while read additions deletions file; do
    if [ -n "$additions" ] && [ "$additions" != "-" ]; then
        total_additions=$((total_additions + additions))
    fi
    if [ -n "$deletions" ] && [ "$deletions" != "-" ]; then
        total_deletions=$((total_deletions + deletions))
    fi
done < <(eval "git log --all --author=\"$username\" $date_filter --pretty=tformat: --numstat")

echo -e "${GREEN}Lines Added: $total_additions${NC}"
echo -e "${GREEN}Lines Deleted: $total_deletions${NC}"
echo -e "${GREEN}Net Lines: $((total_additions - total_deletions))${NC}"

echo "==================================" 