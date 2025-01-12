#!/usr/bin/env ruby
# frozen_string_literal: true

# ruby locales_scan.rb -c locales.yml -o output.yml

require 'yaml'
require 'optparse'
require 'find'

# Localization Tool
#
# This tool reads a YAML config file provided as an argument and processes localization definition and use files.
# The YAML config file should define two main keys: one for localization definition files and one for localization use files.
# Each key should accept one or more globs which define where to search for those files.
# The tool parses all localization definition files to collect existing definitions and all localization use files to collect usage information.
# It then emits the collected information as a YAML file to stdout or to a specified output file.
#
# Usage:
#   ruby locales_scan.rb -c locales.yml -o output.yml
#
# Options:
#   -c, --config CONFIG    The YAML config file.
#   -o, --output OUTPUT    The output file (optional).
class LocalizationTool
  # Initializes the LocalizationTool with command-line arguments.
  #
  # @param [Array<String>] args The command-line arguments.
  def initialize(args) # rubocop:disable Metrics/MethodLength
    @options = {}
    OptionParser.new do |opts|
      opts.banner = 'Usage: locales_scan.rb [options]'

      opts.on('-c', '--config CONFIG', 'YAML config file') do |config|
        @options[:config] = config
      end

      opts.on('-o', '--output OUTPUT', 'Output file') do |output|
        @options[:output] = output
      end
    end.parse!(args)

    @config = YAML.load_file(@options[:config])
    @localizations = {}
  end

  # Parses localization definition files and collects translations.
  #
  # @param [String] file The file to parse.
  # @param [Hash] localizations The hash to store localization definitions.
  # @return [void]
  def parse_definitions(file, localizations)
    language = nil
    File.foreach(file) do |line|
      if line =~ /NewLocale\s*\([^,]*,\s*["'](\w{4})/
        language = ::Regexp.last_match(1)
      elsif line =~ /L\s*\[\s*["'](.+)["']\s*\]\s*=\s*["'](.+)["']/
        text = ::Regexp.last_match(1)
        localizations[text] ||= {}
        localizations[text][language] = ::Regexp.last_match(2)
      end
    end
  end

  # Tokenizes a line of code to find all localization string uses.
  #
  # @param [String] line The line of code to tokenize.
  # @return [Array<String>] An array of localization strings found in the line.
  def tokenize(line)
    regex = /L\['(.+?)'\]/
    line.scan(regex).flatten.map do |text|
      text
    end
  end

  # Parses localization use files and collects usage information.
  #
  # @param [String] file The file to parse.
  # @param [Hash] localizations The hash to store localization uses.
  # @return [void]
  def parse_uses(file, localizations)
    File.foreach(file) do |line|
      tokenize(line).each do |text|
        localizations[text] ||= {}
        localizations[text]['use'] = true
      end
    end
  end

  # Processes the localization files based on the config and collects data.
  #
  # @return [void]
  def process_files
    @config[:definitions].each do |glob|
      Dir.glob(glob).each do |file|
        parse_definitions(file, @localizations)
      end
    end

    @config[:uses].each do |glob|
      Dir.glob(glob).each do |file|
        parse_uses(file, @localizations)
      end
    end
  end

  # Outputs the collected localization data as a YAML file.
  #
  # @return [void]
  def output_result
    result = { localizations: @localizations }

    if @options[:output]
      File.write(@options[:output], result.to_yaml)
    else
      puts result.to_yaml
    end
  end
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  tool = LocalizationTool.new(ARGV)
  tool.process_files
  tool.output_result
end
