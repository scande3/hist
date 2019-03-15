module Hist
  class VersionsController < Hist::ApplicationController

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
