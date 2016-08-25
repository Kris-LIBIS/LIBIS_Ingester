#!/usr/bin/env ruby
require_relative 'include'

def submit_menu
  loop do
    @options[:job] = nil
    return unless select_job
    queue = select_defined_queue
    next unless queue

    job = @options[:job]
    options = [job.id.to_s]

    options[1] = select_options(job)

    run_name = @hl.ask('Specific run name: ')

    bulk = select_bulk_option(options[1])

    options[1]['run_name'] = clean_string run_name

    if bulk
      key = bulk[:key]
      next unless @hl.agree("Ready to submit #{bulk[:values].count} runs for job #{@options[:job].name}. OK?", false)

      base_dir = options[1][key]
      base_name = options[1]['run_name']
      bulk[:values].each do |value|
        options[1]['run_name'] = clean_string "#{base_name}/#{clean_string(value.gsub(/^#{base_dir}/, ''))}"
        options[1][key] = value
        Sidekiq::Client.push(
            'class' => 'Libis::Ingester::JobWorker',
            'queue' => queue.name,
            'retry' => false,
            'args' => options
        )
        puts "Job #{@options[:job].name} submitted for #{key} = #{value}"
      end
    else
      next unless @hl.agree("Ready to submit run for job #{@options[:job].name} with #{options[1]}. OK?", false)
      Sidekiq::Client.push(
          'class' => 'Libis::Ingester::JobWorker',
          'queue' => queue.name,
          'retry' => false,
          'args' => options
      )
      puts "Run for job #{@options[:job].name} submitted with #{options[1]}."
    end
  end
end

def clean_string(s)
  s.split(/[^\w\/-]+/).reject { |x| x.empty? }.join('_').split(/[\/-]+/).reject{|x|x.empty?}.join('-')
end
