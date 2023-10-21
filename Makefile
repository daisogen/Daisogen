IMG := Daisogen.iso
IMGPATH := img
SHELL := /bin/bash
BOOT_DIR := $(IMGPATH)/boot

MAKEFLAGS += -s

LIMINE_PATH := limine
_LIMINE_FILES := limine-cd.bin limine.sys
LIMINE_FILES := $(_LIMINE_FILES:%=$(LIMINE_PATH)/%)

TARGET := x86_64-unknown-daisogen
CARGO := cargo +dev-$(TARGET)
CARGO_FLAGS := --target $(TARGET)

ifdef RELEASE
CARGO_FLAGS += --release
CARGO_TARGET := release
else
CARGO_TARGET := debug
endif

QEMU := qemu-system-x86_64
CPU := IvyBridge
RAM := 128M
NET := -netdev user,id=daisogen0 -device rtl8139,netdev=daisogen0
QEMU_FLAGS := -cdrom $(IMG) -cpu $(CPU) -machine pc -m $(RAM) $(NET) -enable-kvm

.PHONY: all run release debug $(IMG) clean

all: $(IMG)
run: all
	$(QEMU) $(QEMU_FLAGS)
release:
	RELEASE=1 $(MAKE) all
debug: all
	gdb -x debug.gdb

pretty = "\e[34m\e[1m--- "$(1)" ---\e[0m"
$(IMG): limine/limine-deploy
	echo -e $(call pretty,PROJECTS)
	$(MAKE) _projects --no-print-directory

	echo -e $(call pretty,$(IMG))
	cp -v $(LIMINE_FILES) $(BOOT_DIR)/
	xorriso -as mkisofs -b boot/limine-cd.bin -no-emul-boot \
		-boot-load-size 4 -boot-info-table \
		--protective-msdos-label -o $@ $(IMGPATH) &> /dev/null
	limine/limine-deploy $(IMG)

	echo -e "\n\e[34m\e[1mThank you for using Daisōgen\e[0m"

limine/limine-deploy: limine/limine-deploy.c
	$(MAKE) -C limine/


PROJECTS := $(shell ./.expand.sh)
ifeq ($(PROJECTS),error)
    $(error "No projects.txt file")
endif
-include .expansion.mk

.PHONY: _projects
_projects: $(PROJECTS)
$(PROJECTS): | $(BOOT_DIR)
	mkdir -p projects
	test -d projects/$@ || git clone $(repo_$@) projects/$@
	cd projects/$@ && $(CARGO) build $(CARGO_FLAGS) $(flags_$@)
	cp -av projects/$@/target/$(TARGET)/$(CARGO_TARGET)/$@ $(BOOT_DIR)/

$(BOOT_DIR):
	mkdir -p $@

clean:
	echo '🧹🧹🧹'
	$(foreach x, $(PROJECTS), cd projects/$(x) && cargo clean && cd ../..;)
	rm -rfv $(IMG) $(IMGPATH)
	rm -f .expansion.mk limine.cfg

mrproper:
	echo '👨🏻‍🦲🧹'
	rm -rfv ./projects
	rm -rfv $(IMG) $(IMGPATH)
	rm -f .expansion.mk
