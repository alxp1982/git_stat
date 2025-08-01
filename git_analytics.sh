#!/bin/bash

# Git Analytics Script
# Counts PRs, commits, and lines of code for a specific user
# Usage: ./git_analytics.sh <username> [--github-username <github_username>] [--start-date YYYY-MM-DD] [--end-date YYYY-MM-DD] [repository_path]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables for date filtering
START_DATE=""
END_DATE=""
DATE_FILTER=""
GITHUB_USERNAME=""

# Function to print colored output
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_section() {
    echo -e "${CYAN}$1${NC}"
}

print_result() {
    echo -e "${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

print_error() {
    echo -e "${RED}Error: $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to build date filter string
build_date_filter() {
    DATE_FILTER=""
    if [ -n "$START_DATE" ] || [ -n "$END_DATE" ]; then
        if [ -n "$START_DATE" ] && [ -n "$END_DATE" ]; then
            DATE_FILTER="--since=\"$START_DATE\" --until=\"$END_DATE\""
            print_warning "Filtering commits from $START_DATE to $END_DATE"
        elif [ -n "$START_DATE" ]; then
            DATE_FILTER="--since=\"$START_DATE\""
            print_warning "Filtering commits from $START_DATE onwards"
        elif [ -n "$END_DATE" ]; then
            DATE_FILTER="--until=\"$END_DATE\""
            print_warning "Filtering commits until $END_DATE"
        fi
    fi
}

# Function to validate Git repository and navigate to repo root
validate_git_repo() {
    # Try to find git repository from current directory or parent directories
    local current_dir=$(pwd)
    local git_root=""
    
    # Check current directory and parent directories for .git
    while [ "$current_dir" != "/" ]; do
        if [ -d "$current_dir/.git" ]; then
            git_root="$current_dir"
            break
        fi
        current_dir=$(dirname "$current_dir")
    done
    
    if [ -z "$git_root" ]; then
        print_error "Not a Git repository. Please run this script from within a Git repository."
        exit 1
    fi
    
    # Navigate to git repository root if not already there
    if [ "$(pwd)" != "$git_root" ]; then
        print_warning "Navigating to Git repository root: $git_root"
        cd "$git_root"
    fi
}

# Function to check if user exists in Git history
check_user_exists() {
    local username="$1"
    if ! eval "git log --author=\"$username\" $DATE_FILTER --oneline -1" > /dev/null 2>&1; then
        print_warning "No commits found for user '$username' in this repository."
        if [ -n "$DATE_FILTER" ]; then
            print_warning "in the specified date range"
        fi
        return 1
    fi
    return 0
}

# Function to count Pull Requests (GitHub/GitLab)
count_pull_requests() {
    local username="$1"
    local pr_count=0
    
    # Use GitHub username if provided, otherwise use the regular username
    local pr_username="$username"
    if [ -n "$GITHUB_USERNAME" ]; then
        pr_username="$GITHUB_USERNAME"
        echo "Using GitHub username '$pr_username' for PR counting..."
    fi
    
    print_section "Counting Pull Requests..."
    
    # Try GitHub CLI if available
    if command_exists gh; then
        echo "Using GitHub CLI to count PRs..."
        # Check if GitHub CLI is authenticated
        if gh auth status >/dev/null 2>&1; then
            # Try to get PR count, but handle shell configuration issues
            pr_count=$(gh pr list --author "$pr_username" --json number --jq length 2>/dev/null 2>&1 || echo "0")
            # Check if the output contains error messages from shell configuration
            if echo "$pr_count" | grep -q "head:"; then
                echo "GitHub CLI command failed due to shell configuration. Trying alternative method..."
                # Try a simpler approach without jq
                pr_count=$(gh pr list --author "$pr_username" --limit 1000 2>/dev/null | wc -l || echo "0")
            fi
            
            # If we got a valid count, use it
            if [ "$pr_count" != "0" ] && [ "$pr_count" != "null" ] && [ "$pr_count" != "" ] && [ "$pr_count" -gt 0 ] 2>/dev/null; then
                print_result "Pull Requests: $pr_count"
                return
            fi
            
            # If we got 0, that might be correct
            if [ "$pr_count" = "0" ]; then
                echo "No PRs found for '$pr_username'."
                print_result "Pull Requests: 0"
                return
            fi
        else
            echo "GitHub CLI not authenticated. Run 'gh auth login' to authenticate."
        fi
    fi
    
    # Try GitLab CLI if available
    if command_exists glab; then
        echo "Using GitLab CLI to count MRs..."
        pr_count=$(glab mr list --author "$pr_username" --json id --jq length 2>/dev/null || echo "0")
        if [ "$pr_count" != "0" ] && [ "$pr_count" != "null" ]; then
            print_result "Merge Requests: $pr_count"
            return
        fi
    fi
    
    # Fallback: try to count from remote API with authentication
    local remote_url=$(git config --get remote.origin.url)
    if [[ "$remote_url" == *"github.com"* ]]; then
        local repo_name=$(echo "$remote_url" | sed 's/.*github\.com[:/]\([^/]*\/[^/]*\).*/\1/' | sed 's/\.git$//')
        echo "Attempting to count PRs from GitHub API..."
        
        # Try with GitHub token if available
        local headers=""
        if [ -n "$GITHUB_TOKEN" ]; then
            headers="-H \"Authorization: token $GITHUB_TOKEN\""
        fi
        
        pr_count=$(eval "curl -s $headers \"https://api.github.com/search/issues?q=author:$pr_username+repo:$repo_name+is:pr\"" | jq '.total_count' 2>/dev/null || echo "0")
        if [ "$pr_count" != "0" ] && [ "$pr_count" != "null" ] && [ "$pr_count" != "" ]; then
            print_result "Pull Requests: $pr_count"
            return
        fi
    fi
    
    print_warning "Could not determine PR count."
    echo ""
    echo "To enable PR counting, you can:"
    echo "1. Install and authenticate GitHub CLI: brew install gh && gh auth login"
    echo "2. Set GITHUB_TOKEN environment variable: export GITHUB_TOKEN='your_token'"
    echo "3. Check manually at: https://github.com/$(git config --get remote.origin.url | sed 's/.*github\.com[:/]\([^/]*\/[^/]*\).*/\1/' | sed 's/\.git$//')/pulls?q=author:$pr_username"
    echo ""
    print_result "Pull Requests: Unknown"
}

# Function to count commits across all branches
count_commits() {
    local username="$1"
    
    print_section "Counting Commits..."
    
    # Count commits by user across all branches with date filter
    local total_commits=$(eval "git log --all --author=\"$username\" $DATE_FILTER --oneline" | wc -l)
    local unique_commits=$(eval "git log --all --author=\"$username\" $DATE_FILTER --pretty=format:\"%H\"" | sort -u | wc -l)
    
    print_result "Total Commits: $total_commits"
    print_result "Unique Commits: $unique_commits"
    
    # Count commits by branch with date filter
    print_section "Commits by Branch:"
    git branch -r | while read branch; do
        branch_name=$(echo "$branch" | sed 's/origin\///')
        commit_count=$(eval "git log --author=\"$username\" $DATE_FILTER \"$branch\" --oneline" 2>/dev/null | wc -l)
        if [ "$commit_count" -gt 0 ]; then
            echo -e "  ${GREEN}$branch_name${NC}: $commit_count commits"
        fi
    done
    
    # Count commits by date range (relative to filtered range)
    print_section "Recent Activity (Last 30 days):"
    local recent_commits=$(eval "git log --all --author=\"$username\" $DATE_FILTER --since=\"30 days ago\" --oneline" | wc -l)
    print_result "Commits in last 30 days: $recent_commits"
}

# Function to count lines of code
count_lines_of_code() {
    local username="$1"
    
    print_section "Counting Lines of Code..."
    
    # Get all files modified by the user with date filter
    local temp_file=$(mktemp)
    eval "git log --all --author=\"$username\" $DATE_FILTER --name-only --pretty=format:" | sort -u > "$temp_file"
    
    local total_files=$(wc -l < "$temp_file")
    local total_loc=0
    local total_additions=0
    local total_deletions=0
    
    print_section "Analyzing files modified by $username..."
    
    # Count LOC for each file
    while IFS= read -r file; do
        if [ -n "$file" ] && [ -f "$file" ]; then
            # Count current lines in file
            local file_loc=$(wc -l < "$file" 2>/dev/null || echo "0")
            total_loc=$((total_loc + file_loc))
            
            # Count additions and deletions by this user with date filter
            local user_stats=$(eval "git log --all --author=\"$username\" $DATE_FILTER --pretty=tformat: --numstat \"$file\"" | awk '{add+=$1; del+=$2} END {print add, del}')
            local additions=$(echo "$user_stats" | awk '{print $1}')
            local deletions=$(echo "$user_stats" | awk '{print $2}')
            

            
            # Handle empty or invalid values - use numeric comparison
            if [ -n "$additions" ] && [ "$additions" -gt 0 ] 2>/dev/null; then
                total_additions=$((total_additions + additions))
            fi
            if [ -n "$deletions" ] && [ "$deletions" -gt 0 ] 2>/dev/null; then
                total_deletions=$((total_deletions + deletions))
            fi
        fi
    done < "$temp_file"
    
    rm "$temp_file"
    
    print_result "Files Modified: $total_files"
    print_result "Total Lines of Code: $total_loc"
    print_result "Lines Added: $total_additions"
    print_result "Lines Deleted: $total_deletions"
    print_result "Net Lines: $((total_additions - total_deletions))"
}

# Function to get detailed commit statistics
get_commit_stats() {
    local username="$1"
    
    print_section "Detailed Commit Statistics..."
    
    # First commit with date filter
    local first_commit=$(eval "git log --all --author=\"$username\" $DATE_FILTER --pretty=format:\"%ad\" --date=short" | tail -1)
    # Last commit with date filter
    local last_commit=$(eval "git log --all --author=\"$username\" $DATE_FILTER --pretty=format:\"%ad\" --date=short" | head -1)
    
    if [ -n "$first_commit" ] && [ -n "$last_commit" ]; then
        print_result "First Commit: $first_commit"
        print_result "Last Commit: $last_commit"
        
        # Calculate days between first and last commit
        local first_date=$(date -d "$first_commit" +%s 2>/dev/null || echo "0")
        local last_date=$(date -d "$last_commit" +%s 2>/dev/null || echo "0")
        
        if [ "$first_date" -gt 0 ] && [ "$last_date" -gt 0 ]; then
            local days_diff=$(( (last_date - first_date) / 86400 ))
            print_result "Days Active: $days_diff"
        fi
    fi
    
    # Commits by year with date filter
    print_section "Commits by Year:"
    eval "git log --all --author=\"$username\" $DATE_FILTER --pretty=format:\"%ad\" --date=short" | cut -d'-' -f1 | sort | uniq -c | sort -nr | while read count year; do
        if [ -n "$year" ] && [ "$year" != "0000" ]; then
            echo -e "  ${GREEN}$year${NC}: $count commits"
        fi
    done
    
    # Most active day of week with date filter
    print_section "Most Active Day of Week:"
    local most_active_day=$(eval "git log --all --author=\"$username\" $DATE_FILTER --pretty=format:\"%aD\"" | xargs -I {} date -d "{}" +%A 2>/dev/null | sort | uniq -c | sort -nr | head -1)
    if [ -n "$most_active_day" ]; then
        local day_count=$(echo "$most_active_day" | awk '{print $1}')
        local day_name=$(echo "$most_active_day" | awk '{print $2}')
        print_result "Most Active Day: $day_name ($day_count commits)"
    fi
}

# Function to generate summary
generate_summary() {
    local username="$1"
    
    print_header "Git Analytics Summary"
    print_result "User: $username"
    print_result "Repository: $(basename $(git rev-parse --show-toplevel))"
    print_result "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    
    if [ -n "$DATE_FILTER" ]; then
        print_warning "Date Range Filter Applied"
    fi
    
    echo ""
    print_section "Quick Stats:"
    
    # Get basic stats with date filter
    local total_commits=$(eval "git log --all --author=\"$username\" $DATE_FILTER --oneline" | wc -l)
    local recent_commits=$(eval "git log --all --author=\"$username\" $DATE_FILTER --since=\"30 days ago\" --oneline" | wc -l)
    
    print_result "Total Commits: $total_commits"
    print_result "Recent Activity (30 days): $recent_commits"
    
    if [ "$total_commits" -gt 0 ]; then
        local activity_score=$((total_commits * 10 + recent_commits * 50))
        print_result "Activity Score: $activity_score"
    fi
}

# Function to parse command line arguments
parse_arguments() {
    local username=""
    local repo_path="."
    local github_username=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --github-username)
                github_username="$2"
                shift 2
                ;;
            --start-date)
                START_DATE="$2"
                shift 2
                ;;
            --end-date)
                END_DATE="$2"
                shift 2
                ;;
            -*)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
            *)
                if [ -z "$username" ]; then
                    username="$1"
                elif [ -z "$repo_path" ] || [ "$repo_path" = "." ]; then
                    repo_path="$1"
                else
                    echo "Too many arguments. Use --help for usage information"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    if [ -z "$username" ]; then
        print_error "Usage: $0 <username> [--github-username <github_username>] [--start-date YYYY-MM-DD] [--end-date YYYY-MM-DD] [repository_path]"
        echo "Use --help for more information"
        exit 1
    fi
    
    echo "$username:$repo_path:$github_username"
}

# Main function
main() {
    # Parse arguments
    local args_result=$(parse_arguments "$@")
    local username=$(echo "$args_result" | cut -d':' -f1)
    local repo_path=$(echo "$args_result" | cut -d':' -f2)
    GITHUB_USERNAME=$(echo "$args_result" | cut -d':' -f3)
    
    # Build date filter
    build_date_filter
    
    # Change to repository directory if specified
    if [ "$repo_path" != "." ]; then
        if [ ! -d "$repo_path" ]; then
            print_error "Repository path '$repo_path' does not exist."
            exit 1
        fi
        cd "$repo_path"
    fi
    
    # Validate Git repository
    validate_git_repo
    
    # Check if user exists in history
    if ! check_user_exists "$username"; then
        print_error "No commits found for user '$username' in this repository."
        if [ -n "$DATE_FILTER" ]; then
            print_error "in the specified date range"
        fi
        exit 1
    fi
    
    # Generate summary
    generate_summary "$username"
    
    # Count pull requests
    count_pull_requests "$username"
    
    # Count commits
    count_commits "$username"
    
    # Count lines of code
    count_lines_of_code "$username"
    
    # Get detailed commit statistics
    get_commit_stats "$username"
    
    print_header "Analysis Complete"
    print_result "All statistics have been generated for user: $username"
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command_exists git; then
        missing_deps+=("git")
    fi
    
    if ! command_exists awk; then
        missing_deps+=("awk")
    fi
    
    if ! command_exists wc; then
        missing_deps+=("wc")
    fi
    
    if ! command_exists sort; then
        missing_deps+=("sort")
    fi
    
    if ! command_exists uniq; then
        missing_deps+=("uniq")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
    
    # Optional dependencies
    if ! command_exists jq; then
        print_warning "jq not found. Some features may be limited."
    fi
    
    if ! command_exists curl; then
        print_warning "curl not found. GitHub API features will be disabled."
    fi
}

# Check for help before running main
for arg in "$@"; do
    if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
        echo "Usage: $0 <username> [--github-username <github_username>] [--start-date YYYY-MM-DD] [--end-date YYYY-MM-DD] [repository_path]"
        echo ""
        echo "Options:"
        echo "  --github-username USER   GitHub username for PR counting (different from Git author name)"
        echo "  --start-date YYYY-MM-DD  Filter commits from this date (inclusive)"
        echo "  --end-date YYYY-MM-DD    Filter commits until this date (inclusive)"
        echo "  --help, -h               Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 'Alex Panin'"
        echo "  $0 'Alex Panin' --github-username alxp1982"
        echo "  $0 'Alex Panin' --github-username alxp1982 --start-date 2024-01-01"
        echo "  $0 'Alex Panin' --github-username alxp1982 --start-date 2024-01-01 --end-date 2024-12-31"
        echo "  $0 'Alex Panin' --github-username alxp1982 /path/to/repo"
        exit 0
    fi
done

# Run dependency check and main function
check_dependencies
main "$@" 