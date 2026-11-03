# Repository Setup and Contribution Guide

## 1. Project Purpose

The `DE_Project_2026` repository is the team's working repository for the Data Engineering project based on the faculty-provided WhatsApp Messaging Database project.

It provides a shared place where team members can maintain project documentation, code, and checkpoint-related work. The repository helps team members collaborate and keep their contributions organized.

## 2. Clone the Team Repository

To get a local copy of the team's repository, open your terminal and run:

```bash
git clone https://github.com/anshg25067-creator/DE_Project_2026.git
```

Move into the project directory:

```bash
cd DE_Project_2026
```

This creates a local copy of the repository on your computer.

## 3. Check Git Remotes

To view the remote repositories connected to your local project, run:

```bash
git remote -v
```

The output displays the remote repository URLs used for fetching and pushing changes.

By default, `origin` is the name Git gives to the remote repository when it is cloned. In this project, `origin` refers to the team's GitHub repository.

## 4. Checkpoint Files and the Main Branch

Team members must commit their required checkpoint files to the repository's default branch.

If `main` is still the default branch, checkpoint-related contributions should be pushed to `main` according to the team's workflow.

Before making changes, check the current default branch and follow any updated instructions from the team lead.

## 5. Basic Git Contribution Workflow

Follow these commands to synchronize your work and upload your changes.

### Step 1: Get the Latest Changes

```bash
git pull origin main
```

This downloads and integrates the latest changes from the remote `main` branch.

### Step 2: Stage Your Changes

```bash
git add .
```

This stages your modified and new files for the next commit. Check `git status` first to ensure you are not staging unwanted files.

### Step 3: Commit Your Changes

```bash
git commit -m "Describe your changes"
```

A commit saves a snapshot of your staged changes with a descriptive message.

### Step 4: Push Your Changes

```bash
git push origin main
```

This uploads your committed changes to the remote `main` branch.

If a push is rejected because another teammate has pushed changes, synchronize first:

```bash
git pull --rebase origin main
```

Resolve any conflicts carefully. If you are unsure how to resolve a conflict, stop and contact the team lead. Never use `git push --force`.

## 6. Local Datasets and .gitignore

The `seed_data/` and `large_data/` directories contain local datasets used during project development.

These datasets are excluded through the repository's `.gitignore` configuration to avoid unnecessarily uploading local or large data files to GitHub.

Team members should check `.gitignore` before adding files and should not force-add excluded datasets unless the team lead specifically instructs them to do so.

## 7. GitHub Accounts and Genuine Contributions

Each team member must use their own GitHub account when contributing to the project.

Configure your Git identity for this repository using:

```bash
git config user.name "Your Name"
git config user.email "YOUR_VERIFIED_GITHUB_EMAIL"
```

Use an email address verified with your GitHub account so your commits can be correctly associated with your profile.

Every member should make genuine commits for their assigned work. Do not use another member's GitHub credentials or make commits that misrepresent who completed the work.

## 8. Final Checklist

Before pushing your contribution, check:

- [ ] The correct repository is open.
- [ ] The latest changes have been pulled.
- [ ] Your assigned files are updated.
- [ ] Unwanted files and local datasets are not staged.
- [ ] Your commit message clearly describes your work.
- [ ] Your changes are pushed to the correct default branch.

Following this workflow helps the team maintain a consistent repository and collaborate safely.