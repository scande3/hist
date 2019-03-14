# These tests are for cases when previous stored data has been removed to ensure it isn't trying to load old models incorrectly. Additionally,
# this can test deleting versions.
require 'test_helper'

module MigrationTests
  class HasManyTest < ActiveSupport::TestCase
    setup do
      if ActiveRecord::Base.connection.column_exists?(:doc_files, :temporary)
        ActiveRecord::Migration.remove_column :doc_files, :temporary
      end
    end

    # This tests adding a column and deleting a column since a version was made.
    # ActiveRecord::Migration.remove_column :table_name, :column_name
    test "single model with associations {all: {}} should work with has_many and has_many_through when columns are added and deleted" do
      class Doc < ActiveRecord::Base
        include ::Hist::Model
        around_save :hist_around_save

        has_hist associations: {all: {}}

        has_many :doc_files
      end

      class DocFile < ActiveRecord::Base
        belongs_to :doc, optional: true
      end

      doc = Doc.new(title: 'doc1')
      doc_file = DocFile.new(path: 'mypath1') # Create can't work due to no doc_id.
      doc.doc_files = [doc_file]
      doc.save!

      # Add the new column and reset the schema
      ActiveRecord::Migration.add_column :doc_files, :temporary, :string
      DocFile.connection.schema_cache.clear!
      DocFile.reset_column_information
      Doc.connection.schema_cache.clear!
      Doc.reset_column_information

      doc_file.reload
      doc_file.temporary = "They have cookies!"
      doc_file.save!

      doc.reload
      doc.save!

      # Do some light tests of this state
      assert(doc.doc_files[0].temporary == "They have cookies!", "Expected to get cookies but instead got: #{doc.doc_files[0].temporary.to_s}")
      assert(doc.versions.first.doc_files[0].temporary == "They have cookies!", "Expected to get cookies for recent version but instead got: #{doc.versions.first.doc_files[0].temporary.to_s}")
      assert(doc.versions.last.doc_files[0].temporary == "They have cookies!", "Default for a version missing a field is to load the current value but got: #{doc.versions.last.doc_files[0].temporary.to_s}")
      # Should be a setting for the below behavior?
      #assert(doc.versions.last.doc_files[0].temporary.blank?, "Expected first version to lack doc_extra.temporary but got: #{doc.versions.last.doc_files[0].temporary.to_s}")

      # Remove the new column
      ActiveRecord::Migration.remove_column :doc_files, :temporary
      DocFile.connection.schema_cache.clear!
      DocFile.reset_column_information
      Doc.connection.schema_cache.clear!
      Doc.reset_column_information

      # Sleep is to prevent cases where it doesn't seem to complete the refresh time by document load...
      sleep 0.2
      doc.reload

      # Do some light tests of this state.
      assert_raise(NoMethodError) { doc.doc_files[0].temporary }
      assert(doc.versions.first.doc_files[0].path == 'mypath1', "Normal history access caused an error and got: #{doc.versions.first.doc_files[0].path}")
      assert(doc.versions.last.doc_files[0].path == 'mypath1', "Normal history access caused an error and got: #{doc.versions.last.doc_files[0].path}")
      #assert(doc.versions.first.doc_files[0].temporary == 'They have cookies!', "Expected history to still have the temporary value but got: #{doc.versions.first.doc_files[0].temporary}")
      assert_raise(NoMethodError) { doc.versions.first.doc_files[0].temporary }
      assert_raise(NoMethodError) { doc.versions.last.doc_files[0].temporary }
    end

    teardown do
      if ActiveRecord::Base.connection.column_exists?(:doc_files, :temporary)
        ActiveRecord::Migration.remove_column :doc_files, :temporary
      end
    end
  end
end
