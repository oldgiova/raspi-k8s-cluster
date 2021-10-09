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


# TASKS
# Container build
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
	

deploy-git: ## Deploy the Git Infra repository into Load Balancer host - idempotent
	@echo "INFO - check connection to LB host"
	ssh root@${LOAD_BALANCER_HOST} hostname
	@echo "INFO - check if git repo is initialized and updated"
	$(call initialize_git_repo)


test-full-deploy: test-deploy-git ## run all tests

full-deploy: deploy-git ## fully deploy the infra stack

