#!/usr/bin/env bash

set -e

dependencies=("git" "perl" "cpanm")

export PERL_MM_USE_DEFAULT=1

function cleanup() {
    if [[ -d "SubPar-Web" ]]; then
        echo "Cleaning up SubPar-Web due to failure..."
        rm -rf SubPar-Web/
    fi
}
trap cleanup ERR

for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "$dep is required but not installed. Aborting."
        exit 1
    fi
done

echo "Cloning SubPar-Web..."
git clone -b dev https://github.com/mateirobescu/SubPar-Web.git

cd SubPar-Web/

echo "Installing dependencies..."
cpanm --notest --installdeps  .

echo "Building and installing SubPar-Web..."
perl Makefile.PL
make 
make install UNINST=1 

cd ..

trap - ERR

echo "Cleaning up..."

rm -rf SubPar-Web/

echo ""
echo "SubPar-Web installed successfully!"
echo ""
echo "ACTION REQUIRED: Run the following command to activate subpar:"
echo ""
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  source ~/.zshrc"
else
    echo "  source ~/.bashrc"
fi
echo ""
echo "Or open a new terminal, then run 'subpar create-project' to create a new project"

