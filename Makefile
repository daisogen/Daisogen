IMG := Daisogen.iso
IMGPATH := img
SHELL := /bin/bash
BOOT_DIR := $(IMGPATH)/boot

MAKEFLAGS += -s

LIMINE_PATH := limine
_LIMINE_FILES := limine-cd.bin limine.sys
LIMINE_FILES := $(_LIMINE_FILES:%=$(LIMINE_PATH)/%)

.PHONY: run all $(IMG) clean

all: $(IMG)
run: all
	@qemu-system-x86_64 -cdrom $(IMG) -cpu IvyBridge -machine q35 -m 128M

pretty = "\e[34m\e[1m--- "$(1)" ---\e[0m"
$(IMG): limine/limine-deploy
	@echo -e $(call pretty,PROJECTS)
	@#$(MAKE) programs -j`nproc` --no-print-directory
	@$(MAKE) programs --no-print-directory

	@echo -e $(call pretty,$(IMG))
	@cp -v limine.cfg $(LIMINE_FILES) $(BOOT_DIR)/
	@xorriso -as mkisofs -b boot/limine-cd.bin -no-emul-boot \
		-boot-load-size 4 -boot-info-table \
		--protective-msdos-label -o $@ $(IMGPATH) &> /dev/null
	@limine/limine-deploy $(IMG)

	@echo -e "\n\e[34m\e[1mThank you for using Daisōgen\e[0m"

limine/limine-deploy: limine/limine-deploy.c
	@$(MAKE) -C limine/


-include projects/list.txt

# Always compile
.PHONY: programs

# Order doesn't matter
programs: $(IN_BOOT)
$(IN_BOOT): | $(BOOT_DIR)
	@#I think this doesnt really work
	@cd projects/$@ && cargo build
	@cp -v projects/$@/target/x86_64-daisogen/debug/$@ $(BOOT_DIR)/


$(BOOT_DIR):
	@mkdir -p $@


clean:
	@echo '🧹🧹🧹'
	@$(foreach x, $(IN_BOOT), cd projects/$(x) && cargo clean && cd ../..;)
	@rm -rfv $(IMG) $(IMGPATH)
