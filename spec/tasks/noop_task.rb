require 'libis/ingester'

class NoopTask < Libis::Ingester::Task

  parameter param1: nil
  parameter param2: nil
  parameter param3: nil
  parameter param4: nil
  parameter param5: 'set in task definition'
  parameter param6: 'set in task definition'
  parameter param7: 'set in task definition'
  parameter param8: 'set in task definition'
  parameter paramxx: {}

  def process(_)
    self.class.parameter_defs.keys.each do |name|
      debug "#{name}: '#{parameter(name.to_sym)}'"
    end
  end

end