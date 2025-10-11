SHELL := /bin/bash

-include .env
export

K3D_CLUSTER ?= zoekt
K8S_DIR     ?= k8s
NS         ?= zoekt
HOSTPORT   ?= 6070

HOST_INDEX ?= $(CURDIR)/index
HOST_REPOS ?= $(CURDIR)/repos

define _K3D_NODE
$(shell docker ps --format '{{.Names}}' | grep '^k3d-$(K3D_CLUSTER)-server-0$$' || true)
endef

.PHONY: help cluster-up cluster-down deploy reindex cron \
        logs-web logs-index logs-cron status doctor

help:
	@echo "Targets:"
	@echo "  cluster-up       Create k3d cluster $(K3D_CLUSTER)"
	@echo "  cluster-down     Delete k3d cluster $(K3D_CLUSTER)"
	@echo "  deploy           Apply NS/deploy/svc and wait for UI"
	@echo "  reindex          Run one-shot indexing Job (incremental)"
	@echo "  cron             Apply hourly CronJob"
	@echo "  logs-web         Tail zoekt-web logs"
	@echo "  logs-index       Tail last index Job logs"
	@echo "  logs-cron        Tail last cronjob run logs"
	@echo "  status           Show pods/svcs/jobs + recent events"
	@echo "  doctor           Check mounts/ports"

cluster-up:
	@[ -d "$(HOST_INDEX)" ] || mkdir -p "$(HOST_INDEX)"
	@[ -d "$(HOST_REPOS)" ] || mkdir -p "$(HOST_REPOS)"
	k3d cluster create $(K3D_CLUSTER) \
	  -v $(HOST_INDEX):/index@all \
	  -v $(HOST_REPOS):/repos@all \
	  --k3s-arg '--disable=traefik@server:0' \
	  --port "$(HOSTPORT):$(HOSTPORT)@loadbalancer"

cluster-down:
	k3d cluster delete $(K3D_CLUSTER)

deploy:
	kubectl apply -f $(K8S_DIR)/00-namespace.yaml
	kubectl apply -f $(K8S_DIR)/10-web-deployment.yaml
	kubectl apply -f $(K8S_DIR)/20-web-service.yaml
	@echo "Waiting for zoekt-web rollout..."
	kubectl -n $(NS) rollout status deploy/zoekt-web --timeout=180s || \
	  (echo "⚠️  Rollout not ready. Try 'make doctor'."; exit 1)
	@echo "UI should be reachable at http://localhost:$(HOSTPORT)"

reindex:
	kubectl -n $(NS) delete job/zoekt-index --ignore-not-found
	kubectl apply -f $(K8S_DIR)/30-index-job.yaml
	kubectl -n $(NS) wait --for=condition=complete job/zoekt-index --timeout=1h
	- kubectl -n $(NS) logs job/zoekt-index --tail=200
	kubectl -n $(NS) delete job/zoekt-index --ignore-not-found

cron:
	kubectl apply -f $(K8S_DIR)/40-index-cronjob.yaml

logs-web:
	kubectl -n $(NS) logs deploy/zoekt-web -f --all-containers=true

logs-index:
	- kubectl -n $(NS) logs job/zoekt-index -f

logs-cron:
	- kubectl -n $(NS) logs $$(kubectl -n $(NS) get jobs --sort-by=.metadata.creationTimestamp -o name | grep zoekt-index-hourly | tail -1) --tail=200

status:
	kubectl -n $(NS) get pods,svc,job,cronjob -o wide
	@echo "---- Recent events ----"
	- kubectl -n $(NS) get events --sort-by=.lastTimestamp | tail -50

doctor:
	@echo "🔎 Doctor checks…"
	@echo "• Web pod status:"
	- kubectl -n $(NS) get pod -l app=zoekt-web -o wide
	@echo "• Deployment events (image pull, hostPath, permissions):"
	- kubectl -n $(NS) describe deploy/zoekt-web | sed -n '/Events/,$$p'
	@echo "• Node mounts exist inside k3d node?"
	@node='$(_K3D_NODE)'; \
	if [[ -n "$$node" ]]; then \
	  docker exec $$node sh -lc 'ls -ld /index /repos || true'; \
	else \
	  echo "Could not find node container k3d-$(K3D_CLUSTER)-server-0"; \
	fi
	@echo "• Service reachable?"
	- kubectl -n $(NS) get svc zoekt-web -o wide
