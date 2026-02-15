CC = clang
CFLAGS = -Wall -Wextra -Werror -std=c17 -g -Isrc
DOCKER = docker compose run --rm build

SRC_DIR = src
BUILD_DIR = build
TEST_DIR = test
UNITY_DIR = unity/src

SRCS = $(wildcard $(SRC_DIR)/*.c)
OBJS = $(SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)
TARGET = $(BUILD_DIR)/main

TEST_SRCS = $(wildcard $(TEST_DIR)/*.c)
LIB_SRCS = $(filter-out $(SRC_DIR)/main.c, $(SRCS))
TEST_TARGET = $(BUILD_DIR)/test_runner

.PHONY: build run test clean _build _run _test _clean

# Host-facing targets (invoke Docker)
build:
	$(DOCKER) make _build

run:
	$(DOCKER) make _run

test:
	$(DOCKER) make _test

clean:
	$(DOCKER) make _clean

# Container-internal targets
_build: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

_run: _build
	./$(TARGET)

_test: $(TEST_TARGET)
	./$(TEST_TARGET)

$(TEST_TARGET): $(TEST_SRCS) $(LIB_SRCS) $(UNITY_DIR)/unity.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -I$(UNITY_DIR) -o $@ $^

_clean:
	rm -rf $(BUILD_DIR)
