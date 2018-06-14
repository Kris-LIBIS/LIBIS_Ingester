#! /usr/bin/env ruby

require 'fileutils'
require 'zip'
require 'mail'

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'libis/ingester/tasks/base/mailer'

Zip.on_exists_proc = true
Zip.default_compression = Zlib::BEST_COMPRESSION

class AcpInstaller
  include Libis::Ingester::Base::Mailer

  attr_reader :acp_file, :target_dir, :email, :pkg

  def initialize(acp_file, target_dir, email)
    unless acp_file
      error "Must supply an ACP file path"
      exit 1
    end
    unless target_dir
      error "Must supply a target directory"
      exit 1
    end
    unless email
      error "Must supply one or more email addresses separated with a comma"
    end
    @acp_file = acp_file
    @pkg = File.basename(acp_file, '.*')
    @target_dir = File.join(target_dir, @pkg)
    @email = email
  end

  def process
    # prepare target dir
    FileUtils.mkdir_p(target_dir, mode: 0755)

    # unzip the acp into the target dir
    Zip::File.foreach(acp_file) do |entry|
      dest = File.join(target_dir, entry.name)
      puts "Extracting #{entry.name}"
      dest_dir = File.dirname(dest)
      FileUtils.mkdir_p(dest_dir, mode: 0755) unless Dir.exist?(dest_dir)
      entry.extract(dest)
      FileUtils.chmod(0644, dest)
    end

    # The extracted XML file
    xml_file = File.join(target_dir, "#{pkg}.xml")

    # Compress the XML file
    zip_file = File.join('/tmp', "#{pkg}.zip")
    Zip::File.open(zip_file, Zip::File::CREATE) do |zip|
      zip.add(File.basename(xml_file), xml_file)
    end

    # email the compressed XML file
    error "Could not send email" unless send_email(zip_file) do |mail|
      mail.from  = "teneo.libis@gmail.com"
      mail.to = email
      mail.subject = "[VLP] ACP #{pkg}"
      mail.body = "The ACP file '#{pkg}' has been extracted and prepared for ingest in Teneo.\n" +
        "Please find the extracted XML file in the attached zip file."
    end

    # remove zip_file
    FileUtils.rm zip_file

  end

  protected

  def debug(message)
    puts "DEBUG: #{message}"
  end

  def info(message)
    puts "INFO: #{message}"
  end

  def warn(message)
    puts "WARNING: #{message}"
  end

  def error(message)
    $stderr.puts "ERROR: #{message}"
  end

end

if ARGV.count != 3
  puts "USAGE: #{File.basename(__FILE__)} <acp_file> <target_dir> <email>"
  puts "  with:"
  puts "   <acp_file>   : the path to the ACP file"
  puts "   <target_dir> : a directory to extract the ACP into (*)"
  puts "   <email>      : the email address to send the XML file to (+)"
  puts ""
  puts "  notes:"
  puts "    (*) in the <target_dir> a subdir with the name of the ACP file will be created and the ACP content will be"
  puts "        extracted into that subdirectory"
  puts "    (+) multiple email addresses can be supplied by separating them with a comma"
  exit 1
end
acp_file = ARGV.shift
target_dir = ARGV.shift
email = ARGV.shift
AcpInstaller.new(acp_file, target_dir, email).process
