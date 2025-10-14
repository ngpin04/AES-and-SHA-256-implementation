# ==== Config ====
APP_AES    := aes_tool
APP_SHA    := sha256_tool

SRC_DIR    := src
INC_DIR    := include
BUILD_DIR  := build
BIN_DIR    := bin

# Toolchain
CXX ?= g++
LD  := $(CXX)

# Mode: Release (default) or Debug (use: make MODE=Debug)
MODE ?= Release

# Common flags
CPPFLAGS := -I$(INC_DIR) -MMD -MP
CXXFLAGS := -std=c++17 -Wall -Wextra -Wpedantic
LDFLAGS  :=

ifeq ($(MODE),Debug)
  CXXFLAGS += -O0 -g
else ifeq ($(MODE),Release)
  CXXFLAGS += -O3 -DNDEBUG
else
  $(error MODE must be Debug or Release)
endif

# ==== Sources ====
# Common sources (optional)
COMMON_SRCS := $(wildcard $(SRC_DIR)/common/*.cpp)

# AES sources (including its main)
AES_SRCS := $(COMMON_SRCS) $(wildcard $(SRC_DIR)/aes/*.cpp)
AES_OBJS := $(patsubst $(SRC_DIR)/%.cpp,$(BUILD_DIR)/%.o,$(AES_SRCS))

# SHA sources (including its main)
SHA_SRCS := $(COMMON_SRCS) $(wildcard $(SRC_DIR)/sha256/*.cpp)
SHA_OBJS := $(patsubst $(SRC_DIR)/%.cpp,$(BUILD_DIR)/%.o,$(SHA_SRCS))

# All objects (for auto-deps)
ALL_OBJS := $(AES_OBJS) $(SHA_OBJS)

# Optional: Precompiled header
PCH_HDR := $(INC_DIR)/pch.hpp
PCH_GCH := $(BUILD_DIR)/pch.hpp.gch
USE_PCH ?= 0
ifeq ($(USE_PCH),1)
  CPPFLAGS += -include $(PCH_HDR)
endif

# ==== Rules ====
.PHONY: all aes sha run-aes run-sha clean rebuild dirs print

all: dirs $(BIN_DIR)/$(APP_AES) $(BIN_DIR)/$(APP_SHA)

aes: $(BIN_DIR)/$(APP_AES)
sha: $(BIN_DIR)/$(APP_SHA)

# Link
$(BIN_DIR)/$(APP_AES): $(AES_OBJS)
	$(LD) $(AES_OBJS) $(LDFLAGS) -o $@
	@echo "Linked $@ ($(MODE))"

$(BIN_DIR)/$(APP_SHA): $(SHA_OBJS)
	$(LD) $(SHA_OBJS) $(LDFLAGS) -o $@
	@echo "Linked $@ ($(MODE))"

# Compile each .cpp -> .o
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp $(if $(filter 1,$(USE_PCH)),$(PCH_GCH))
	@mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

# PCH (optional)
$(PCH_GCH): $(PCH_HDR) | dirs
ifeq ($(USE_PCH),1)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -x c++-header $(PCH_HDR) -o $@
endif

# Auto-deps
-include $(ALL_OBJS:.o=.d)

# Helpers
dirs:
	@mkdir -p $(BUILD_DIR) $(BIN_DIR)

run-aes: aes
	@$(BIN_DIR)/$(APP_AES)

run-sha: sha
	@$(BIN_DIR)/$(APP_SHA)

clean:
	@rm -rf $(BUILD_DIR) $(BIN_DIR)
	@echo "Cleaned."

rebuild: clean all

print:
	@echo "MODE     = $(MODE)"
	@echo "USE_PCH  = $(USE_PCH)"
	@echo "AES_SRCS = $(AES_SRCS)"
	@echo "SHA_SRCS = $(SHA_SRCS)"