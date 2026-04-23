#!/usr/bin/env bash

dependencies=("git" "perl" "cpanm")

set -e

export PERL_MM_USE_DEFAULT=1

for dep in "${dependencies[@]}"; do
    if ! command -v $dep >/dev/null 2>&1; then
        echo "$dep is required but not installed. Aborting."
        exit 1
    fi
done

echo "Cloning SubPar-Web..."
git clone -b dev https://github.com/mateirobescu/SubPar-Web.git

cd SubPar-Web/

echo "Installing dependencies..."
cpanm --installdeps .

echo "Building and installing SubPar-Web..."
perl Makefile.PL
make 
make install UNINST=1

cd ..

echo "Cleaning up..."
rm -rf SubPar-Web/

echo "SubPar-Web installed successfully!"
echo "Run 'subpar create-project' to create a new project"

