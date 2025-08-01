# 🔑 GitHub API Setup Guide

This guide explains how to configure the Git analytics scripts to use the GitHub API for counting Pull Requests.

## 🎯 Why GitHub API Authentication?

The scripts can count Pull Requests in several ways:
1. **GitHub CLI** (recommended) - Most reliable and user-friendly
2. **GitHub API with Personal Access Token** - Good for automation
3. **Manual counting** - Fallback option

## 🚀 Method 1: GitHub CLI (Recommended)

### Installation

**macOS:**
```bash
brew install gh
```

**Ubuntu/Debian:**
```bash
sudo apt install gh
```

**Windows:**
```bash
winget install GitHub.cli
```

### Authentication

```bash
gh auth login
```

Follow the interactive prompts:
1. Choose "GitHub.com"
2. Choose "HTTPS"
3. Choose "Yes" to authenticate Git operations
4. Choose "Login with a web browser"
5. Copy the one-time code and paste it in your browser
6. Authorize the GitHub CLI

### Verification

```bash
gh auth status
```

You should see something like:
```
github.com
  ✓ Logged in to github.com as username (oauth_token)
  ✓ Git operations for github.com configured to use https protocol.
```

## 🔑 Method 2: Personal Access Token (PAT)

### Create a Personal Access Token

1. Go to [GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Give it a descriptive name (e.g., "Git Analytics Scripts")
4. Set expiration (recommend 90 days for security)
5. Select scopes:
   - ✅ `repo` (for private repositories)
   - ✅ `public_repo` (for public repositories)
6. Click "Generate token"
7. **Copy the token immediately** (you won't see it again!)

### Set Environment Variable

**Temporary (current session only):**
```bash
export GITHUB_TOKEN="ghp_your_token_here"
```

**Permanent (add to shell profile):**

For Zsh (`~/.zshrc`):
```bash
echo 'export GITHUB_TOKEN="ghp_your_token_here"' >> ~/.zshrc
source ~/.zshrc
```

For Bash (`~/.bashrc`):
```bash
echo 'export GITHUB_TOKEN="ghp_your_token_here"' >> ~/.bashrc
source ~/.bashrc
```

### Verification

```bash
echo $GITHUB_TOKEN
# Should show your token (first few characters)
```

## 🧪 Testing the Configuration

### Test GitHub CLI
```bash
# Check if authenticated
gh auth status

# Test PR listing
gh pr list --limit 1
```

### Test with Personal Access Token
```bash
# Test API call
curl -H "Authorization: token $GITHUB_TOKEN" \
     "https://api.github.com/user" | jq '.login'
```

### Test the Scripts
```bash
# Test from repository root
./utils/git_analytics.sh "your_username"

# Test from utils directory
cd utils && ./git_analytics.sh "your_username"
```

## 📊 Expected Output

With proper authentication, you should see:
```
Counting Pull Requests...
Using GitHub CLI to count PRs...
Pull Requests: 15
```

Or with API:
```
Counting Pull Requests...
Attempting to count PRs from GitHub API...
Pull Requests: 15
```

## ❌ Troubleshooting

### "GitHub CLI not authenticated"
```bash
gh auth login
```

### "GitHub API authentication failed"
```bash
# Check if token is set
echo $GITHUB_TOKEN

# Set token if missing
export GITHUB_TOKEN="your_token_here"
```

### "GitHub API rate limit exceeded"
- Wait for rate limit to reset (usually 1 hour)
- Use GitHub CLI instead (higher limits)
- Consider using a GitHub App token for higher limits

### "Could not determine PR count"
The script will show helpful instructions:
```
To enable PR counting, you can:
1. Install and authenticate GitHub CLI: brew install gh && gh auth login
2. Set GITHUB_TOKEN environment variable: export GITHUB_TOKEN='your_token'
3. Check manually at: https://github.com/owner/repo/pulls?q=author:username
```

## 🔒 Security Best Practices

1. **Use GitHub CLI** when possible (handles authentication securely)
2. **Set token expiration** (90 days recommended)
3. **Use minimal scopes** (only `repo` and `public_repo`)
4. **Don't commit tokens** to version control
5. **Rotate tokens regularly**

## 🎯 Quick Setup Commands

**For GitHub CLI:**
```bash
brew install gh && gh auth login
```

**For Personal Access Token:**
```bash
# Add to your shell profile
echo 'export GITHUB_TOKEN="your_token_here"' >> ~/.zshrc
source ~/.zshrc
```

## 📝 Manual PR Counting

If all else fails, you can manually count PRs:
1. Go to your repository on GitHub
2. Click "Pull requests"
3. Filter by author: `author:username`
4. Count the results

The script provides a direct link for this:
```
https://github.com/owner/repo/pulls?q=author:username
``` 