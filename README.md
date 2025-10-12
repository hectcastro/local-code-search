# local-code-search

Local deployment of [Zoekt](https://github.com/sourcegraph/zoekt), a fast trigram-based code search engine, running on k3d to facilitate fast cross-repository code search.

## Prerequisites

- [k3d](https://k3d.io/) - Lightweight Kubernetes in Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [Docker](https://www.docker.com/) - Container runtime
- [ghorg](https://github.com/gabrie30/ghorg) - (Optional) For cloning GitLab repositories

## Quick Start

```bash
# 1. Configure your repositories directory (optional but recommended)
cp .env.example .env
# Edit .env and set HOST_REPOS to your projects directory

# 2. Create k3d cluster with host directory mounts
make cluster-up

# 3. Deploy Zoekt web server
make deploy

# 4a. Clone repositories from GitLab (requires ghorg and GitLab config in .env)
make clone-repos

# 4b. Or manually clone repositories into your HOST_REPOS directory
# cd ~/Projects  # or your HOST_REPOS path
# git clone https://github.com/your-org/your-repo.git

# 5. Index the repositories
make reindex

# 6. Access the web UI
open http://localhost:6070
```

## Configuration

### Using .env for local settings

Copy `.env.example` to `.env` and customize for your setup:

```bash
cp .env.example .env
```

Edit `.env` to point to your repositories directory:

```bash
HOST_REPOS=/Users/yourname/Projects
```

The `.env` file is git-ignored and allows you to:
- Configure persistent local settings without modifying the Makefile
- Use different paths on different machines
- Override any Make variable (see `.env.example` for all options)

You can still override settings via command line:
```bash
make cluster-up HOST_REPOS=/different/path
```

### Cloning repositories from GitLab

Install [ghorg](https://github.com/gabrie30/ghorg) and configure GitLab settings in `.env`:

```bash
# For cloning user repositories
GITLAB_URL=https://gitlab.com
GITLAB_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
GITLAB_CLONE_TYPE=user
GITLAB_GROUP=your-username

# For cloning group repositories
GITLAB_CLONE_TYPE=group
GITLAB_GROUP=your-group-name
```

Then run:
```bash
make clone-repos
```

The `--preserve-dir` flag is used by default to maintain GitLab's nested group/subgroup structure and prevent name collisions.

**Examples:**
- Clone personal repos: `GITLAB_CLONE_TYPE=user GITLAB_GROUP=username`
- Clone group repos: `GITLAB_CLONE_TYPE=group GITLAB_GROUP=mygroup`
- Clone multiple: `GITLAB_GROUP="group1 group2"`
- Clone all users: `GITLAB_CLONE_TYPE=user GITLAB_GROUP=all-users` (requires GitLab 13.0.1+)

## Troubleshooting

If deployment fails or the UI is unreachable:

```bash
make doctor
```

This checks:
- Pod status and events
- Host mount visibility inside k3d nodes
- Service configuration
- Image pull status
