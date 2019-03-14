module Hist
  class HistConfig

    def initialize(associations:nil, model:, max_versions:, max_pendings:, include: [], exclude: [], auto_version:)
      @associations = associations
      @model = model
      @max_versions = max_versions
      @max_pendings = max_pendings
      @include = include
      @exclude = exclude
      @auto_version = auto_version
    end

    def auto_version
      @auto_version
    end

    def max_versions
      @max_versions
    end

    def max_pendings
      @max_pendings
    end

    def include
      @include
    end

    def exclude
      @exclude
    end

    def model
      @model
    end

    # Support STI
    def associations(obj: nil, klass: nil, exclude_through:false)
      return [] if @associations.nil?

      klass = obj.class if obj.present?
      klass = self.model.constantize if klass.nil?

      if @associations.present?
        if @associations.has_key? :all
          return all_associations(klass: klass, exclude_through: exclude_through)
        elsif @associations.has_key? :has_many
          return all_associations(klass: klass, type: :has_many, exclude_through: exclude_through)
        elsif @associations.has_key? :belongs_to
          return all_associations(klass: klass,type: :belongs_to, exclude_through: exclude_through)
        end
      end

      return_assocs = []
      @associations.each do |k, _|
        return_assocs << (klass.reflect_on_all_associations.select { |a| a.name == k})[0] if valid_association(klass: klass, assoc: k, exclude_through: exclude_through)
      end

      return_assocs
    end

    def valid_association(klass:, assoc:, exclude_through:false)
      all_assocs = klass.reflect_on_all_associations
      association_details = all_assocs.select { |a| a.name == assoc }[0]

      if association_details.present?
        if exclude_through and association_details.class == ActiveRecord::Reflection::HasManyReflection
          through_associations = all_assocs.select { |assoc| assoc.class == ActiveRecord::Reflection::ThroughReflection}
          if through_associations.present?
            assoc_check = through_associations.select { |assoc| assoc.options[:through] == assoc }
            return false if assoc_check.present?
          end
        end
        return true
      end
      return false
    end

    def all_associations(klass:, type: nil, exclude_through:false)
      if type.nil?
        associations = klass.reflect_on_all_associations
      else
        associations = klass.reflect_on_all_associations(type)
      end

      if exclude_through
        through_associations = associations.select { |assoc| assoc.class == ActiveRecord::Reflection::ThroughReflection}

        through_associations.each do |t_assoc|
          assoc_to_delete = associations.select { |assoc| assoc.name == t_assoc.options[:through]}
          associations.delete(assoc_to_delete[0]) if assoc_to_delete.present?
        end
      end

      associations
    end

    def update_associations_on_save(klass:, assoc:)
      if @associations.blank?
        return false
      end

      if @associations.has_key? :all
        return true if @associations[:all][:update_associations_on_save].nil? || @associations[:all][:update_associations_on_save]
      elsif @associations.has_key? :has_many
        return true if @associations[:has_many][:update_associations_on_save].nil? || @associations[:has_many][:update_associations_on_save]
      elsif @associations.has_key? :belongs_to
        return true if @associations[:belongs_to][:update_associations_on_save].nil? || @associations[:belongs_to][:update_associations_on_save]
      end

      item = @associations[assoc]
      return true if !item.nil? and (item[:update_associations_on_save].nil? || item[:update_associations_on_save])

      return false
    end

    def options
      @options
    end

  end

end
