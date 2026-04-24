#!/usr/bin/env bash

set -e

dependencies=("git" "perl" "cpanm")

export PERL_MM_USE_DEFAULT=1

if command -v perlbrew &>/dev/null && perlbrew version &>/dev/null; then
    echo "Using perlbrew: $(perlbrew version)"
else
    export PERL_LOCAL_LIB_ROOT="$HOME/perl5"
    export PERL_MB_OPT="--install_base $HOME/perl5"
    export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"
    export PERL5LIB="$HOME/perl5/lib/perl5"
    export PATH="$HOME/perl5/bin:$PATH"
fi

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

PERL=$(which perl)
CPANM=$(which cpanm)

echo "Cloning SubPar-Web..."
git clone -b dev https://github.com/mateirobescu/SubPar-Web.git

cd SubPar-Web/

echo "Installing dependencies..."
$CPANM --notest --installdeps  .

echo "Building and installing SubPar-Web..."
$PERL Makefile.PL
make 
make install UNINST=1 PREFIX=$($PERL -e 'use Config; print $Config{prefix}')

cd ..

trap - ERR

echo "Cleaning up..."

rm -rf SubPar-Web/

if ! grep -q 'perl5/bin' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/perl5/bin:$PATH"' >> ~/.bashrc
fi

if ! grep -q 'perl5/bin' ~/.zshrc 2>/dev/null; then
    echo 'export PATH="$HOME/perl5/bin:$PATH"' >> ~/.zshrc
fi

export PATH="$HOME/perl5/bin:$PATH"

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

