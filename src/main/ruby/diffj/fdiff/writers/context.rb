#!/usr/bin/jruby -w
# -*- ruby -*-

require 'rubygems'
require 'riel'
require 'java'
require 'diffj/fdiff/writers/writer'

include Java

module DiffJ
  module FDiff
    module Writer
      class ContextWriter < BaseWriter
        include Loggable

        def initialize from_contents, to_contents
          @from_contents = from_contents
          @to_contents = to_contents
        end

        def print_from sb, fdiff
          print_lines_by_location sb, true, fdiff.first_location, @from_contents
        end

        def print_to sb, fdiff
          print_lines_by_location sb, false, fdiff.second_location, @to_contents
        end

        def print_lines sb, fdiff
          info "fdiff: #{fdiff}; #{fdiff.class}"
          fdiff.print_context self, sb
          sb.append EOLN
        end

        def print_lines sb, fdiff
          info "fdiff: #{fdiff}; #{fdiff.class}"
          fdiff.print_context self, sb
          sb.append EOLN
        end

        def get_line lines, lidx, from_line, from_column, to_line, to_column, is_delete
          raise "abstract method!"
        end

        def line_to_s line, ch = " "
          "#{ch} #{line}\n"
        end
        
        def print_lines_by_location sb, is_delete, locrg, lines
          from_line = locrg.from.line
          from_column = locrg.from.column
          to_line = locrg.to.line
          to_column = locrg.to.column

          ([ 0, from_line - 4 ].max ... from_line - 1).each do |lnum|
            sb.append line_to_s lines[lnum]
          end

          (from_line .. to_line).each do |lidx|
            line = get_line(lines, lidx, from_line, from_column, to_line, to_column, is_delete)
            sb.append line
          end

          (to_line ... [ to_line + 3, lines.size() ].min).each do |lnum|
            sb.append line_to_s lines[lnum]
          end
        end
      end
    end
  end
end