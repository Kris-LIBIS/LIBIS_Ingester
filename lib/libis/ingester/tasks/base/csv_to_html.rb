require 'csv'
require 'cgi'

module Libis
  module Ingester
    module Base

      module Csv2Html

        def csv2html(csv_file, html_file = nil)
          csv_in = File.open(csv_file, 'r')
          html_out = html_file ? File.open(html_file, 'w') : StringIO.new
          csv2html_io(csv_in, html_out)
          csv_in.close
          return html_out if StringIO === html_out
          html_out.close
        end

        def csv2html_io(csv_in, html_out = nil)
          html_out ||= StringIO.new
          html_out.puts <<~STR
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              table {
                font-family: arial, sans-serif;
                font-size: 12px;
                border-collapse: collapse;
                width: 100%;
              }

              td, th {
                border: 1px solid #dddddd;
                text-align: left;
                padding: 5px;
              }

              tr:nth-child(even) {
                background-color: #dddddd;
              }

              .debug {
                color: gray;
              }

              .info {
                color: black;
              }

              .warn {
                color: #b35900;
              }

              .error {
                color: red;
              }   

              .fatal {
                color: white;
                background-color: red;
              }

            </style>
          </head>
          <body>
            <table>
          STR

          first_line = true
          csv_in.each_line do |line|
            row = CSV.parse_line(line, col_sep: ';', quote_char: '"')
            el = 'tr'
            case row[0]
            when 'DEBUG'
              el += ' class="debug"'
            when 'WARN'
              el += ' class="warn"'
            when 'ERROR'
              el += ' class="error"'
            when 'FATAL'
              el += ' class="fatal"'
            else
              el += ' class="info"'
            end
            html_out.puts "    <#{el}>"
            el = first_line ? 'th' : 'td'
            row.each do |col|
              html_out.puts "      <#{el}>#{CGI.escapeHTML(col)}</#{el}>"
            end
            html_out.puts '    </tr>'
            first_line = false
          end

          html_out.puts <<~STR
            </table>
          </body>
          </html>
          STR

          html_out
        end

      end

    end
  end
end