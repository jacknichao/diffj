#!/usr/bin/jruby -w
# -*- ruby -*-

require 'rubygems'
require 'riel'
require 'java'
require 'diffj/ast/item'

include Java

module DiffJ
  class FunctionComparator < ItemComparator
    RETURN_TYPE_CHANGED = "return type changed from {0} to {1}"

    PARAMETER_REMOVED = "parameter removed: {0}"
    PARAMETER_ADDED = "parameter added: {0}"
    PARAMETER_REORDERED = "parameter {0} reordered from argument {1} to {2}"

    PARAMETER_TYPE_CHANGED = "parameter type changed from {0} to {1}"
    PARAMETER_NAME_CHANGED = "parameter name changed from {0} to {1}"
    PARAMETER_REORDERED_AND_RENAMED = "parameter {0} reordered from argument {1} to {2} and renamed {3}"

    THROWS_REMOVED = "throws removed: {0}"
    THROWS_ADDED = "throws added: {0}"
    THROWS_REORDERED = "throws {0} reordered from argument {1} to {2}"
    
    def compare_return_types from, to
      from_ret_type     = from.jjtGetChild(0)
      to_ret_type       = to.jjtGetChild(0)
      from_ret_type_str = from_ret_type.to_string
      to_ret_type_str   = to_ret_type.to_string

      if from_ret_type_str != to_ret_type_str
        changed from_ret_type, to_ret_type, RETURN_TYPE_CHANGED, from_ret_type_str, to_ret_type_str
      end
    end

    def get_child_names name_list
      name_list.snatch_children "net.sourceforge.pmd.ast.ASTName"
    end

    def compare_each_parameter from_formal_params, from_params, to_formal_params, to_params, size
      (0 ... size).each do |idx|
        from_param = from_params.get idx
        param_match = org.incava.pmdx.ParameterUtil.getMatch from_params, idx, to_params

        from_formal_param = org.incava.pmdx.ParameterUtil.getParameter from_formal_params, idx

        if param_match[0] == idx && param_match[1] == idx
          Log.info "exact match"
        elsif param_match[0] == idx
          mark_parameter_name_changed from_formal_param, to_formal_params, idx
        elsif param_match[1] == idx
          mark_parameter_type_changed from_param, to_formal_params, idx
        elsif param_match[0] >= 0
          check_for_reorder from_formal_param, idx, to_formal_params, param_match[0]
        elsif param_match[1] >= 0
          mark_reordered from_formal_param, idx, to_formal_params, param_match[1]
        else
          mark_removed from_formal_param, to_formal_params
        end
      end

      to_params.each_with_index do |to_param, to_idx|
        if to_param
          to_formal_param = org.incava.pmdx.ParameterUtil.getParameter to_formal_params, to_idx
          to_name = org.incava.pmdx.ParameterUtil.getParameterName to_formal_param
          changed from_formal_params, to_formal_param, PARAMETER_ADDED, to_name.image
        end
      end
    end

    def check_for_reorder from_param, from_idx, to_formal_params, to_idx
      from_name_tk = org.incava.pmdx.ParameterUtil.getParameterName from_param
      to_name_tk = org.incava.pmdx.ParameterUtil.getParameterName to_formal_params, to_idx
      if from_name_tk.image == to_name_tk.image
        changed from_name_tk, to_name_tk, PARAMETER_REORDERED, from_name_tk.image, from_idx, to_idx
      else
        changed from_name_tk, to_name_tk, PARAMETER_REORDERED_AND_RENAMED, from_name_tk.image, from_idx, to_idx, to_name_tk.image
      end
    end

    # $$$ @untested
    def mark_reordered from_param, from_idx, to_params, to_idx
      from_name_tk = org.incava.pmdx.ParameterUtil.getParameterName from_param
      to_param = org.incava.pmdx.ParameterUtil.getParameter(to_params, to_idx)
      changed from_param, to_param, PARAMETER_REORDERED, from_name_tk.image, from_idx, to_idx
    end

    def mark_removed from_param, to_params
      from_name_tk = org.incava.pmdx.ParameterUtil.getParameterName from_param
      changed from_param, to_params, PARAMETER_REMOVED, from_name_tk.image
    end

    def mark_parameter_type_changed from_param, to_formal_params, idx
      to_param = org.incava.pmdx.ParameterUtil.getParameter to_formal_params, idx
      to_type = org.incava.pmdx.ParameterUtil.getParameterType to_param
      changed from_param.getParameter(), to_param, PARAMETER_TYPE_CHANGED, from_param.getType(), to_type
    end

    def mark_parameter_name_changed from_param, to_formal_params, idx
      from_name_tk = org.incava.pmdx.ParameterUtil.getParameterName from_param
      to_name_tk = org.incava.pmdx.ParameterUtil.getParameterName to_formal_params, idx
      changed from_name_tk, to_name_tk, PARAMETER_NAME_CHANGED, from_name_tk.image, to_name_tk.image
    end

    def mark_parameters_added from_formal_params, to_formal_params
      names = org.incava.pmdx.ParameterUtil.getParameterNames to_formal_params
      names.each do |name|
        changed from_formal_params, name, PARAMETER_ADDED, name.image
      end
    end

    def mark_parameters_removed from_formal_params, to_formal_params
      names = org.incava.pmdx.ParameterUtil.getParameterNames from_formal_params
      names.each do |name|
        changed name, to_formal_params, PARAMETER_REMOVED, name.image
      end
    end
    
    def compare_parameters from_params, to_params
      from_param_list = org.incava.pmdx.ParameterUtil.getParameterList from_params
      to_param_list = org.incava.pmdx.ParameterUtil.getParameterList to_params
        
      from_param_types = org.incava.pmdx.ParameterUtil.getParameterTypes from_params
      to_param_types = org.incava.pmdx.ParameterUtil.getParameterTypes to_params

      from_size = from_param_types.size
      to_size = to_param_types.size

      if from_size > 0
        if to_size > 0
          compare_each_parameter from_params, from_param_list, to_params, to_param_list, from_size
        else
          mark_parameters_removed from_params, to_params
        end
      elsif to_size > 0
        mark_parameters_added from_params, to_params
      end
    end

    def change_throws from_node, to_node, msg, name
      changed from_node, to_node, msg, name.to_string
    end

    def add_all_throws from_node, to_name_list
      names = get_child_names to_name_list
      names.each do |name|
        change_throws from_node, name, THROWS_ADDED, name
      end
    end

    def remove_all_throws from_name_list, to_node
      names = get_child_names from_name_list
      names.each do |name|
        change_throws name, to_node, THROWS_REMOVED, name
      end
    end

    def get_match from_names, from_idx, to_names
      from_name_str = from_names.get(from_idx).to_string

      (0 ... to_names.size).each do |to_idx|
        to_name = to_names.get(to_idx)
        if to_name && to_name.to_string == from_name_str
          from_names.set(from_idx, nil)
          to_names.set(to_idx, nil) # mark as consumed
          return to_idx
        end
      end
      nil
    end

    def compare_each_throw from_name_list, to_name_list
      from_names = get_child_names from_name_list
      to_names = get_child_names to_name_list

      (0 ... from_names.size()).each do |from_idx|
        # save a reference to the name here, in case it gets removed
        # from the array in getMatch.
        from_name = from_names.get from_idx
        
        throws_match = get_match from_names, from_idx, to_names

        if throws_match.nil?
          change_throws from_name, to_name_list, THROWS_REMOVED, from_name
        elsif throws_match == from_idx
          next
        elsif throws_match
          to_name = org.incava.pmdx.ThrowsUtil.getNameNode to_name_list, throws_match
          from_name_str = from_name.to_string
          changed from_name, to_name, THROWS_REORDERED, from_name_str, from_idx, throws_match
        end
      end

      (0 ... to_names.size()).each do |to_idx|
        if to_names.get(to_idx)
          to_name = org.incava.pmdx.ThrowsUtil.getNameNode to_name_list, to_idx
          change_throws from_name_list, to_name, THROWS_ADDED, to_name
        end
      end
    end

    def compare_throws from_node, from_name_list, to_node, to_name_list
      if from_name_list.nil?
        if to_name_list
          add_all_throws from_node, to_name_list
        end
      elsif to_name_list.nil?
        remove_all_throws from_name_list, to_node
      else
        compare_each_throw from_name_list, to_name_list
      end
    end
  end
end
