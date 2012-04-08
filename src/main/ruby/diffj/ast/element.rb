#!/usr/bin/jruby -w
# -*- ruby -*-

require 'rubygems'
require 'riel'
require 'java'

include Java

module DiffJ
  class Delta
    include Loggable
    
    attr_reader :filediff

    def initialize args
      ast_elements = Array.new

      info "args: #{args}".green
      args.each do |arg|
        info "arg: #{arg}".green
        info "arg.class: #{arg.class}".green
      end

      @tokens = Array.new
      @msg = nil
      @params = nil

      info "params: #{@params} #{@params.class}".on_blue      

      args.each_with_index do |arg, idx|
        if arg.class == String
          @msg = arg
          @params = args[idx + 1 .. -1]
          ast_elements = args[0 ... idx]
          info "params: #{@params} #{@params.class}".blue
          break
        end
      end

      if ast_elements.size == 4
        @tokens = ast_elements
        info "params: #{@params} #{@params.class}".magenta
      else
        ast_classes = ast_elements.collect { |ast| ast.class.to_s.sub(%r{.*::}, '').sub(%r{AST\w+}, 'SimpleNode').downcase }.join('_')
        meth = "process_#{ast_classes}".to_sym
        method(meth).call(*ast_elements)
        info "params: #{@params} #{@params.class}".bold
      end

      info "params: #{@params} #{@params.class}".yellow

      params = @params
      info "params: #{params} #{params.class}".on_green
      info "params: #{@params} #{@params.class}".on_blue

      parmary = java.util.ArrayList.new
      @params.each do |parm|
        parmary << parm
      end

      mf = java.text.MessageFormat.new @msg
      # fmtmeth = mf.java_method :format, [ :
      # info "fmtmeth: #{fmtmeth}".on_yellow
      sb = mf.format parmary.toArray, java.lang.StringBuffer.new, java.text.FieldPosition.new(0)
      info "sb: #{sb}".yellow

      str = sb.toString
      
      fdcls = get_filediff_cls

      info "tokens: #{@tokens.inspect}"
      @tokens.each do |tk|
        info "tk: #{tk}"
        info "tk.class: #{tk.class}"
      end
      
      if @tokens.length == 2
        @filediff = fdcls.new str, @tokens[0], @tokens[1]
      else
        @filediff = fdcls.new str, @tokens[0], @tokens[1], @tokens[2], @tokens[3]
      end
    end    

    def process_token_simplenode from_tk, to_sn
      @tokens.concat [ from_tk, from_tk, to_sn.getFirstToken(), to_sn.getLastToken() ]
    end

    def process_simplenode_token from_sn, to_tk
      @tokens.concat [ from_sn.getFirstToken(), from_sn.getLastToken(), to_tk, to_tk  ]
    end

    def process_token_token from_tk, to_tk
      @tokens.concat [ from_tk, to_tk ]
      if @params.empty?
        @params = tokens_to_parameters from_tk, to_tk
      end      
    end

    def process_simplenode_simplenode from_sn, to_sn
      @tokens.concat [ from_sn.getFirstToken(), from_sn.getLastToken(), to_sn.getFirstToken(), to_sn.getLastToken() ]
      if @params.empty?
        @params = nodes_to_parameters from_sn, to_sn
      end
    end

    def get_filediff_class
    end

    def tokens_to_parameters from, to
      params = java.util.ArrayList.new
      if from
        params.add from.image
      end
      if to
        params.add to.image
      end
      params.toArray
    end

    def nodes_to_parameters from, to
      params = java.util.ArrayList.new
      if from
        params.add from.to_string
      end
      if to
        params.add to.to_string
      end
      params.toArray
    end
  end

  class Add < Delta
    def tokens_to_parameters from_tk, to_tk
      super nil, to
    end

    def nodes_to_parameters from_sn, to_sn
      super nil, to_sn
    end

    def get_filediff_cls
      org.incava.analysis.FileDiffAdd
    end
  end

  class Remove < Delta    
    def tokens_to_parameters from_tk, to_tk
      super from_tk, nil
    end

    def nodes_to_parameters from_sn, to_sn
      super from_sn, nil
    end

    def get_filediff_cls
      org.incava.analysis.FileDiffDelete
    end
  end

  class Change < Delta
    def get_filediff_cls
      org.incava.analysis.FileDiffChange
    end
  end

  class ElementComparator
    include Loggable

    attr_reader :filediffs

    def initialize filediffs
      @filediffs = filediffs
    end

    def add ref
      @filediffs << ref
    end

    def changed *args
      chgobj = Change.new args
      @filediffs << chgobj.filediff
    end

    def added *args
      addobj = Add.new args
      @filediffs << addobj.filediff
    end

    def deleted *args
      remobj = Remove.new args
      @filediffs << remobj.filediff
    end
  end    
end
