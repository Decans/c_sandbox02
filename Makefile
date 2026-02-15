DOCKER = docker compose run --rm build

.PHONY: build run test clean debug debug-stop

build:
	$(DOCKER) make -f /opt/Makefile.build build

run:
	$(DOCKER) make -f /opt/Makefile.build run

test:
	$(DOCKER) make -f /opt/Makefile.build test

clean:
	$(DOCKER) make -f /opt/Makefile.build clean

debug:
	$(DOCKER) make -f /opt/Makefile.build build
	docker compose up -d debug

debug-stop:
	docker compose stop debug
	docker compose rm -f debug
