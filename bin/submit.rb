#!/usr/bin/env ruby
require_relative '../lib/libis/ingester/console/include'

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  common_opts(opts)
  job_opts(opts)

end.parse!

get_initializer
exit unless select_job

queue = select_defined_queue

job = @options[:job]
options = [job.id.to_s]
input = {}
job.workflow.config['input'].each do |key, value|
  input[key] = value
end
job.input.each do |key, value|
  input[key]['default'] = value
end
set_option = Proc.new { |opt|
  key, value = opt
  puts "key: #{key}, value: #{value}"
  value = if value['default']
            @hl.ask("#{key} : ", value['default'].class) { |q| q.default = value['default'] }
          else
            @hl.ask("#{key} : ")
          end
  [key, value]
}

puts input

loop do
  option = selection_menu('Options', input, parent: job.name, proc: set_option) { |opt| "#{opt.first} : #{opt.last['default']}" }
  break unless option
  key, value = option
  options[1] ||= {}
  options[1][key] = value
  input[key]['default'] = value
end

until (option = @hl.ask('option: ') { |q| q.validate = /\A([a-z][a-z0-9_]*|)\Z/ }).empty?
  value = @hl.ask('value for #{option): ')
  options[1][option] = value
end

Sidekiq::Client.push(
    'class' => 'Libis::Ingester::JobWorker',
    'queue' => queue.name,
    'args' => options
)

puts "Job #{@options[:job].name} submitted #{"with options #{options[1].to_s}" if options[1]}..."
