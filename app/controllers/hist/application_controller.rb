module Hist
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    def diff_base(model)
      @aceMode = params[:mode].to_sym if params.has_key? :mode
      @aceMode ||= :yaml

      @height = params[:height] if params.has_key? :height
      @height ||= 'screen'

      field_path = params[:field_path] if params.has_key? :field_path
      field_path ||= ''

      exclude = params[:exclude] if params.has_key? :exclude
      exclude ||= []

      include = params[:include] if params.has_key? :include
      include ||= []

      # Remove some less needed differential fields
      if include.blank? && !Hist.config.default_diff_exclude.nil?
        if Hist.config.default_diff_exclude.class == Array
          exclude += Hist.config.default_diff_exclude
        else
          exclude << Hist.config.default_diff_exclude
        end

        exclude.uniq!
      end

      only_diffs = false
      only_diffs = params[:only_diffs] if params.has_key? :only_diffs

      type = params[:type].to_sym if params.has_key? :type
      type ||= :json

      if params[:left_id] == 'current'
        obj_right = model.find(params[:right_id]).reify
        obj_left = obj_right.class.find(obj_right.id)
      else
        if params[:right_id] == 'current'
          obj_left = model.find(params[:left_id]).reify
          obj_right = obj_left.class.find(obj_left.id)
        else
          obj_right = model.find(params[:right_id]).reify
          obj_left = model.find(params[:left_id]).reify
        end
      end

      @diff = {left: obj_left.hist_json(exclude: exclude, include: include), right: obj_right.hist_json(exclude: exclude, include: include)}

      if only_diffs
        diff_vals = ApplicationRecord.only_hash_diffs(h1: @diff[:left], h2: @diff[:right])
        @diff[:left] = diff_vals[:h1]
        @diff[:right] = diff_vals[:h2]
      end

      if field_path.present?
        @diff[:left] = eval('@diff[:left]' + field_path)
        @diff[:right] = eval('@diff[:right]' + field_path)
      end

      @diff_escaped = {}
      @diff_escaped[:left] = ActiveSupport::JSON.encode(@diff[:left])
      @diff_escaped[:right] = ActiveSupport::JSON.encode(@diff[:right])

      return [obj_left, obj_right]
    end
  end
end
