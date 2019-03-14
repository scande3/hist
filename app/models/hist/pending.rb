module Hist
  class Pending < Hist::ApplicationRecord

    self.table_name = "hist_pendings"

    def self.start_pending
      ActiveRecord::Base.transaction do
        yield
        raise ActiveRecord::Rollback, "Don't save pending object changes"
      end
    end

    def self.get_new_raw(klass:, user: nil, extra: nil, only: 'kept')
      if user.nil?
        if extra.nil?
          versions = self.where(model: Hist.model(klass: klass), obj_id: nil).send(only).reverse
        else
          versions = self.where(model: Hist.model(klass: klass), obj_id: nil, extra: extra).send(only).reverse
        end

      else
        if extra.nil?
          # .to_s to support either user object or username
          versions = self.where(model: Hist.model(klass: klass), obj_id: nil, user: user.to_s).send(only).reverse
        else
          # .to_s to support either user object or username
          versions = self.where(model: Hist.model(klass: klass), obj_id: nil, user: user.to_s, extra: extra).send(only).reverse
        end
      end

      versions
    end

    def self.get_new(klass:, user: nil, extra: nil, only: 'kept')
      hash_versions = self.get_new_raw(klass: klass, user: user, extra: extra, only: only)
      versions = hash_versions.map {|v| v.reify }
      versions
    end

    def self.put(obj:, user: nil, extra: nil)
      # Trim old pendings
      # TODO: make this more efficient
      if obj.class.base_class.hist_config.max_pendings >= 0
        versions = self.class.raw_get(obj: obj, only: 'discarded')
        if versions.size >= obj.class.base_class.hist_config.max_pendings
          versions.last.destroy!
        end
      end

      super
    end
  end
end
