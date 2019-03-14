This file is mainly for the original creator and can be ignored. Failed
code snippets that are just here in case I need to go back
to trying one of these approaches.

    # This should work for associations for encode... but only in the rails console. It doesn't function from within this
    # gem. Leaving it commented here in case the new method causes issues.
    # Include type in the associations to support STI
```ruby
    all_associations = obj.class.reflect_on_all_associations(:has_many)
    fixed_associations = []

    all_associations = obj.class.reflect_on_all_associations(:has_many)
    associations.each do |assoc|
      h = {}
      row = all_associations.select{ |row| row.name == assoc }

      if row[0].klass.present? && row[0].klass.method_defined?(:type)
        h[assoc] = {methods: :type}
      else
        h[assoc] = {}
      end

      fixed_associations << h
    end
```

    # Another broken way that should work...
```ruby
    fixed_associations = []

    associations.each do |assoc|
      h = {}
      puts 'Assoc: ' + assoc.to_s + " and klass: " + obj.send(assoc).klass.to_s
      puts 'Recult of method_defined: ' + obj.send(assoc).klass.method_defined?(:type).to_s
      if obj.send(assoc).klass.method_defined?(:type)
        h[assoc] = {methods: :type}
      else
        h[assoc] = {}
      end

      fixed_associations << h
    end
```

    # Failed attempt at forcing save
```ruby
          if Hist.model(obj: obj).constantize.hist_config.update_associations_on_save(klass: obj.class, assoc: k)
            puts 'route 1'
            if detail.class == ActiveRecord::Reflection::BelongsToReflection
              version_set.save! unless version_set.nil?
            else
              current_obj.send(k).each do |ex|
                current_obj.send(k).delete(ex)
              end
              version_set.each do |ex|
                puts 'EX is: ' + ex.to_s
                ex.save!
                current_obj.send(k) << ex
              end
            end
          end  
```
