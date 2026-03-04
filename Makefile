.PHONY: all help serve stop test

include .env
export $(shell sed 's/=.*//' .env)

PWD := $(shell pwd)
IMAGE_NAME :=page2alto-converter

serve:
	@cd $(PWD) && docker compose up -d
	@echo
	@echo "Webserver running on http://localhost:8000"
	@echo
	@echo "I'm up to no good..."
	@echo

stop:
	@echo
	@echo "Stopping all containers..."
	@cd $(PWD) && docker compose down
	@echo
	@echo "...mischief managed."
	@echo

test: smoke-test transkribus-test page-2019-test

smoke-test: serve
	@echo
	@docker exec -it "${IMAGE_NAME}" bash -lc "/var/www/tests/test-page-to-alto.sh"
	@echo

transkribus-test: serve
	@echo
	@bash -lc "${PWD}/tests/http-page-upload-test.sh ${PWD}/tests/transkribus-page-2013-sample.xml"
	@echo

page-2019-test: serve
	@echo
	@bash -lc "${PWD}/tests/http-page-upload-test.sh ${PWD}/tests/page-2019-sample.xml"
	@echo

help:
	@echo "Manage project"
	@echo ""
	@echo "Usage:"
	@echo "  $$ make [command]"
	@echo ""
	@echo "Commands:"
	@echo ""
	@echo "  $$ make serve"
	@echo "  Starting the servers"
	@echo ""
	@echo "  $$ make stop"
	@echo "  Stopping the servers"
	@echo ""
	@echo "  $$ make test"
	@echo "  Run tests"
	@echo ""
	@echo "  $$ make transkribus-test"
	@echo "  Run HTTP endpoint test on Transkribus flavor PAGE XML"
	@echo ""
	@echo "  $$ make page-2019-test"
	@echo "  Run HTTP endpoint test on PRImA PAGE XML v2019"
	@echo ""
	@echo "  $$ make smoke-test"
	@echo "  Run python smoke test"
	@echo ""
