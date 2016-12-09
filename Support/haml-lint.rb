#!/usr/bin/env ruby

begin
  require 'haml_lint'
  require 'haml_lint/cli'
  require 'json'
rescue LoadError
  puts "Install haml_lint!\ngem install haml_lint"
  exit 1
end

def log(msg)
  require 'logger'
  logger = Logger.new('/tmp/haml_lint_bundle.log')
  logger.info msg
end

def offences(file)
  io = StringIO.new
  logger = HamlLint::Logger.new(io)
  HamlLint::CLI.new(logger).run(['--reporter', 'JSON', file])
  offence = JSON.parse(io.string)
  offence["files"][0]["offenses"]
end

def messages(offences)
  messages = {
    warning: {},
    error: {}
  }
  offences.each do |offence|
    severity = offence["severity"].to_sym
    line = offence["location"]["line"]
    message = messages[severity][line] ||= []
    message << offence["message"].gsub('`', "'")
  end
  messages
end

def command(messages)
  icons = {
    warning:    "#{ENV['TM_BUNDLE_SUPPORT']}/neutral.png".inspect,
    error:      "#{ENV['TM_BUNDLE_SUPPORT']}/sad.png".inspect
  }
  args = []

  messages.each do |severity, messages|
    args << ["--clear-mark=#{icons[severity]}"]
    messages.each do |line, message|
      args << "--set-mark=#{icons[severity]}:#{message.uniq.join('. ').inspect}"
      args << "--line=#{line}"
    end
  end

  args << ENV['TM_FILEPATH'].inspect

  "#{ENV['TM_MATE']} #{args.join(' ')}"
end

cmd = command(messages(offences(ENV['TM_FILEPATH'])))

# log cmd
exec cmd
