module Hist
  class VersionsController < Hist::ApplicationController
    def diff_old
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
      if include.blank?
        exclude << 'created_at'
        exclude << 'hist_extra'
        exclude << 'whodunnit'
        exclude << 'pending_id'
        exclude << 'ver_id'
        exclude << 'user_id'
        exclude.uniq!
      end

      only_diffs = false
      only_diffs = params[:only_diffs] if params.has_key? :only_diffs

      type = params[:type].to_sym if params.has_key? :type
      type ||= :json

      if params[:left_id] == 'current'
        obj_right = Hist::Version.find(params[:right_id]).reify
        obj_left = obj_right.class.find(obj_right.id)
      else
        if params[:right_id] == 'current'
          obj_left = Hist::Version.find(params[:left_id]).reify
          obj_right = obj_left.class.find(obj_left.id)
        else
          obj_right = Hist::Version.find(params[:right_id]).reify
          obj_left = Hist::Version.find(params[:left_id]).reify
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


      if obj_left.ver_id.nil?
        @left_title = "Current Version (#{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
      else
        if obj_left.respond_to?(:hist_created_at)
          @left_title = "Version #{obj_left.ver_id} (#{obj_left.hist_created_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
        elsif obj_left.respond_to?(:created_at)
          @left_title = "Version #{obj_left.ver_id} (#{obj_left.created_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
        elsif obj_left.respond_to?(:updated_at)
          @left_title = "Version #{obj_left.ver_id} (#{obj_left.updated_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
        else
          @left_title = "Version"
        end
      end

      if obj_right.ver_id.nil?
        @right_title = "Current Version (#{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
      else
        if obj_right.respond_to?(:hist_created_at)
          @right_title = "Version #{obj_right.ver_id} (#{obj_right.hist_created_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
        elsif obj_right.respond_to?(:created_at)
          @right_title = "Version #{obj_right.ver_id} (#{obj_right.created_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
        elsif obj_right.respond_to?(:updated_at)
          # FIXME: DO BETTER
          obj_right.versions.each_with_index do |ver, index|
            if ver.ver_id.to_s == obj_right.ver_id
              @left_title = "Version #{obj_right.versions.size - (index)} (#{obj_right.updated_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
            end
          end
          #@right_title = "Version #{obj_right.ver_id} (#{obj_right.updated_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
        else
          @right_title = "Version"
        end
      end
    end

    def diff
      obj_left, obj_right = diff_base(Hist::Version)


      if obj_left.ver_id.nil?
        @left_title = "Current Version (#{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
      else
        if obj_left.respond_to?(:hist_created_at)
          #@left_title = "Version #{obj_left.ver_id} (#{obj_left.created_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
          # FIXME: DO BETTER
          obj_left.versions.each_with_index do |ver, index|
            if ver.ver_id.to_s == obj_left.ver_id.to_s
              @left_title = "Version #{obj_left.versions.size - (index)} (#{obj_left.hist_created_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
            end
          end
        elsif obj_left.respond_to?(:created_at)
          #@left_title = "Version #{obj_left.ver_id} (#{obj_left.created_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
          # FIXME: DO BETTER
          obj_left.versions.each_with_index do |ver, index|
            if ver.ver_id.to_s == obj_left.ver_id.to_s
              @left_title = "Version #{obj_left.versions.size - (index)} (#{obj_left.created_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
            end
          end
        elsif obj_left.respond_to?(:updated_at)
          # FIXME: DO BETTER
          obj_left.versions.each_with_index do |ver, index|
            if ver.ver_id.to_s == obj_left.ver_id.to_s
              @left_title = "Version #{obj_left.versions.size - (index)} (#{obj_left.updated_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
            end
          end

        else
          @left_title = "Version"
        end
      end

      if obj_right.ver_id.nil?
        @right_title = "Current Version (#{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
      else

        if obj_right.respond_to?(:hist_created_at)
          # FIXME: DO BETTER
          obj_right.versions.each_with_index do |ver, index|
            if ver.ver_id.to_s == obj_right.ver_id.to_s
              @right_title = "Version #{obj_right.versions.size - (index)} (#{obj_right.hist_created_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
            end
          end
        elsif obj_right.respond_to?(:created_at)
          #@right_title = "Version #{obj_right.ver_id} (#{obj_right.created_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
          # FIXME: DO BETTER
          obj_right.versions.each_with_index do |ver, index|
            if ver.ver_id.to_s == obj_right.ver_id.to_s
              @right_title = "Version #{obj_right.versions.size - (index)} (#{obj_right.created_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
            end
          end
        elsif obj_right.respond_to?(:updated_at)
          #@right_title = "Version #{obj_right.ver_id} (#{obj_right.updated_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
          # FIXME: DO BETTER
          obj_right.versions.each_with_index do |ver, index|
            if ver.ver_id.to_s == obj_right.ver_id.to_s
              @right_title = "Version #{obj_right.versions.size - (index)} (#{obj_right.updated_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
            end
          end
        else
          @right_title = "Version"
        end
      end
    end
  end
end
