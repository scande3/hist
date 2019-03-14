# These tests are for cases when previous stored data has been removed to ensure it isn't trying to load old models incorrectly. Additionally,
# this can test deleting versions.
require 'test_helper'

module MigrationTests
  class HasOneTest < ActiveSupport::TestCase
    setup do
      if ActiveRecord::Base.connection.column_exists?(:doc_extras, :temporary)
        ActiveRecord::Migration.remove_column :doc_extras, :temporary
      end
    end

    # This tests adding a column and deleting a column since a version was made.
    # ActiveRecord::Migration.remove_column :table_name, :column_name
    test "single model with associations {all: {}} should work with has_many and has_many_through when columns are added and deleted" do
      class Doc < ActiveRecord::Base
        include ::Hist::Model
        around_save :hist_around_save

        has_hist associations: {all: {}}

        has_one :doc_extra
      end

      class DocExtra < ActiveRecord::Base
      end

      doc = Doc.new(title: 'doc1')
      doc_extra = DocExtra.new(extra_info: 'DocExtra1.') # Create can't work due to no doc_id.
      doc.doc_extra = doc_extra
      doc.save!

      # Add the new column and reset the schema
      ActiveRecord::Migration.add_column :doc_extras, :temporary, :string
      DocExtra.connection.schema_cache.clear!
      DocExtra.reset_column_information
      Doc.connection.schema_cache.clear!
      Doc.reset_column_information

      doc_extra.reload
      doc_extra.temporary = "They have cookies!"
      doc_extra.save!

      doc.reload
      doc.save!

      # Do some light tests of this state
      assert(doc.doc_extra.temporary == "They have cookies!", "Expected to get cookies but instead got: #{doc.doc_extra.temporary.to_s}")
      assert(doc.versions.first.doc_extra.temporary == "They have cookies!", "Expected to get cookies for recent version but instead got: #{doc.versions.first.doc_extra.temporary.to_s}")
      assert(doc.versions.last.doc_extra.temporary == "They have cookies!", "Expected to get cookies for initial version but instead got: #{doc.versions.last.doc_extra.temporary.to_s}")
      #FIXME: Add a setting to enable the below type of behavior
      #assert(doc.versions.last.doc_extra.temporary.blank?, "Expected first version to lack doc_extra.temporary but got: #{doc.versions.last.doc_extra.temporary.to_s}")

      # Remove the new column
      ActiveRecord::Migration.remove_column :doc_extras, :temporary
      DocExtra.connection.schema_cache.clear!
      DocExtra.reset_column_information
      Doc.connection.schema_cache.clear!
      Doc.reset_column_information

      # Sleep is to prevent cases where it doesn't seem to complete the refresh time by document load...
      sleep 0.2
      doc.reload

      # Do some light tests of this state.
      assert_raise(NoMethodError) { doc.versions.doc_extra.temporary }
      assert(doc.versions.first.doc_extra.extra_info == 'DocExtra1.', "Normal history access caused an error and got: #{doc.versions.first.doc_extra.extra_info}")
      assert(doc.versions.last.doc_extra.extra_info == 'DocExtra1.', "Normal history access caused an error and got: #{doc.versions.last.doc_extra.extra_info}")
      assert_raise(NoMethodError) { doc.versions.first.doc_extra.temporary }
      assert_raise(NoMethodError) { doc.versions.last.doc_extra.temporary }
    end

    teardown do
      if ActiveRecord::Base.connection.column_exists?(:doc_extras, :temporary)
          ActiveRecord::Migration.remove_column :doc_extras, :temporary
      end
    end
  end
end
