DOCKER = docker compose run --rm build

.PHONY: build run test clean

build:
	$(DOCKER) make -f /opt/Makefile.build build

run:
	$(DOCKER) make -f /opt/Makefile.build run

test:
	$(DOCKER) make -f /opt/Makefile.build test

clean:
	$(DOCKER) make -f /opt/Makefile.build clean
