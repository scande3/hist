module Hist
  class Version < Hist::ApplicationRecord

    self.table_name = "hist_versions"

    def self.put(obj:, user: nil, extra: nil)
      # Trim old versions
      # TODO: make this more efficient
      if obj.class.base_class.hist_config.max_versions >= 0
        versions = self.raw_get(obj: obj)
        if versions.size >= obj.class.base_class.hist_config.max_versions
          versions.last.destroy!
        end
      end

      super
    end

  end
end
