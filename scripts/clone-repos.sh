#!/usr/bin/env bash

set -euo pipefail

GITLAB_URL="${GITLAB_URL:-https://gitlab.com}"
GITLAB_TOKEN="${GITLAB_TOKEN:-}"
GITLAB_GROUP="${GITLAB_GROUP:-}"
GITLAB_CLONE_TYPE="${GITLAB_CLONE_TYPE:-group}"
GHORG_CLONE_OPTS="${GHORG_CLONE_OPTS:---preserve-dir}"

validate_requirements() {
    if ! command -v ghorg &> /dev/null; then
        echo "Error: ghorg is not installed. Install it from https://github.com/gabrie30/ghorg"
        exit 1
    fi

    if [[ -z "$GITLAB_URL" ]]; then
        echo "Error: GITLAB_URL environment variable is not set"
        echo "Example: export GITLAB_URL=https://gitlab.com"
        exit 1
    fi

    if [[ -z "$GITLAB_TOKEN" ]]; then
        echo "Error: GITLAB_TOKEN environment variable is not set"
        echo "Create a personal access token with 'read_api' scope"
        exit 1
    fi

    if [[ -z "$GITLAB_GROUP" ]]; then
        echo "Error: GITLAB_GROUP environment variable is not set"
        echo "For groups: export GITLAB_GROUP='mygroup mygroup2'"
        echo "For users: export GITLAB_GROUP='username' and GITLAB_CLONE_TYPE='user'"
        echo "For all users: export GITLAB_GROUP='all-users' and GITLAB_CLONE_TYPE='user'"
        exit 1
    fi

    if [[ -z "${HOST_REPOS:-}" ]]; then
        echo "Error: HOST_REPOS environment variable is not set"
        exit 1
    fi
}

clone_target() {
    local target="$1"

    cd "$HOST_REPOS"

    ghorg clone "$target" \
        --scm=gitlab \
        --clone-type="$GITLAB_CLONE_TYPE" \
        --base-url="$GITLAB_URL" \
        --token="$GITLAB_TOKEN" \
        --path="$HOST_REPOS" \
        "$GHORG_CLONE_OPTS"
}

main() {
    validate_requirements

    for target in $GITLAB_GROUP; do
        clone_target "$target"
    done

    echo ""
    echo "You can now run 'make reindex' to index the repositories"
}

main "$@"
