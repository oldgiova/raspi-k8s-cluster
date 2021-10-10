# Import config
cnf ?= config.env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# Import current timestamp for tagging container inside
# the pipeline
TIMESTAMP_TAG=ts-$(shell date +%Y%m%d-%H%M%S)

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

ansible_deploy = (ssh root@${LOAD_BALANCER_HOST} "apt update && apt install -y ansible"; \
	for host in ${CONTROL_PLANES}; do $(call ssh_jumpbox_command,$$host,"apt update && apt install -y ansible"); done; \
	for host in ${WORKERS}; do $(call ssh_jumpbox_command,$$host,"apt update && apt install -y ansible"); done;)

# TASKS
# tests
test-hosts-connection: ## Test connection to every host
	@echo "TEST connection to hosts"
	for host in ${CONTROL_PLANES}; do \
		$(call ssh_jumpbox_command,$$host,"echo \"TEST ok: connected to host: \"; hostname"); \
	done
	@echo
	@echo "TEST ok"
	@echo
	for host in ${WORKERS}; do \
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
	@echo "TEST ansible deploy"
	@echo "TEST ansible deploy when ansible is not installed"
	ssh root@${LOAD_BALANCER_HOST} "apt remove -y ansible"; \
	for host in ${CONTROL_PLANES}; do \
		$(call ssh_jumpbox_command,$$host,"apt remove -y ansible"); \
	done
	for host in ${WORKERS}; do \
		$(call ssh_jumpbox_command,$$host,"apt remove -y ansible"); \
	done
	$(call ansible_deploy)
	@echo
	@echo "TEST ok"
	@echo
	@echo "TEST ansible deploy when ansible is already installed"
	$(call ansible_deploy)
	@echo
	@echo "TEST ok"
	@echo
	

deploy-git: ## Deploy the Git Infra repository into Load Balancer host - idempotent
	@echo "INFO - check connection to LB host"
	ssh root@${LOAD_BALANCER_HOST} hostname
	@echo "INFO - check if git repo is initialized and updated"
	$(call initialize_git_repo)

deploy-ansible: ## Deploy Ansible
	@echo "INFO - deploy Ansible"
	$(call ansible_deploy)
	@echo "INFO - Ansible installed"


test-full-deploy: test-hosts-connection test-deploy-git test-deploy-ansible ## run all tests

full-deploy: deploy-git deploy-ansible ## fully deploy the infra stack

