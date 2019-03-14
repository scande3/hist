module Hist
  class PendingsController < Hist::ApplicationController
    prepend_view_path 'app/views/hist/versions'

    def diff
      obj_left, obj_right = diff_base(Hist::Pending)

      if obj_left.ver_id.nil?
        @right_title = "Current Version (#{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
      else
        @right_title = "Submitted (Pending): #{obj_left.pending_id} (#{obj_left.created_at.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
      end

      if obj_right.ver_id.nil?
        @left_title = "Current Version (#{Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
      else
        @left_title = "Submitted (Pending): #{obj_right.pending_id} (#{obj_right.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e, %Y at %I:%M %p')} EST)"
      end
    end
  end
end
