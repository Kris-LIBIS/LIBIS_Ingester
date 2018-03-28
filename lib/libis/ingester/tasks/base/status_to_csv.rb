require 'csv'
require 'libis/ingester'
require 'time_difference'

module Libis
  module Ingester
    module Base

      module Status2Csv

        # @param [Libis::Ingester::WorkItem] item
        # @param [String] csv_file
        def status2csv(item, csv_file = nil)
          csv_out = csv_file ? File.open(csv_file, 'w') : StringIO.new
          status2csv_io(item, csv_out)
          return csv_out if StringIO === csv_out
          csv_out.close
        end

        # @param [Libis::Ingester::WorkItem] item
        # @param [IO] csv_out
        def status2csv_io(item, csv_out = nil)
          csv_out ||= StringIO.new

          csv_out.puts CSV.generate_line(%w'Task Progress Status Started Updated Elapsed', col_sep: ';', quote_char: '"')

          item.reload.status_log.inject({}) do |hash, status|
            task = status['task'].gsub(/[^\/]*\//, '- ')
            task = '- ' + task unless task == 'Run'
            data = {
                status: status['status'].to_s.capitalize,
                start: status['created'].localtime,
                end: status['updated'].localtime
            }
            if status['progress']
              data[:progress] = status['progress'].to_s
              data[:progress] += ' of ' + status['max'].to_s if status['max']
            end
            data.delete :start if hash[task]
            (hash[task] ||= {}).merge! data
            hash
          end.each do |task, data|
            data_array = [
                task,
                data[:progress].to_s,
                data[:status],
                data[:start].strftime('%d/%m/%Y %T'),
                data[:end].strftime('%d/%m/%Y %T'),
                time_diff_in_hours(data[:start], data[:end]),
            ]
            csv_out.puts CSV.generate_line(data_array, col_sep: ';', quote_char: '"')
          end

          csv_out
        end

        protected

        def time_diff_in_hours(start_time, end_time)
          seconds =   TimeDifference.between(start_time, end_time).in_seconds.round
          minutes = seconds / 60
          seconds = seconds % 60
          hours = minutes / 60
          minutes = minutes % 60
          "#{'%4d' % hours}:#{'%02d' % minutes}:#{'%02d' % seconds}"
        end

      end
    end
  end
end