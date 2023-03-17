#!/bin/sh -e

rm -f .expansion.mk limine.cfg || :

if [ ! -f projects.txt ]; then
    echo "error"
    exit
fi

# The two basics: kernel and std
cat > .expansion.mk <<EOF
repo_std := https://github.com/daisogen/std

PROJECTS := kernel
repo_kernel := https://github.com/daisogen/kernel

EOF

# At the same time, let's build limine.cfg
cat > limine.cfg <<EOF
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
while read p; do
    name="$(echo "$p" | cut -d" " -f1)"
    repo="$(echo "$p" | cut -d" " -f2)"

    echo "PROJECTS += $name" >> .expansion.mk
    echo "repo_$name := $repo" >> .expansion.mk

    echo "MODULE_PATH=boot:///boot/$name" >> limine.cfg
    echo "MODULE_STRING=$CTR $name" >> limine.cfg
    echo >> limine.cfg

    (( CTR++ ))
done < projects.txt
