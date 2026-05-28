# Container Engine Toggle (Configured explicitly for Podman execution)
DOCKER = podman

# Configuration Variables
IMAGE_NAME = micropython-st7789-builder
OUTPUT_DIR = $(shell pwd)/output_binaries
BOARD = ESP32_GENERIC_S3

# Persistent Named Volumes to cache downloads directly inside Podman storage
MPY_VOLUME = micropython_src_cache
ST7789_VOLUME = st7789_driver_cache

.PHONY: all container firmware clean prune

all: container firmware

## container : Build the compilation environment snapshot image
container:
	@echo "=================================================="
	@echo " Building Environment via $(DOCKER)..."
	@echo "=================================================="
	$(DOCKER) build -t $(IMAGE_NAME) .

## firmware  : Compile firmware at full native speed using Podman volumes
firmware:
	@echo "=================================================="
	@echo " Compiling MicroPython v1.28 + ST7789 (${BOARD})... "
	@echo "=================================================="
	@mkdir -p $(OUTPUT_DIR)
	
	# Create persistent volumes if they do not exist
	$(DOCKER) volume create $(MPY_VOLUME) >/dev/null 2>&1 || true
	$(DOCKER) volume create $(ST7789_VOLUME) >/dev/null 2>&1 || true
	
	# Execute build using fast native volumes instead of slow bind-mounts
	$(DOCKER) run --rm \
		-v "$(OUTPUT_DIR):/builds/output:z" \
		-v "$(MPY_VOLUME):/builds/src-micropython:z" \
		-v "$(ST7789_VOLUME):/builds/src-st7789:z" \
		-e BOARD=$(BOARD) \
		$(IMAGE_NAME)
	
	@echo "--------------------------------------------------"
	@echo "SUCCESS: Check '$(OUTPUT_DIR)' for binaries."
	@echo "--------------------------------------------------"

## clean     : Remove locally generated output binaries
clean:
	@echo "Cleaning local build outputs..."
	rm -rf $(OUTPUT_DIR)

## prune     : Wipe out cached persistent volumes to force a fresh download
prune: clean
	@echo "Wiping Podman internal source cache volumes..."
	$(DOCKER) volume rm -f $(MPY_VOLUME) $(ST7789_VOLUME)

