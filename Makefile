# Import config
cnf ?= config.env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# Import current timestamp for tagging container inside
# the pipeline
TIMESTAMP_TAG=ts-$(shell date +%Y%m%d-%H%M%S)

SHELL := /bin/bash

# HELP
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

# Reusable Methods
initialize_git_repo = (ssh root@${LOAD_BALANCER_HOST} "cd ${GIT_REPO_PATH} \
		|| ( mkdir -p `dirname ${GIT_REPO_PATH}`\
		&& cd `dirname ${GIT_REPO_PATH}` \
		&& git clone ${GIT_CLONE_URL} ) \
		&& cd ${GIT_REPO_PATH} \
		&& git pull \
		")

ssh_jumpbox_command = (echo "INFO - test connection to $(1)"; \
							   ssh -J root@${LOAD_BALANCER_HOST} root@$(1) $(2))

ansible_deploy = (ssh root@${LOAD_BALANCER_HOST} "apt update && apt install -y ansible")

set_default_ansible_inventory = (ssh root@${LOAD_BALANCER_HOST} "cp ${INI_FILE_PATH}{,.`date +%Y%m%d-%H%M%S`.bak} || echo """INFO - no ${INI_FILE_PATH}""" "; \
	scp ansible_hosts.tmpl root@${LOAD_BALANCER_HOST}:${INI_FILE_PATH};)

ansible_inventory = (ssh root@${LOAD_BALANCER_HOST} "cp ${INI_FILE_PATH}{,.`date +%Y%m%d-%H%M%S`.bak} || echo """INFO - no ${INI_FILE_PATH}""" "; \
	scp ansible_hosts.tmpl root@${LOAD_BALANCER_HOST}:${INI_FILE_PATH}; \
	for host in $(shell echo "${CONTROL_PLANES}" | sed "s/,/ /g"); do \
		ssh root@${LOAD_BALANCER_HOST} "python3 ${GIT_REPO_PATH}/bin/set-ansible-inventory.py controlplanes $$host";\
	done; \
	for host in $(shell echo "${WORKERS}" | sed "s/,/ /g"); do \
		ssh root@${LOAD_BALANCER_HOST} "python3 ${GIT_REPO_PATH}/bin/set-ansible-inventory.py workers $$host";\
	done)

test_grep_default_ansible_inventory = (for host in $(shell echo "${CONTROL_PLANES}" | sed "s/,/ /g"); do \
		echo "INFO - checking $$host"; \
		ssh root@${LOAD_BALANCER_HOST} "grep $$host ${INI_FILE_PATH} || echo """OK - no controlplane host found""" ";\
	done; \
	for host in $(shell echo "${WORKERS}" | sed "s/,/ /g"); do \
		ssh root@${LOAD_BALANCER_HOST} "grep $$host ${INI_FILE_PATH} || echo """OK - no worker host found""" ";\
	done)

grep_ansible_inventory = (for host in $(shell echo "${CONTROL_PLANES}" | sed "s/,/ /g"); do \
		echo "INFO - checking $$host"; \
		ssh root@${LOAD_BALANCER_HOST} "grep $$host ${INI_FILE_PATH}";\
	done; \
	for host in $(shell echo "${WORKERS}" | sed "s/,/ /g"); do \
		ssh root@${LOAD_BALANCER_HOST} "grep $$host ${INI_FILE_PATH}";\
	done)

# TASKS
# tests
test-hosts-connection: ## Test connection to every host
	@echo "TEST connection to hosts"
	for host in $(shell echo "${CONTROL_PLANES}" | sed "s/,/ /g"); do \
		$(call ssh_jumpbox_command,$$host,"echo \"TEST ok: connected to host: \"; hostname"); \
	done
	@echo
	@echo "TEST ok"
	@echo
	for host in $(shell echo "${WORKERS}" | sed "s/,/ /g"); do \
		$(call ssh_jumpbox_command,$$host,"echo \"TEST ok: connected to host: \"; hostname"); \
	done
	@echo
	@echo "TEST ok"
	@echo

test-deploy-git: ## Test the Infrastructure main functionalities
	@echo "TEST git repository"
	@echo "TEST git repository deploy when directory not exists"
	ssh root@${LOAD_BALANCER_HOST} "rm -r `dirname ${GIT_REPO_PATH}`"
	$(call initialize_git_repo)
	@echo
	@echo "TEST ok"
	@echo
	@echo "TEST git repository deploy when git is initialized"
	$(call initialize_git_repo)
	@echo
	@echo "TEST ok"
	@echo

test-deploy-ansible: ## Test the Ansible Deployment
	@echo "INFO - code update"
	$(call initialize_git_repo)
	@echo "TEST ansible deploy"
	@echo "TEST ansible deploy when ansible is not installed"
	ssh root@${LOAD_BALANCER_HOST} "apt remove -y ansible"; \
	$(call ansible_deploy)
	@echo
	@echo "TEST ok"
	@echo
	@echo "TEST ansible deploy when ansible is already installed"
	$(call ansible_deploy)
	@echo
	@echo "TEST ok"
	@echo
	@echo "TEST ansible hosts is default before configure it"
	$(call set_default_ansible_inventory)
	$(call test_grep_default_ansible_inventory)
	@echo
	@echo "TEST ok"
	@echo
	@echo "TEST ansible hosts configuration"
	$(call ansible_inventory)
	$(call grep_ansible_inventory)
	@echo
	@echo "TEST ok"
	@echo

deploy-git: ## Deploy the Git Infra repository into Load Balancer host - idempotent
	@echo "INFO - check connection to LB host"
	ssh root@${LOAD_BALANCER_HOST} hostname
	@echo "INFO - check if git repo is initialized and updated"
	$(call initialize_git_repo)

deploy-ansible: ## Deploy Ansible
	@echo "INFO - code update"
	$(call initialize_git_repo)
	@echo "INFO - deploy Ansible"
	$(call ansible_deploy)
	@echo "INFO - Ansible installed"
	@echo "INFO - creating Ansible Inventory"
	$(call ansible_inventory)
	


test-full-deploy: test-hosts-connection test-deploy-git test-deploy-ansible ## run all tests

deploy-full: deploy-git deploy-ansible ## fully deploy the infra stack

