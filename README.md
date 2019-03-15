# Hist
This gem is designed to allow one to record version history of an object. Additionally, it has support to store
"pending" objects.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'hist'
```

And then execute:
```bash
$ bundle
```

Finally run the generator with:
```bash
rails g hist:install
```

## Usage

### Setup steps:

#### Models

1. Add the following to your model:
   ```ruby
     include ::Hist::Model

     has_hist associations: {all: {}}
   ```

2. Then do one of the following two methods to records your versions:

    1a. Add the following to your model to save anytime you call this object's save method:
      ```ruby
        around_save :hist_around_save
      ```

    2b. Manually call the following on cases you want to create a version: `obj.hist_save_actions`.
    An example of this might be the follow:

      ```ruby
        around_save :my_custom_save

        def my_custom_save
            self.class.transaction do
              yield

              if self.saved_change_to_body?
                self.hist_save_actions
              end
        end
      ```

#### Pending Versions
This is extremely experimental and still being completed. Bugs are to be expected here for the next few weeks. To do a version, one would do:
```ruby
  obj = MyObj(params[:id])
  Hist::Pending.start_pending do
     <updates to object>
  end
  obj.record_pending # or with extra fields of obj.record_pending(user: username, extra: extra_string_info)
```

In the future, when you load that object, it will have pending versions:
```ruby
  obj.pendings
```

To approve a pending object, one would do:
```ruby
  ActiveRecord::Base.transaction do
    pending = Hist::Pending.find(params[:pending_id])
    obj_reified = pending.reify
    obj_reified.save!
    pending.destroy!
  end
```

To delete a pending object, one would do:
```ruby
  pending = Hist::Pending.find(params[:pending_id])
  pending.destroy!
```

#### Views (comparison feature)

1. Mount the Hist engine in your routes.rb:
   ```ruby
     mount Hist::Engine => '/hist'
   ```

2. Inside of your layout or just on a view page, add the following:
   ```ruby
     <%= render partial: 'partials/hist/modal.html.erb' %>
   ```

3. Have Bootstrap installed in your application with the popover javascript available.

4. Have the Ace Editor installed which is essentially:
    Inside of your Gemfile:
    ```ruby
      gem 'ace-rails-ap'
    ```

    Inside of your app/assets/javascripts/application.js:
    ```javascript
      //= require ace-rails-ap
      //= require ace/mode-json
      //= require ace/mode-yaml
      //= require ace/mode-text
    ```

5. For the diff views, one needs to simply use a link on their page in the format (see API for more examples):
   ```ruby
     # For Versions
     <%= link_to "Diff Content", hist.diff_versions_path(left_id: ver_id, right_id: 'current'), remote: true %></li>

     # For Pendings
     <%= link_to "Diff Content", hist.diff_pendings_path(left_id: pending_id, right_id: 'current'), remote: true %></li>
   ```

#### JSON output of your object
If you just want the JSON hash output of your object, you can do one of the below two options:
```ruby
  obj.hist_json

  Hist::Version.encode(obj: myobj)
```

### Some API documentation

The following will assume an ActiveRecord model of "Model" loaded as an instance "obj".
You model will now have the following:
```ruby
  obj.versions # All versions
  obj.pendings # All Pendings
  obj.raw_versions # All versions as a Hist::Version object
  obj.raw_pendings # All pendings as a Hist::Pending object
  obj.record_version # Record a version
  obj.record_pending # Record a future version
  obj.reload_hist # Reload cached versions and histories if this would have changed
  obj.hist_json(exclude: [], include: [], associations: nil) # Hist JSON version of this object
  obj.ver_id # The version ID of the object if this is a version
  obj.pending_id # The pending ID of the object if this is pending
  obj.hist_whodunnit # A string value of who did it if this is a Hist object
  obj.hist_extra # A string extra value if this is a Hist object

  # The below needs to be fixed in its implementation...
  Model.hist_new_pendings(user: nil, extra: nil, only: 'kept') # All pending new objects for this model. The 'only'
  # field is used to only show undiscarded entries. Other valid values are: 'all' and 'discarded'.

  Model.hist_all_pendings
```

Many of these take extra arguments. For instance, to record with a user and extra information, do:
```ruby
  obj.record_version(user: myuser, extra: some_dept)
```

For the diff views, one needs to simply use a link on their page in the format:
```ruby
  # For Versions
  <%= link_to "Diff Content", hist.diff_versions_path(left_id: ver_id, right_id: 'current'), remote: true %></li>

  # For Pendings
  <%= link_to "Diff Content", hist.diff_pendings_path(left_id: pending_id, right_id: 'current'), remote: true %></li>
```

Note that "current" is a special keyword to use the current version of the object. There are also various optional fields
for these links. Some examples:

```ruby
  # Test mode with a path to an ocr field
  <%= link_to "Diff Content", hist.diff_versions_path(left_id: ver.ver_id, right_id: 'current', field_path: '["doc_files"].first["ocr"]', mode: :text), remote: true %><

  # JSON with certain fields excluded
  <%= link_to "Diff Metadata", hist.diff_versions_path(left_id: ver.ver_id, right_id: 'current', exclude: [:ocr, :id, :user_id], mode: :json), remote: true %>

  # YAML based output (default mode)
  <%= link_to "Diff Metadata", hist.diff_versions_path(left_id: ver.ver_id, right_id: 'current', mode: :yaml), remote: true %>

  # Exclude hashes that are not different
  <%= link_to "Only Differences", hist.diff_versions_path(left_id: ver.ver_id, right_id: 'current', only_diffs: true), remote: true %>
```

### Configuration

#### Initializer

There is a `config/initializers/hist.rb` file that was generated that simply sets some default fields to exclude in the
differential views. Feel free to customize these defaults.

#### Model options
`has_hist` supports the followng currently:
* `associations`: A hash of associations to save with the object (ie. `associations: {a1: {}, a2: {}}`). The default is nil
(no associations). It supports special keys of `:all`, `:has_many`, and `:belongs_to` in the first slot (ie.
`associations: {belongs_to: {}}` will only version belongs_to associations). The inner hash is for more settings. These
are:
  * `:update_associations_on_save` -> Defaults to true. This means that if you save a pending or version object with the
  `save` method, then overwrite those relationships with whatever values that pending or versioned object had. If set to
  false, then the final object from saving a pending or versioned object will use the latest values of that association if
  it still exists on the current object. An example of setting this to false is: `associations: {all: {update_associations_on_save: false}}`

* `max_versions`: The maximum amount of versions to store of the object. The default is infinity.

* `max_pendings`: The maximum amount of processed pending items to keep. This works differently from max_versions in
that once you approve a pending object, it marks it as "discarded". It will keep the number of discarded pending objects
up to this amount but one will always have infinity pending submissions. The default to keep of discarded pending objects
is infinity.

* `auto_version`: If this is set to true, then auto-create a version upon a "save" action. If false, you will need to
call `obj.record_hist(user: nil, extra: nil)` whenever a new version should be created. Default for this is true.

## Known Issues

Some ActiveRecord methods will cause a database query that will retrieve current data rather than your stubbed out version
data. To work around these (and these are faster anyway):

1. Use `size` rather than `count` for the number of elements in an association.

2. Use `sort_by` over other sorting methods. IE. `@doc.doc_files.sort_by{|f| f.order}`

3. Use `select` to pick a certain item in your association. IE. `@repo.repo_images.select{ |img| img.order == params[:image_no].to_i }`

## Testing

Once the project is checked out, go to the `test/dummy` directory and run:
```ruby
  RAILS_ENV="test" rake db:migrate
```

One can then do: `rails test` from the hist root (outside the test/dummy directory).

To use the console to test commands, go to `test/dummy` and run `rake db:migrate`. Then one can do `rails c`.

TODO is to add some views of the comparison feature into the `test/dummy` application.
