# local-code-search

Local deployment of [Zoekt](https://github.com/sourcegraph/zoekt), a fast trigram-based code search engine, running on k3d to facilitate fast cross-repository code search.

## Prerequisites

- [k3d](https://k3d.io/) - Lightweight Kubernetes in Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [Docker](https://www.docker.com/) - Container runtime

## Quick Start

```bash
# 1. Configure your repositories directory (optional but recommended)
cp .env.example .env
# Edit .env and set HOST_REPOS to your projects directory

# 2. Create k3d cluster with host directory mounts
make cluster-up

# 3. Deploy Zoekt web server
make deploy

# 4. If not using .env, clone repositories into the repos/ directory
# cd repos/
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
