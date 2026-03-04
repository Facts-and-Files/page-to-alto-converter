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

test: smoke-test endpoint-test

smoke-test: serve
	@docker exec -it "${IMAGE_NAME}" bash -lc "/var/www/tests/test-page-to-alto.sh"
	@echo

endpoint-test: serve
	@SAMPLE="${PWD}/tests/page-2013-sample.xml"; \
	RESP=$$(curl -sS -w "\n%{http_code}" \
		-H "Authorization: Bearer $(UPLOAD_KEY)" \
		-F "file=@$$SAMPLE;type=application/xml" \
		"http://localhost:8000/index.php"); \
	BODY=$$(echo "$$RESP" | sed '$$d'); \
	CODE=$$(echo "$$RESP" | tail -n1); \
	echo "HTTP status: $$CODE"; \
	if [ "$$CODE" -ne 200 ]; then \
		echo "Non-200 response from API"; \
		echo "$$BODY"; \
		exit 1; \
	fi; \
	echo "$$BODY" | grep -q "http://www.loc.gov/standards/alto" || { \
		echo "Response does not look like ALTO XML"; \
		echo "$$BODY" | head -n 40; \
		exit 1; \
	}; \
	echo "OK: HTTP POST endpoint returned ALTO XML."

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
	@echo "  $$ make endpoint-test"
	@echo "  Run HTTP endpoint test"
	@echo ""
	@echo "  $$ make smoke-test"
	@echo "  Run python smoke test"
	@echo ""
