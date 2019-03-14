module Hist
  module Model
    extend ActiveSupport::Concern

    included do
      #attribute :ver_id, :integer
      #attribute :pending_id, :integer
      #attribute :hist_whodunnit, :string
      #attribute :hist_extra, :string
    end

    class_methods do
      def has_hist(associations: nil, max_versions:-1, max_pendings: -1, include: [], exclude: [], auto_version: true)
        @hist_config = ::Hist::HistConfig.new(associations: associations, model: Hist.model(klass: self), max_versions: max_versions, max_pendings: max_pendings, include: include, exclude: exclude, auto_version: auto_version)
      end

      def hist_config
        @hist_config
      end

      def hist_new_pendings(user: nil, extra: nil, only: 'kept')
        ::Hist::Pending.get(obj: nil, user: user, extra: extra, only: only)
      end
    end

    def hist_save_actions
      Hist::Pending.find(self.pending_id).discard unless self.pending_id.nil?

      # Need to fix associations... won't update properly on parent save cause rails is baka.
      if self.pending_id.present? || self.ver_id.present?
        current = ApplicationRecord.fix_save_associations(obj: self)
      else
        current = self
      end

      # Does this happen  after reload?
      u = self.hist_whodunnit if self.record_hist_whodunnit?
      e = self.hist_extra if self.record_hist_extra?
      current.record_version(user: u, extra: e) if self.class.base_class.hist_config.auto_version

      if self.pending_id.present? || self.ver_id.present?
        self.reload
      else
        self.reload_hist
      end
    end

    def hist_around_save
      self.class.transaction do
        yield
        self.hist_save_actions
      end
    end

    def hist_after_save
      self.class.transaction do
        hist_save_actions
      end
    end

    # @api public
    def record_version(user: nil, extra: nil)
      ::Hist::Version.put(obj: self, user: user, extra: extra)
    end

    def record_pending(user: nil, extra: nil)
      ::Hist::Pending.put(obj: self, user: user, extra: extra)
    end

    def version_at_temp(date)
      @versions ||= ::Hist::Version.raw_get(obj: self)
      @versions.each do |ver|
        #raise "Date.parse: " + Date.parse(ver.created_at.to_s).to_s + " and date: " + date.to_s + " And equals: " + (Date.parse(ver.created_at.to_s) <= date).to_s + " and ver_id: " + ver.id.to_s
        if Date.parse(ver.created_at.to_s) <= date
          #raise ver.reify.ver_id.to_s
          return ver.reify
        end
      end
      return @versions.last.reify if @version.present?
      return self
    end

    def version_at(date)
      @versions ||= ::Hist::Version.get(obj: self)
      @versions.each do |ver|
        #raise "Date.parse: " + Date.parse(ver.created_at.to_s).to_s + " and date: " + date.to_s + " And equals: " + (Date.parse(ver.created_at.to_s) <= date).to_s + " and ver_id: " + ver.id.to_s
        if Date.parse(ver.hist_created_at.to_s) <= date
          #raise ver.reify.ver_id.to_s
          return ver
        end
      end
      return @versions.last if @version.present?
      return self
    end

    def raw_versions(user: nil, extra: nil, only: 'kept')
      @raw_versions ||= ::Hist::Version.raw_get(obj: self, user: nil, extra: nil, only: only)
      @raw_versions
    end

    def versions(user: nil, extra: nil, only: 'kept')
      @versions ||= ::Hist::Version.get(obj: self, user: nil, extra: nil, only: only)
      @versions
    end

    def raw_pendings(user: nil, extra: nil, only: 'kept')
      @raw_pendings ||= ::Hist::Pending.raw_get(obj: self, user: nil, extra: nil, only: only)
      @raw_pendings
    end

    def pendings(user: nil, extra: nil, only: 'kept')
      @pendings ||= ::Hist::Pending.get(obj: self, user: nil, extra: nil, only: only)
      @pendings
    end

    def diff_hist(ver:nil, pending: nil, type: :json, exclude: [], include: [], associations: nil, only_diffs: false)
      if ver.present?
        return Hist::ApplicationRecord.diff(obj: self, ver: ver, type: type, exclude: exclude, include: include, associations: associations, only_diffs: only_diffs)
      elsif pending.present?
        return Hist::ApplicationRecord.diff(obj: self, pending: pending, type: type, exclude: exclude, include: include, associations: associations, only_diffs: only_diffs)
      else
        raise 'Error: either ver or pending parameter is required for diff_history'
      end

    end

    def reload_hist
      @versions = nil
      @raw_versions = nil
      @pendings = nil
      @raw_pendings = nil
    end

    def reload
      reload_hist
      super
    end

    def hist_json(exclude: [], include: [], associations: nil)
      Hist::ApplicationRecord.to_json(obj: self, exclude: exclude, include: include, associations: associations)
    end

    # Attributes essentially... defined as methods as just don't want to save this data as part of the JSON hash
    def ver_id
      @ver_id
    end

    def ver_id=(value)
      @ver_id = value
    end

    def pending_id
      @pending_id
    end

    def pending_id=(value)
      @pending_id = value
    end

    def hist_created_at=(value)
      @hist_created_at = value
    end

    def hist_created_at
      @hist_created_at
    end

    def hist_whodunnit
      @hist_whodunnit
    end

    def hist_whodunnit=(value)
      @hist_whodunnit_user_set = true
      @hist_whodunnit = value
    end

    def system_hist_whodunnit=(value)
      @hist_whodunnit_user_set = false
      @hist_whodunnit = value
    end

    def hist_extra
      @hist_extra
    end

    def hist_extra=(value)
      @hist_whodunnit_extra_set = true
      @hist_extra = value
    end

    def system_hist_extra=(value)
      @hist_whodunnit_extra_set = false
      @hist_extra = value
    end

    def record_hist_whodunnit?
      @hist_whodunnit_user_set
    end

    def record_hist_extra?
      @hist_whodunnit_extra_set
    end


    # Type normally isn't part of the JSON output... try to fix that here...
    #def as_json(options={})
      #if self.type.present?
        #super(options.merge({:methods => :type}))
      #else
        #super
      #end
    #end
  end
end
