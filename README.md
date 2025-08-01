# Git Analytics Scripts

This directory contains scripts for analyzing Git repository statistics and user contributions.

## 🚀 Quick Start

Choose the script that best fits your needs:

### 1. Quick Stats (`quick_git_stats.sh`) - Fast & Simple
```bash
# From repository root
./utils/quick_git_stats.sh <username>
./utils/quick_git_stats.sh <username> --start-date 2024-01-01
./utils/quick_git_stats.sh <username> --start-date 2024-01-01 --end-date 2024-12-31

# From any subdirectory
cd utils && ./quick_git_stats.sh <username>
```

### 2. Full Analytics (`git_analytics.sh`) - Comprehensive Bash Script
```bash
# From repository root
./utils/git_analytics.sh <username>
./utils/git_analytics.sh <username> --start-date 2024-01-01
./utils/git_analytics.sh <username> --start-date 2024-01-01 --end-date 2024-12-31

# From any subdirectory
cd utils && ./git_analytics.sh <username>
```

### 3. Advanced Analytics (`git_analytics.py`) - Python with JSON Output
```bash
# From repository root
python3 utils/git_analytics.py <username> --format json --output report.json
python3 utils/git_analytics.py <username> --start-date 2024-01-01 --format json
python3 utils/git_analytics.py <username> --start-date 2024-01-01 --end-date 2024-12-31 --format json

# From any subdirectory
cd utils && python3 git_analytics.py <username> --format json
```

## 📊 Git Analytics Script (`git_analytics.sh`)

A comprehensive script that analyzes Git repository statistics for a specific user, including:

- **Pull Request Count** - Number of PRs/MRs created
- **Commit Statistics** - Total commits across all branches
- **Lines of Code** - Lines added, deleted, and net contribution
- **Activity Analysis** - Commit patterns, time periods, and activity scores

### 🚀 Quick Start

```bash
# Basic usage (run from repository root)
./scripts/git_analytics.sh <username>

# Example
./scripts/git_analytics.sh john.doe

# Run from different directory
./scripts/git_analytics.sh john.doe /path/to/repo
```

### 📋 Features

#### 1. Pull Request Analysis
- **GitHub CLI Integration** - Uses `gh` command if available
- **GitLab CLI Integration** - Uses `glab` command if available
- **GitHub API Fallback** - Direct API calls for public repositories
- **Manual Verification** - Prompts for manual check if automated methods fail

#### 2. Commit Statistics
- **Total Commits** - All commits by user across all branches
- **Unique Commits** - Deduplicated commit count
- **Branch Analysis** - Commits per branch breakdown
- **Recent Activity** - Commits in last 30 days
- **Time Analysis** - Commits by year and day of week

#### 3. Lines of Code Analysis
- **Files Modified** - Total number of files touched
- **Current LOC** - Lines of code in files currently in repository
- **Lines Added** - Total lines added by user
- **Lines Deleted** - Total lines deleted by user
- **Net Contribution** - Net lines added (additions - deletions)

#### 4. Detailed Statistics
- **Activity Timeline** - First and last commit dates
- **Days Active** - Total days between first and last commit
- **Yearly Breakdown** - Commits per year
- **Activity Patterns** - Most active day of week
- **Activity Score** - Calculated engagement metric

### 🔧 Requirements

#### Required Dependencies
- `git` - Git version control system
- `awk` - Text processing utility
- `wc` - Word count utility
- `sort` - Sorting utility
- `uniq` - Unique line filtering

#### Optional Dependencies
- `gh` - GitHub CLI (for PR counting)
- `glab` - GitLab CLI (for MR counting)
- `jq` - JSON processor (for API responses)
- `curl` - HTTP client (for API calls)

### 📊 Sample Output

```
================================
Git Analytics Summary
================================
User: john.doe
Repository: shopping-calc-app
Generated: 2024-12-19 14:30:25

Quick Stats:
Total Commits: 45
Unique Commits: 42
Recent Activity (30 days): 12
Activity Score: 1050

Counting Pull Requests...
Using GitHub CLI to count PRs...
Pull Requests: 8

Counting Commits...
Total Commits: 45
Unique Commits: 42
Commits by Branch:
  main: 25 commits
  feature/auto-save: 15 commits
  bugfix/auth: 5 commits
Recent Activity (Last 30 days):
Commits in last 30 days: 12

Counting Lines of Code...
Files Modified: 23
Total Lines of Code: 15420
Lines Added: 2847
Lines Deleted: 1234
Net Lines: 1613

Detailed Commit Statistics...
First Commit: 2024-01-15
Last Commit: 2024-12-19
Days Active: 338
Commits by Year:
  2024: 45 commits
Most Active Day of Week:
  Wednesday: 12 commits

================================
Analysis Complete
================================
All statistics have been generated for user: john.doe
```

### 🎯 Use Cases

#### For Project Managers
- **Team Performance** - Track individual contributions
- **Project Health** - Monitor activity levels
- **Resource Planning** - Identify most active contributors

#### For Developers
- **Personal Analytics** - Track your own contributions
- **Portfolio Building** - Generate statistics for resumes
- **Code Review** - Understand your impact on projects

#### For Open Source Projects
- **Contributor Recognition** - Acknowledge top contributors
- **Community Health** - Monitor project activity
- **Documentation** - Generate contribution reports

### 🔍 Advanced Usage

#### Custom Date Ranges
```bash
# The script automatically shows recent activity, but you can modify it
# Edit the script to change the "30 days ago" period
```

#### Multiple Users
```bash
# Run for multiple users
for user in user1 user2 user3; do
    ./utils/git_analytics.sh "$user" > "report_${user}.txt"
done
```

#### Export to File
```bash
# Save output to file
./utils/git_analytics.sh john.doe > analytics_report.txt

# Save with timestamp
./utils/git_analytics.sh john.doe > "analytics_$(date +%Y%m%d_%H%M%S).txt"
```

### ⚠️ Limitations

1. **PR Counting** - Requires GitHub/GitLab CLI or API access
2. **Private Repos** - API calls may fail for private repositories
3. **Large Repositories** - May be slow for very large codebases
4. **Git History** - Only analyzes current Git history (not deleted branches)

### 🛠️ Troubleshooting

#### Common Issues

**"Not a Git repository"**
```bash
# Make sure you're in a Git repository
cd /path/to/your/repo
./utils/git_analytics.sh username
```

**"No commits found for user"**
```bash
# Check if the username matches Git author names
git log --pretty=format:"%an" | sort -u | grep -i "username"
```

**"Could not determine PR count"**
```bash
# Install GitHub CLI
# macOS: brew install gh
# Ubuntu: sudo apt install gh
# Then authenticate: gh auth login
```

#### Performance Tips

- **Large Repositories**: The script may take time for large codebases
- **Network Issues**: API calls may timeout on slow connections
- **Memory Usage**: Very large repositories may use significant memory

### 📈 Activity Score Calculation

The activity score is calculated as:
```
Activity Score = (Total Commits × 10) + (Recent Commits × 50)
```

This gives more weight to recent activity while considering overall contribution.

### 🔄 Updates and Maintenance

The script is designed to be:
- **Self-contained** - Minimal external dependencies
- **Cross-platform** - Works on macOS, Linux, and Windows (with Git Bash)
- **Extensible** - Easy to add new metrics or modify existing ones

## 🐍 Python Analytics Script (`git_analytics.py`)

Advanced Git analytics with JSON output support and enhanced data processing.

### Features
- **JSON Output** - Machine-readable format for further processing
- **Enhanced Statistics** - More detailed analysis than bash version
- **File Extension Analysis** - Breakdown by file types
- **Largest Files** - Top 10 largest files modified
- **Export Support** - Save reports to files

### Usage Examples

```bash
# Basic usage
python3 utils/git_analytics.py "john.doe"

# With date range
python3 utils/git_analytics.py "john.doe" --start-date 2024-01-01 --end-date 2024-12-31

# JSON output
python3 utils/git_analytics.py "john.doe" --format json

# JSON output with date range
python3 utils/git_analytics.py "john.doe" --start-date 2024-01-01 --end-date 2024-12-31 --format json

# Save to file
python3 utils/git_analytics.py "john.doe" --format json --output report.json

# Analyze different repository
python3 utils/git_analytics.py "john.doe" --repo /path/to/repo
```

### Python Dependencies
- `requests` - For API calls (optional)
- Standard library modules: `os`, `sys`, `json`, `subprocess`, `datetime`, `collections`, `argparse`

## ⚡ Quick Stats Script (`quick_git_stats.sh`)

Lightweight script for fast statistics overview.

### Features
- **Fast Execution** - Minimal processing time
- **Essential Stats** - Core metrics only
- **Simple Output** - Clean, readable format
- **No Dependencies** - Uses only standard Unix tools

### Usage
```bash
# From repository root
./utils/quick_git_stats.sh <username>
./utils/quick_git_stats.sh <username> --start-date 2024-01-01
./utils/quick_git_stats.sh <username> --start-date 2024-01-01 --end-date 2024-12-31

# From any subdirectory (scripts auto-detect Git root)
cd utils && ./quick_git_stats.sh <username>
cd shopping_calc_app && ../utils/quick_git_stats.sh <username>
```

### Sample Output
```
Quick Git Stats for: john.doe
==================================
Total Commits: 45
Recent Commits (30 days): 12
Files Modified: 23
Lines Added: 2847
Lines Deleted: 1234
Net Lines: 1613
==================================
```

## 📅 Date Filtering

All scripts support date range filtering to analyze contributions within specific time periods:

### Date Format
- **Format**: `YYYY-MM-DD` (e.g., `2024-01-01`)
- **Start Date**: `--start-date` - Filter commits from this date (inclusive)
- **End Date**: `--end-date` - Filter commits until this date (inclusive)

### Examples
```bash
# Analyze commits from January 1, 2024 onwards
./utils/quick_git_stats.sh "username" --start-date 2024-01-01

# Analyze commits in 2024 only
./utils/quick_git_stats.sh "username" --start-date 2024-01-01 --end-date 2024-12-31

# Analyze commits until December 31, 2023
./utils/git_analytics.sh "username" --end-date 2023-12-31

# Python with date range and JSON output
python3 utils/git_analytics.py "username" --start-date 2024-01-01 --end-date 2024-12-31 --format json
```

### Benefits
- **Time-based Analysis**: Focus on specific periods (quarters, years, sprints)
- **Performance**: Faster processing for large repositories
- **Trend Analysis**: Compare activity across different time periods
- **Project Phases**: Analyze contributions during specific project phases
- **Flexible Execution**: Scripts automatically detect and navigate to Git repository root

## 📊 Comparison Table

| Feature | Quick Stats | Full Analytics | Python Analytics |
|---------|-------------|----------------|------------------|
| Speed | ⚡ Fast | 🐌 Medium | 🐌 Medium |
| Output Format | Text | Text | Text/JSON |
| PR Counting | ❌ No | ✅ Yes | ✅ Yes |
| File Analysis | ❌ No | ✅ Yes | ✅ Yes |
| Dependencies | Minimal | Medium | Python + libs |
| Export Support | ❌ No | ❌ No | ✅ Yes |
| Customization | ❌ No | ✅ Yes | ✅ Yes |

## 🎯 Use Cases

### Quick Stats - When to Use
- **Daily Check-ins** - Quick overview of your contributions
- **Team Standups** - Fast team member statistics
- **CI/CD Integration** - Automated reporting in pipelines

### Full Analytics - When to Use
- **Detailed Reports** - Comprehensive analysis
- **Project Reviews** - Full contribution assessment
- **Documentation** - Complete user activity reports

### Python Analytics - When to Use
- **Data Processing** - Further analysis with other tools
- **API Integration** - Programmatic access to statistics
- **Custom Reports** - Tailored analytics for specific needs



This script is part of the ShoppingCalc project and follows the same license terms. 