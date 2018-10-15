require 'mail'
require 'zip'

module Libis
  module Ingester
    module Base

      module Mailer

        def send_email(*attachments, &block)
          mail = Mail.new do
            from "teneo.libis@gmail.com"
          end
          block.call(mail)
          attachments.each do |file|
            mail.add_file file
          end
          mail.deliver!
          message = "Message '#{mail.subject}'"
          mail_to = "to #{mail.to}#{mail.cc ? " and #{mail.cc}" : ''}"
          debug "#{message} sent #{mail_to}"
          return true

        rescue Exception => e

          if e.message =~ /message file too big/ && !attachments.empty?

            if attachments.all? { |x| x =~ /\.zip$/ }

              warn "Email '#{message}' is too big. Sending without attachments."

              mail.body = mail.body.to_s + "\n\nWarning: The attachments were too big. Attachments can be found at:"
              attachments.each do |file|
                mail.body = mail.body.to_s + "\n - #{file}"
              end

              attachments = []

            else

              warn "Email '#{message}' is too big. Retrying with zip compression."

              Zip.default_compression = Zlib::BEST_COMPRESSION

              attachments.map! do |file|
                zip_file = File.join('/tmp', "#{File.basename(file)}.zip")
                Zip::File.open(zip_file, Zip::File::CREATE) do |zip|
                  zip.add(File.basename(file), file)
                end
                zip_file
              end

            end

            send_email attachments, &block

          else

            error "#{message}' could not be sent #{mail_to}: #{e.message}"

            attachments.each do |file|
              warn "Attachment can be found here: #{file}"
            end

            return false

          end

        end

      end

    end
  end
end
