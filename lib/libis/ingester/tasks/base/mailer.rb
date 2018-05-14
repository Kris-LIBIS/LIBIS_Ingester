require 'mail'

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
            warn "#{message} with attachments was too big. Retrying without attachments"
            attachments.each do |file|
              warn "Attachment can be found here: #{file}"
            end
            send_email &block
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
