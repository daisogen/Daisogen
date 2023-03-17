IMG := Daisogen.iso
IMGPATH := img
SHELL := /bin/bash
BOOT_DIR := $(IMGPATH)/boot

MAKEFLAGS += -s

LIMINE_PATH := limine
_LIMINE_FILES := limine-cd.bin limine.sys
LIMINE_FILES := $(_LIMINE_FILES:%=$(LIMINE_PATH)/%)

ifdef RELEASE
CARGO_FLAGS := --release
CARGO_TARGET := release
else
CARGO_TARGET := debug
endif

.PHONY: all run release debug $(IMG) clean

all: $(IMG)
run: all
	qemu-system-x86_64 -cdrom $(IMG) -cpu IvyBridge -machine pc -m 128M
release:
	# We do a little trolling; this is way simpler
	RELEASE=1 $(MAKE) all
debug: all
	gdb -x debug.gdb

pretty = "\e[34m\e[1m--- "$(1)" ---\e[0m"
$(IMG): limine/limine-deploy
	echo -e $(call pretty,PROJECTS)
	$(MAKE) std --no-print-directory
	#$(MAKE) _projects -j`nproc` --no-print-directory
	$(MAKE) _projects --no-print-directory

	echo -e $(call pretty,$(IMG))
	cp -v limine.cfg $(LIMINE_FILES) $(BOOT_DIR)/
	xorriso -as mkisofs -b boot/limine-cd.bin -no-emul-boot \
		-boot-load-size 4 -boot-info-table \
		--protective-msdos-label -o $@ $(IMGPATH) &> /dev/null
	limine/limine-deploy $(IMG)

	echo -e "\n\e[34m\e[1mThank you for using Daisōgen\e[0m"

limine/limine-deploy: limine/limine-deploy.c
	$(MAKE) -C limine/


# Compute $(PROJECTS) and add "kernel" to it
PROJECTS := $(shell ./.expand.sh)
ifeq ($(PROJECTS),error)
    $(error "No projects.txt file")
endif
-include .expansion.mk

.PHONY: _projects
_projects: $(PROJECTS) | std
$(PROJECTS): | $(BOOT_DIR)
	mkdir -p projects
	test -d projects/$@ || git clone $(repo_$@) projects/$@
	cd projects/$@ && cargo build $(CARGO_FLAGS)
	cp -av projects/$@/target/x86_64-daisogen/$(CARGO_TARGET)/$@ $(BOOT_DIR)/

.PHONY: std
std:
	mkdir -p projects
	test -d projects/std || git clone $(repo_std) projects/std
	# That's it, no building

$(BOOT_DIR):
	mkdir -p $@

clean:
	echo '🧹🧹🧹'
	$(foreach x, $(PROJECTS), cd _projects/$(x) && cargo clean && cd ../..;)
	rm -rfv $(IMG) $(IMGPATH)
	rm -f .expansion.mk limine.cfg

mrproper:
	echo '👨🏻‍🦲🧹'
	rm -rfv ./projects
	rm -rfv $(IMG) $(IMGPATH)
	rm -f .expansion.mk limine.cfg
