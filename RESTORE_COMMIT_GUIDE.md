# How to Restore to an Older Commit

## 📋 Recent Commits

Here are the most recent commits you can restore to:

### Latest Commits (Most Recent First)

1. **5a1e4fa** (2025-11-14) - Fix: Web compilation errors - conditional imports for dart:io
2. **71edc62** (2025-11-14) - Fix: Improve build.sh error handling for Vercel deployment
3. **38e5a27** (2025-11-14) - Improve Vercel build script: Better error handling and web support
4. **5e5928a** (2025-11-14) - Fix CORS: Add Vercel frontend origin and set Express req fields for serverless
5. **ac0dcb9** (2025-11-13) - Fix: Add localhost detection for web using conditional imports
6. **ebaf6fd** (2025-11-13) - Fix: Remove dart:html dependency for Android build
7. **dd47e70** (2025-11-13) - Add APK build guide and script
8. **3c77432** (2025-11-13) - Update backend URL to latest deployment: tailor-app-backend-1bfc2dnm3
9. **89c5229** (2025-11-13) - AGGRESSIVE CORS FIX: Ensure headers are set and preserved
10. **cbda2c5** (2025-11-13) - CRITICAL CORS FIX: Handle CORS at serverless function entry point
11. **3d2e4cf** (2025-11-13) - Fix CORS: Add explicit OPTIONS handler before middleware
12. **00ba912** (2025-11-13) - Fix: Optimize MongoDB connection for Vercel serverless functions
13. **38768d8** (2025-11-13) - Fix CORS: Remove credentials when using wildcard origin

---

## 🔄 Restore Options

### Option 1: Hard Reset (⚠️ DESTRUCTIVE - Discards all changes after commit)

```bash
# WARNING: This will PERMANENTLY delete all commits after the specified commit
git reset --hard <commit-hash>

# Example: Restore to commit ac0dcb9
git reset --hard ac0dcb9
```

**⚠️ Warning:** This is irreversible! All commits after the specified commit will be lost.

---

### Option 2: Soft Reset (Keeps changes as uncommitted)

```bash
# This keeps your changes but removes commits
git reset --soft <commit-hash>

# Example: Restore to commit ac0dcb9 but keep changes
git reset --soft ac0dcb9
```

**✅ Safer:** Your changes are preserved as uncommitted files.

---

### Option 3: Create New Branch from Old Commit (✅ SAFEST)

```bash
# Create a new branch from an old commit without affecting current branch
git checkout -b restore-<commit-hash> <commit-hash>

# Example: Create branch from commit ac0dcb9
git checkout -b restore-ac0dcb9 ac0dcb9
```

**✅ Safest:** Your current work is untouched. You can switch between branches.

---

### Option 4: Revert Specific Commits (Keeps history)

```bash
# Revert a specific commit (creates a new commit that undoes changes)
git revert <commit-hash>

# Example: Revert the last commit
git revert HEAD
```

**✅ Safe:** Creates a new commit that undoes the changes, preserving history.

---

## 📊 View Full History

To see all commits:

```bash
# View last 50 commits
git log --oneline -50

# View with dates
git log --pretty=format:"%h | %ad | %s" --date=short -50

# View with graph
git log --oneline --graph --decorate -30
```

---

## 🔍 View What Changed in a Commit

```bash
# See what files changed in a commit
git show <commit-hash> --stat

# See the full diff
git show <commit-hash>

# Example
git show ac0dcb9
```

---

## 💡 Recommended Approach

**For safety, use Option 3 (Create New Branch):**

1. Create a branch from the commit you want:
   ```bash
   git checkout -b restore-ac0dcb9 ac0dcb9
   ```

2. Test if everything works on that branch

3. If you want to make it the main branch:
   ```bash
   git checkout master
   git reset --hard restore-ac0dcb9
   ```

4. Or merge the changes:
   ```bash
   git checkout master
   git merge restore-ac0dcb9
   ```

---

## 🚨 Before Restoring

1. **Backup your current work:**
   ```bash
   git branch backup-before-restore
   ```

2. **Check what you'll lose:**
   ```bash
   git log <commit-hash>..HEAD
   ```

3. **Make sure you're on the right branch:**
   ```bash
   git branch
   ```

---

## 📝 Current Status

- **Current Branch:** master
- **Latest Commit:** 5a1e4fa
- **Remote Status:** Up to date with origin/master

---

## ⚠️ Important Notes

- **Hard reset** will lose all commits after the target commit
- **Always backup** before doing destructive operations
- **Consider creating a branch** first to test the old version
- **You can always go back** to the latest commit using: `git reset --hard origin/master`

