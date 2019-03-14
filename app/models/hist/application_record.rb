module Hist
  class ApplicationRecord < ActiveRecord::Base
    include Discard::Model

    self.abstract_class = true

    # This could be done better...
    def self.raw_get(obj:, user: nil, extra: nil, only: 'kept')
      if user.nil?
        if extra.nil?
          versions = self.where(model: Hist.model(obj: obj), obj_id: obj.id).send(only).reverse
        else
          versions = self.where(model: Hist.model(obj: obj), obj_id: obj.id, extra: extra).send(only).reverse
        end

      else
        if extra.nil?
          # .to_s to support either user object or username
          versions = self.where(model: Hist.model(obj: obj), obj_id: obj.id, whodunnit: user.to_s).send(only).reverse
        else
          # .to_s to support either user object or username
          versions = self.where(model: Hist.model(obj: obj), obj_id: obj.id, whodunnit: user.to_s, extra: extra).send(only).reverse
        end
      end

      versions
    end

    def self.get(obj:, user: nil, extra: nil, only: 'kept')
      hash_versions = self.raw_get(obj: obj, user: user, extra: extra, only: only)
      versions = hash_versions.map {|v| v.reify }
      versions
    end

    def self.encode(obj:, associations: nil)
      if associations.nil?
        associations = Hist.model(obj:obj).constantize.hist_config.associations(obj: obj).map(&:name)
      else
        associations.each do |assoc|
          unless Hist.model(obj:obj).constantize.hist_config.valid_association(klass: obj.class, assoc: assoc)
            associations.delete(assoc)
          end
        end
      end


      if associations.nil?
        if obj.class.attribute_names.include?("type")
          encoded = ActiveSupport::JSON.encode obj, methods: :type
        else
          encoded = ActiveSupport::JSON.encode obj
        end
      else
        # Include type in the associations to support STI
        fixed_associations = []

        associations.each do |assoc|
          h = {}
          h[assoc] = {}
          # FIXME: This only works if the type file isn't custom.
          unless obj.send(assoc).nil?
            if obj.send(assoc).respond_to?("klass") && obj.send(assoc).klass.attribute_names.include?("type")
              h[assoc] = {methods: :type}
            elsif obj.send(assoc).class.respond_to?("attribute_names") && obj.send(assoc).class.attribute_names.include?("type")
              h[assoc] = {methods: :type}
            end
          end

          fixed_associations << h
        end
        if obj.class.attribute_names.include?("type")
          encoded = ActiveSupport::JSON.encode obj, include: fixed_associations, methods: :type
        else
          encoded = ActiveSupport::JSON.encode obj, include: fixed_associations
        end
      end

      encoded
    end

    def self.decode(obj:, associations: nil)
      if obj.class == Hash
        decoded = ActiveSupport::JSON.decode(obj: obj, associations: associations)
      else
        decoded = ActiveSupport::JSON.decode(encode(obj: obj, associations: associations))
      end

      decoded
    end

    def self.put(obj:, user: nil, extra: nil, exclude: [])
      encoded = encode(obj: obj)

      # Remove excluded fields... might be a better way to do this.
      decoded = ActiveSupport::JSON.decode encoded
      exclude.each do |attr|
        decoded.delete(attr)
      end

      encoded = ActiveSupport::JSON.encode decoded

      # Check to see if the last version is already saved... don't duplicate
      # Potential flaw with version caching to watch out for
      if obj.raw_versions.present?
        return obj if encoded == obj.raw_versions.first.data
      end

      if user.nil?
        if extra.nil?
          return self.create(model: Hist.model(obj: obj), obj_id: obj.id, data: encoded)
        else
          return self.create(model: Hist.model(obj: obj), obj_id: obj.id, extra: extra.to_s, data: encoded)
        end

      else
        if extra.nil?
          # .to_s to support either user object or username
          return self.create(model: Hist.model(obj: obj), obj_id: obj.id, whodunnit: user.to_s, data: encoded)
        else
          # .to_s to support either user object or username
          return self.create(model: Hist.model(obj: obj), obj_id: obj.id, whodunnit: user.to_s, extra: extra.to_s, data: encoded)
        end

      end
    end

    # Need to add exclude[ActiveRecord::Reflection::ThroughReflection]
    def self.to_json(obj:, exclude: [], include: [], associations: nil)
      if associations.nil?
        associations = Hist.model(obj:obj).constantize.hist_config.associations(obj: obj, exclude_through: true).map(&:name)
      else
        associations.each do |assoc|
          unless Hist.model(obj:obj).constantize.hist_config.valid_association(klass: obj.class.base_class, assoc: assoc)
            associations.delete(assoc)
          end
        end
      end
      assoc_to_s = associations.map { |val| val.to_s }

      obj_hash = decode(obj: obj, associations: associations)

      if exclude.present?
        exclude.each do |e|
          obj_hash = remove_key(h: obj_hash, val: e.to_s)
        end
      end

      if include.present?
        include.map! { |val| val.to_s }
        obj_hash = include_keys(h: obj_hash, vals: include, associations: assoc_to_s)
      end

      # Only include associations we have configured
      #Hist.model(obj:obj).constantize.hist_config.all_associations(klass: obj.class).each do |assoc|
        #obj_hash.delete(assoc.to_s) unless associations.include?(assoc) || associations.include?(assoc.to_s)
      #end

      obj_hash
    end

    def self.to_yaml(obj:, exclude: [], include: [], associations: nil)
      YAML.dump(self.to_json(obj: obj, exclude: exclude, include: include, associations: associations))
    end

    def self.only_hash_diffs(h1: {}, h2: {})
      return_h1 = {}
      return_h2 = {}

      h1.each_key do |k|
        if h1[k] != h2[k]
          return_h1[k] = h1[k]
          return_h2[k] = h2[k]
        end
      end

      {h1: return_h1, h2: return_h2}
    end

    def self.include_keys(h: {}, vals: [], associations: [])
      return_h = {}
      h.each_key do |k|
        if vals.include?(k.to_s)
          return_h[k] = h[k]
        elsif associations.include? k.to_s
          return_h[k] = []
          h[k].each_with_index do |_, idx|
            return_h[k][idx] = {}
            h[k][idx].each_key do |k2|
              if vals.include? k2.to_s
                return_h[k][idx][k2] = h[k][idx][k2]
              end
            end
          end
        end
      end
      return_h
    end

    def self.remove_key(h: {}, val: '')
      #h = passed_h.clone
      h.except! val
      h.each_key do |k|
        if h[k].class == Array
          h[k].each_with_index { |_, idx|
            if h[k][idx].class == Hash
              h[k][idx].except! val
            end
          }
        elsif h[k].class == Hash
          h[k].except! val
        end
      end
    end

    def reify
      #associations = self.model.constantize.reflect_on_all_associations(:has_many).map(&:name)

      decoded = ActiveSupport::JSON.decode self.data
      decoded.stringify_keys!

      # Potential issue when changing STI class when removing associations... how to get all_associations for all STI?
      if decoded["type"].present?
        associations = self.model.constantize.hist_config.associations(klass: decoded["type"].constantize).map(&:name)
        all_associations = self.model.constantize.hist_config.all_associations(klass: decoded["type"].constantize).map(&:name)
      else
        associations = self.model.constantize.hist_config.associations(klass: self.model.constantize).map(&:name)
        all_associations = self.model.constantize.hist_config.all_associations(klass: self.model.constantize).map(&:name)
      end

      associations_to_process = {}

      # Can't instantiate with the association params... need to process those once the object is up
      all_associations.each do |assoc|
        if decoded.has_key? assoc.to_s
          if associations.include? assoc
            associations_to_process.merge!(decoded.slice(assoc.to_s))
          end

          decoded.delete(assoc.to_s)
        end
      end

      #obj = self.model.constantize.new(decoded)
      if decoded["id"].present? && self.model.constantize.exists?(id: decoded["id"])
        obj = self.model.constantize.find(decoded["id"])
        # If a version attribute no longer exists, will error at: https://github.com/rails/rails/blob/v5.2.0/activemodel/lib/active_model/attribute_assignment.rb
        # So must verify each key and drop it otherwise... in the future, update the version to drop that key possibly?
        decoded.each do |k, _|
          setter = :"#{k}="
          unless obj.respond_to?(setter)
            decoded.delete(k)
          end
        end

        obj.assign_attributes(decoded)
      else
        obj = self.model.constantize.new(decoded)
      end

      associations_to_process.each do |k,v|
        assoc_collection = []
        # Has Many
        if v.class == Array
          v.each do |d|
            if d["id"].present? && obj.class.reflect_on_association(k).class_name.constantize.exists?(id: d["id"])
              a = obj.class.reflect_on_association(k).class_name.constantize.find(d["id"])
              # If a version attribute no longer exists, will error at: https://github.com/rails/rails/blob/v5.2.0/activemodel/lib/active_model/attribute_assignment.rb
              # So must verify each key and drop it otherwise... in the future, update the version to drop that key possibly?
              d.each do |k2, _|
                setter = :"#{k2}="
                unless a.respond_to?(setter)
                  d.delete(k2)
                end
              end

              a.assign_attributes(d)
              assoc_collection << a
            else
              assoc_collection << obj.class.reflect_on_association(k).class_name.constantize.new(d)
            end
          end
          obj.send(k).proxy_association.target = assoc_collection
          # Belongs To
        else
          if v["id"].present? && obj.class.reflect_on_association(k).class_name.constantize.exists?(id: v["id"])
            a = obj.class.reflect_on_association(k).class_name.constantize.find(v["id"])
            # If a version attribute no longer exists, will error at: https://github.com/rails/rails/blob/v5.2.0/activemodel/lib/active_model/attribute_assignment.rb
            # So must verify each key and drop it otherwise... in the future, update the version to drop that key possibly?
            v.each do |k2, _|
              setter = :"#{k2}="
              unless a.respond_to?(setter)
                v.delete(k2)
              end
            end

            a.assign_attributes(v)
            assoc_collection = a
          else
            assoc_collection = obj.class.reflect_on_association(k).class_name.constantize.new(v)
          end

          without_persisting(assoc_collection) do
            obj.send("#{k}=".to_sym, assoc_collection)
          end

        end

      end

      if self.class == Hist::Version
        obj.ver_id = self.id
      elsif self.class == Hist::Pending
        obj.pending_id = self.id
      end

      obj.hist_whodunnit = self.whodunnit
      obj.hist_extra = self.extra
      obj.hist_created_at = self.created_at

      obj
    end

    # From: https://github.com/westonganger/paper_trail-association_tracking/blob/5ed8cfbfa48cc773cc8a694dabec5a962d9c6cfe/lib/paper_trail_association_tracking/reifiers/has_one.rb
    # Temporarily suppress #save so we can reassociate with the reified
    # master of a has_one relationship. Since ActiveRecord 5 the related
    # object is saved when it is assigned to the association. ActiveRecord
    # 5 also happens to be the first version that provides #suppress.
    def without_persisting(record)
      if record.class.respond_to? :suppress
        record.class.suppress { yield }
      else
        yield
      end
    end

    # Many-To-Many ID changes. This causes a problem with historic many-to-many saving.
    def self.fix_save_associations(obj:)

      associations = Hist.model(obj: obj).constantize.hist_config.associations(klass: obj.class.base_class, exclude_through: true).map(&:name)
      association_details = Hist.model(obj: obj).constantize.hist_config.all_associations(klass: obj.class.base_class, exclude_through: true)

      current_obj = obj.class.find(obj.id)

      # For has_many
      associations.each do |k,v|
        detail = association_details.select { |a| a.name == k}[0]
        existing = current_obj.send(k)
        version_set = obj.send(k)

        unless detail.class == ActiveRecord::Reflection::BelongsToReflection || detail.class == ActiveRecord::Reflection::HasOneReflection
          existing.each do |ex|
            unless version_set.pluck(:id).include? ex.id
              current_obj.send(k).delete(ex)
            end
          end

          if Hist.model(obj: obj).constantize.hist_config.update_associations_on_save(klass: obj.class, assoc: k)
            version_set.each do |ex|
              ex.save!

              unless existing.pluck(:id).include? ex.id
                current_obj.send(k) << ex
              end
            end
          else
            version_set.each do |ex|
              unless existing.pluck(:id).include? ex.id
                ex_obj = ex.class.find(ex.id)
                if ex_obj.present?
                  current_obj.send(k) << ex_obj
                else
                  ex.save!
                  current_obj.send(k) << ex
                end

              end
            end
          end

        end
      end

      current_obj.reload
      current_obj

    end

  end
end
