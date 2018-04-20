$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'libis/ingester/console/server'

run = Libis::Ingester::Run.find('59ccc88e16870a05e0abb189')

task = Libis::Ingester::FormatDirIdentifier.new nil, folder: '/nas/vol03/lbs/alma/etd-kul/sap/FIIW/out'

task.send :process, run
