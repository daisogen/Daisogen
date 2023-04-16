#!/bin/sh -e

# This file takes projects.txt and builds .expansion.mk, which is used in
# the Makefile, and img/boot/limine.cfg, which lets Limine (the bootloader)
# know which modules to load.

rm -f .expansion.mk limine.cfg || :

if [ ! -f projects.txt ]; then
    echo "error"
    exit
fi

# Add the kernel
cat > .expansion.mk <<EOF
PROJECTS := kernel
repo_kernel := https://github.com/daisogen/kernel

EOF

# At the same time, let's build limine.cfg
mkdir -p img/boot/
LIMINE=img/boot/limine.cfg
cat > $LIMINE <<EOF
TIMEOUT=0
TEXTMODE=yes

:Daisogen
DEPRECATION_WARNING=no
PROTOCOL=stivale2
KASLR=no
KERNEL_PATH=boot:///boot/kernel

EOF

# Here we go
CTR=0
while IFS= read -r line; do
    name="$(echo "$line" | cut -d" " -f1)"
    repo="$(echo "$line" | cut -d" " -f2)"

    if [ -z "$name" ]; then
        # Empty line, ignore
        continue
    fi

    if [ "${name:0:1}" = "#" ]; then
        # Commented, ignore
        continue
    fi

    echo "PROJECTS += $name" >> .expansion.mk
    echo "repo_$name := $repo" >> .expansion.mk
    # All Daisogen programs need to be PIC, so let's add it here directly
    echo "flags_$name := --config 'build.rustflags = [\"-Crelocation-model=pic\", \"-Clink-arg=-pie\"]'" >> .expansion.mk

    echo "MODULE_PATH=boot:///boot/$name" >> $LIMINE
    echo "MODULE_STRING=$CTR $name" >> $LIMINE
    echo >> $LIMINE

    (( CTR=CTR+1 ))
done < projects.txt
