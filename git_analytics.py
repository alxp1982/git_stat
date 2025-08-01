#!/usr/bin/env python3
"""
Git Analytics Script (Python Version)
Advanced Git repository analytics for user contributions
"""

import os
import sys
import json
import subprocess
import argparse
from datetime import datetime, timedelta
from collections import defaultdict, Counter
import requests
from typing import Dict, List, Tuple, Optional


class GitAnalytics:
    def __init__(self, repo_path: str = ".", start_date: str = None, end_date: str = None):
        self.repo_path = repo_path
        self.username = None
        self.start_date = start_date
        self.end_date = end_date
        
    def _build_date_filter(self) -> List[str]:
        """Build date filter arguments for git commands"""
        date_filter = []
        if self.start_date:
            date_filter.extend(['--since', self.start_date])
        if self.end_date:
            date_filter.extend(['--until', self.end_date])
        return date_filter
        
    def run_git_command(self, command: List[str]) -> str:
        """Run a git command and return the output"""
        try:
            result = subprocess.run(
                ['git'] + command,
                cwd=self.repo_path,
                capture_output=True,
                text=True,
                check=True
            )
            return result.stdout.strip()
        except subprocess.CalledProcessError as e:
            print(f"Git command failed: {' '.join(command)}")
            print(f"Error: {e.stderr}")
            return ""
    
    def validate_repo(self) -> bool:
        """Validate that we're in a Git repository and navigate to repo root if needed"""
        try:
            # First try current directory
            self.run_git_command(['rev-parse', '--git-dir'])
            return True
        except subprocess.CalledProcessError:
            # Try to find git repository in parent directories
            current_dir = os.path.abspath(self.repo_path)
            while current_dir != os.path.dirname(current_dir):  # Stop at root
                if os.path.isdir(os.path.join(current_dir, '.git')):
                    print(f"Warning: Navigating to Git repository root: {current_dir}")
                    self.repo_path = current_dir
                    return True
                current_dir = os.path.dirname(current_dir)
            return False
    
    def check_user_exists(self, username: str) -> bool:
        """Check if user has commits in the repository"""
        command = ['log', '--all', '--author', username, '--oneline', '-1']
        command.extend(self._build_date_filter())
        output = self.run_git_command(command)
        return bool(output)
    
    def get_commit_stats(self, username: str) -> Dict:
        """Get comprehensive commit statistics"""
        stats = {
            'total_commits': 0,
            'unique_commits': 0,
            'recent_commits': 0,
            'first_commit': None,
            'last_commit': None,
            'commits_by_branch': {},
            'commits_by_year': {},
            'commits_by_day': {},
            'commits_by_month': {}
        }
        
        date_filter = self._build_date_filter()
        
        # Total commits
        command = ['log', '--all', '--author', username, '--oneline']
        command.extend(date_filter)
        output = self.run_git_command(command)
        stats['total_commits'] = len(output.split('\n')) if output else 0
        
        # Unique commits
        command = ['log', '--all', '--author', username, '--pretty=format:%H']
        command.extend(date_filter)
        output = self.run_git_command(command)
        unique_hashes = set(output.split('\n')) if output else set()
        stats['unique_commits'] = len(unique_hashes)
        
        # Recent commits (30 days) - relative to filtered range
        command = ['log', '--all', '--author', username, '--since=30 days ago', '--oneline']
        command.extend(date_filter)
        output = self.run_git_command(command)
        stats['recent_commits'] = len(output.split('\n')) if output else 0
        
        # First and last commit dates
        command = ['log', '--all', '--author', username, '--pretty=format:%ad', '--date=short']
        command.extend(date_filter)
        output = self.run_git_command(command)
        if output:
            dates = output.split('\n')
            stats['first_commit'] = dates[-1] if dates else None
            stats['last_commit'] = dates[0] if dates else None
        
        # Commits by year
        command = ['log', '--all', '--author', username, '--pretty=format:%ad', '--date=short']
        command.extend(date_filter)
        output = self.run_git_command(command)
        if output:
            years = [line.split('-')[0] for line in output.split('\n') if line and line != '0000']
            year_counts = Counter(years)
            stats['commits_by_year'] = dict(year_counts.most_common())
        
        # Commits by day of week
        command = ['log', '--all', '--author', username, '--pretty=format:%aD']
        command.extend(date_filter)
        output = self.run_git_command(command)
        if output:
            try:
                days = []
                for line in output.split('\n'):
                    if line:
                        try:
                            date_obj = datetime.strptime(line, '%a, %d %b %Y %H:%M:%S %z')
                            days.append(date_obj.strftime('%A'))
                        except ValueError:
                            continue
                day_counts = Counter(days)
                stats['commits_by_day'] = dict(day_counts.most_common())
            except Exception as e:
                print(f"Warning: Could not parse day statistics: {e}")
        
        # Commits by month
        command = ['log', '--all', '--author', username, '--pretty=format:%ad', '--date=short']
        command.extend(date_filter)
        output = self.run_git_command(command)
        if output:
            months = []
            for line in output.split('\n'):
                if line and len(line.split('-')) >= 2:
                    try:
                        year, month = line.split('-')[:2]
                        months.append(f"{year}-{month}")
                    except (ValueError, IndexError):
                        continue
            month_counts = Counter(months)
            stats['commits_by_month'] = dict(month_counts.most_common())
        
        # Commits by branch
        try:
            branches_output = self.run_git_command(['branch', '-r'])
            if branches_output:
                for branch in branches_output.split('\n'):
                    if branch.strip():
                        branch_name = branch.strip().replace('origin/', '')
                        command = ['log', '--author', username, branch.strip(), '--oneline']
                        command.extend(date_filter)
                        output = self.run_git_command(command)
                        commit_count = len(output.split('\n')) if output else 0
                        if commit_count > 0:
                            stats['commits_by_branch'][branch_name] = commit_count
        except Exception as e:
            print(f"Warning: Could not get branch statistics: {e}")
        
        return stats
    
    def get_lines_of_code(self, username: str) -> Dict:
        """Get lines of code statistics"""
        stats = {
            'files_modified': 0,
            'total_loc': 0,
            'lines_added': 0,
            'lines_deleted': 0,
            'net_lines': 0,
            'files_by_extension': {},
            'largest_files': []
        }
        
        date_filter = self._build_date_filter()
        
        # Get all files modified by user with date filter
        command = ['log', '--all', '--author', username, '--name-only', '--pretty=format:']
        command.extend(date_filter)
        output = self.run_git_command(command)
        files = set(output.split('\n')) if output else set()
        files = {f for f in files if f.strip()}
        stats['files_modified'] = len(files)
        
        # Count lines by extension
        ext_counts = defaultdict(int)
        file_sizes = []
        
        for file_path in files:
            if os.path.isfile(file_path):
                # Count lines in current file
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        lines = len(f.readlines())
                        stats['total_loc'] += lines
                        file_sizes.append((file_path, lines))
                        
                        # Count by extension
                        ext = os.path.splitext(file_path)[1]
                        ext_counts[ext] += lines
                except Exception:
                    continue
        
        stats['files_by_extension'] = dict(ext_counts)
        stats['largest_files'] = sorted(file_sizes, key=lambda x: x[1], reverse=True)[:10]
        
        # Count additions and deletions with date filter
        command = ['log', '--all', '--author', username, '--pretty=tformat:', '--numstat']
        command.extend(date_filter)
        output = self.run_git_command(command)
        
        total_additions = 0
        total_deletions = 0
        
        for line in output.split('\n'):
            if line.strip():
                parts = line.split('\t')
                if len(parts) >= 2:
                    try:
                        additions = int(parts[0]) if parts[0] != '-' else 0
                        deletions = int(parts[1]) if parts[1] != '-' else 0
                        total_additions += additions
                        total_deletions += deletions
                    except ValueError:
                        continue
        
        stats['lines_added'] = total_additions
        stats['lines_deleted'] = total_deletions
        stats['net_lines'] = total_additions - total_deletions
        
        return stats
    
    def get_pull_requests(self, username: str) -> Dict:
        """Get pull request statistics"""
        stats = {
            'pull_requests': 0,
            'source': 'unknown'
        }
        
        # Try GitHub CLI
        try:
            # Check if GitHub CLI is authenticated
            auth_check = subprocess.run(
                ['gh', 'auth', 'status'],
                capture_output=True,
                text=True
            )
            if auth_check.returncode == 0:
                result = subprocess.run(
                    ['gh', 'pr', 'list', '--author', username, '--json', 'number'],
                    capture_output=True,
                    text=True,
                    check=True
                )
                data = json.loads(result.stdout)
                stats['pull_requests'] = len(data)
                stats['source'] = 'github_cli'
                return stats
            else:
                print("GitHub CLI not authenticated. Run 'gh auth login' to authenticate.")
        except (subprocess.CalledProcessError, json.JSONDecodeError, FileNotFoundError):
            pass
        
        # Try GitLab CLI
        try:
            result = subprocess.run(
                ['glab', 'mr', 'list', '--author', username, '--json', 'id'],
                capture_output=True,
                text=True,
                check=True
            )
            data = json.loads(result.stdout)
            stats['pull_requests'] = len(data)
            stats['source'] = 'gitlab_cli'
            return stats
        except (subprocess.CalledProcessError, json.JSONDecodeError, FileNotFoundError):
            pass
        
        # Try GitHub API with authentication
        try:
            remote_url = self.run_git_command(['config', '--get', 'remote.origin.url'])
            if 'github.com' in remote_url:
                # Extract repo name from URL
                repo_name = remote_url.split('github.com/')[-1].replace('.git', '')
                url = f"https://api.github.com/search/issues?q=author:{username}+repo:{repo_name}+is:pr"
                
                # Add authentication headers if token is available
                headers = {}
                github_token = os.environ.get('GITHUB_TOKEN')
                if github_token:
                    headers['Authorization'] = f'token {github_token}'
                
                response = requests.get(url, headers=headers, timeout=10)
                if response.status_code == 200:
                    data = response.json()
                    stats['pull_requests'] = data.get('total_count', 0)
                    stats['source'] = 'github_api'
                    return stats
                elif response.status_code == 401:
                    print("GitHub API authentication failed. Set GITHUB_TOKEN environment variable.")
                elif response.status_code == 403:
                    print("GitHub API rate limit exceeded or insufficient permissions.")
        except Exception as e:
            print(f"GitHub API error: {e}")
        
        return stats
    
    def calculate_activity_score(self, stats: Dict) -> int:
        """Calculate activity score based on commits and recent activity"""
        total_commits = stats.get('total_commits', 0)
        recent_commits = stats.get('recent_commits', 0)
        return total_commits * 10 + recent_commits * 50
    
    def generate_report(self, username: str, output_format: str = 'text') -> str:
        """Generate comprehensive analytics report"""
        if not self.validate_repo():
            return "Error: Not a Git repository"
        
        if not self.check_user_exists(username):
            return f"Error: No commits found for user '{username}'"
        
        # Gather all statistics
        commit_stats = self.get_commit_stats(username)
        loc_stats = self.get_lines_of_code(username)
        pr_stats = self.get_pull_requests(username)
        
        # Calculate activity score
        activity_score = self.calculate_activity_score(commit_stats)
        
        # Generate report
        if output_format == 'json':
            return self._generate_json_report(
                username, commit_stats, loc_stats, pr_stats, activity_score
            )
        else:
            return self._generate_text_report(
                username, commit_stats, loc_stats, pr_stats, activity_score
            )
    
    def _generate_text_report(self, username: str, commit_stats: Dict, 
                            loc_stats: Dict, pr_stats: Dict, activity_score: int) -> str:
        """Generate text report"""
        report = []
        report.append("=" * 50)
        report.append("Git Analytics Report")
        report.append("=" * 50)
        report.append(f"User: {username}")
        report.append(f"Repository: {os.path.basename(os.path.abspath(self.repo_path))}")
        report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        # Show date filter if applied
        if self.start_date or self.end_date:
            date_range = []
            if self.start_date:
                date_range.append(f"from {self.start_date}")
            if self.end_date:
                date_range.append(f"until {self.end_date}")
            report.append(f"Date Range: {' '.join(date_range)}")
        
        report.append("")
        
        # Quick stats
        report.append("📊 Quick Stats:")
        report.append(f"  Total Commits: {commit_stats['total_commits']}")
        report.append(f"  Unique Commits: {commit_stats['unique_commits']}")
        report.append(f"  Recent Activity (30 days): {commit_stats['recent_commits']}")
        report.append(f"  Activity Score: {activity_score}")
        report.append("")
        
        # Pull Requests
        report.append("🔀 Pull Requests:")
        report.append(f"  Count: {pr_stats['pull_requests']}")
        report.append(f"  Source: {pr_stats['source']}")
        report.append("")
        
        # Lines of Code
        report.append("📝 Lines of Code:")
        report.append(f"  Files Modified: {loc_stats['files_modified']}")
        report.append(f"  Total LOC: {loc_stats['total_loc']}")
        report.append(f"  Lines Added: {loc_stats['lines_added']}")
        report.append(f"  Lines Deleted: {loc_stats['lines_deleted']}")
        report.append(f"  Net Lines: {loc_stats['net_lines']}")
        report.append("")
        
        # Top file extensions
        if loc_stats['files_by_extension']:
            report.append("📁 Top File Extensions:")
            sorted_exts = sorted(loc_stats['files_by_extension'].items(), 
                               key=lambda x: x[1], reverse=True)[:5]
            for ext, count in sorted_exts:
                report.append(f"  {ext}: {count} lines")
            report.append("")
        
        # Commit timeline
        if commit_stats['first_commit'] and commit_stats['last_commit']:
            report.append("📅 Timeline:")
            report.append(f"  First Commit: {commit_stats['first_commit']}")
            report.append(f"  Last Commit: {commit_stats['last_commit']}")
            report.append("")
        
        # Commits by year
        if commit_stats['commits_by_year']:
            report.append("📈 Commits by Year:")
            for year, count in sorted(commit_stats['commits_by_year'].items()):
                report.append(f"  {year}: {count} commits")
            report.append("")
        
        # Most active day
        if commit_stats['commits_by_day']:
            most_active_day = max(commit_stats['commits_by_day'].items(), 
                                key=lambda x: x[1])
            report.append("🗓️  Most Active Day:")
            report.append(f"  {most_active_day[0]}: {most_active_day[1]} commits")
            report.append("")
        
        report.append("=" * 50)
        report.append("Report Complete")
        report.append("=" * 50)
        
        return "\n".join(report)
    
    def _generate_json_report(self, username: str, commit_stats: Dict, 
                            loc_stats: Dict, pr_stats: Dict, activity_score: int) -> str:
        """Generate JSON report"""
        report = {
            'user': username,
            'repository': os.path.basename(os.path.abspath(self.repo_path)),
            'generated': datetime.now().isoformat(),
            'activity_score': activity_score,
            'commit_stats': commit_stats,
            'lines_of_code': loc_stats,
            'pull_requests': pr_stats
        }
        
        # Add date filter information if applied
        if self.start_date or self.end_date:
            report['date_filter'] = {
                'start_date': self.start_date,
                'end_date': self.end_date
            }
        
        return json.dumps(report, indent=2)


def main():
    parser = argparse.ArgumentParser(description='Git Analytics Tool')
    parser.add_argument('username', help='Git username to analyze')
    parser.add_argument('--repo', default='.', help='Repository path (default: current directory)')
    parser.add_argument('--start-date', help='Start date filter (YYYY-MM-DD format)')
    parser.add_argument('--end-date', help='End date filter (YYYY-MM-DD format)')
    parser.add_argument('--format', choices=['text', 'json'], default='text', 
                       help='Output format (default: text)')
    parser.add_argument('--output', help='Output file (default: stdout)')
    
    args = parser.parse_args()
    
    analytics = GitAnalytics(args.repo, args.start_date, args.end_date)
    report = analytics.generate_report(args.username, args.format)
    
    if args.output:
        with open(args.output, 'w') as f:
            f.write(report)
        print(f"Report saved to: {args.output}")
    else:
        print(report)


if __name__ == '__main__':
    main() 