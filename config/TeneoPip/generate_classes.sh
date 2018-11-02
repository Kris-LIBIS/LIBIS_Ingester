#!/usr/bin/env bash
# Needs to be run in a jruby < 9.x enviroment with jaxb2ruby gem installed
# Load RVM into a shell session *as a function*
#if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
#
#  # First try to load from a user install
#  source "$HOME/.rvm/scripts/rvm"
#
#elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
#
#  # Then try to load from a root install
#  source "/usr/local/rvm/scripts/rvm"
#
#else
#
#  printf "ERROR: An RVM installation was not found.\n"
#
#fi
#rvm use jruby-1.7
rm -fR ruby
jaxb2ruby -t roxml -n "https://teneo.libis.be/schema=Libis::Ingester::Teneo" ../TeneoPip.xsd
cd ruby/libis/ingester
TGT=../../../../../lib/libis/ingester/teneo
rm -fR ${TGT}
cp -R teneo ${TGT}
cd -
