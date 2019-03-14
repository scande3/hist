require 'test_helper'

class VersionTest < ActiveSupport::TestCase
  setup do

  end

  test "single model versions work fine" do
    class Doc < ActiveRecord::Base
      include ::Hist::Model
      around_save :hist_around_save

      has_hist
    end

    doc = Doc.create(title: 'doc1')
    doc.title = 'doc2'
    doc.save!

    assert(doc.versions.count == 2, "There should be two versions" )
    assert(doc.versions.last.title == 'doc1', "Oldest version should be called doc1")
    assert(doc.versions.first.title == 'doc2', "Newest version should be called doc2")
    assert(ActiveSupport::JSON.decode(doc.raw_versions.last.data).has_key?("id"), "ID should have been saved in versions")
    assert(doc.versions.first.hist_whodunnit.nil?, "hist_whodunnit should be nil")
    assert(doc.versions.first.hist_extra.nil?, "hist_extra should be nil")

    doc = Doc.first
    doc.title = 'doc3'
    doc.hist_whodunnit = 'Aliens'
    doc.hist_extra = 'From Mars'
    doc.save!

    assert(doc.versions.count == 3, "There should be three versions" )
    assert(doc.versions.first.title == doc.title, "Newest version should be called doc3")
    assert(doc.versions.first.hist_whodunnit == 'Aliens', "hist_whodunnit should be set to Alients")
    assert(doc.versions.first.hist_extra == 'From Mars', "hist_extra should be From Mars")
  end

  test "single model with association but not configured should not save association" do
    class Doc < ActiveRecord::Base
      include ::Hist::Model
      around_save :hist_around_save

      has_hist
      has_many :doc_files
    end

    class DocFile < ActiveRecord::Base
      belongs_to :doc, optional: true
    end


    doc = Doc.create(title: 'doc1')
    doc.title = 'doc2'
    doc.doc_files << DocFile.create(path: 'mypath')
    doc.save!

    assert(!ActiveSupport::JSON.decode(doc.raw_versions.last.data).has_key?("doc_files"), "Doc Files should not have been saved")
    assert(doc.versions.first.doc_files.first.path == 'mypath', 'Doc Files should give the latest')
  end

  test "single model with associations {all: {}} should work with has_many and has_many_through" do
    class Doc < ActiveRecord::Base
      include ::Hist::Model
      around_save :hist_around_save

      has_hist associations: {all: {}}
      has_many :doc_files
      has_many :doc_subjects, dependent: :destroy
      has_many :subjects, :through=>:doc_subjects
    end

    class DocFile < ActiveRecord::Base
      belongs_to :doc, optional: true
    end

    class DocSubject < ActiveRecord::Base
      belongs_to :doc
      belongs_to :subject
    end

    class Subject < ActiveRecord::Base
      has_many :doc_subjects, dependent: :destroy
      has_many :docs, :through=>:doc_subjects
    end

    doc = Doc.new(title: 'doc1')
    doc.title = 'doc1'
    doc.doc_files << DocFile.create(path: 'mypath')
    subject = Subject.create(label: 'subject1')
    doc.subjects << subject
    doc.save!

    assert(ActiveSupport::JSON.decode(doc.raw_versions.last.data).has_key?("doc_files"), "Doc Files should have doc_files key")
    assert(ActiveSupport::JSON.decode(doc.raw_versions.last.data).has_key?("subjects"), "Doc Files should have subjects key")

    subject.label = 'changed'
    subject.save!

    doc.reload
    doc.title = 'doc2'
    doc.doc_files << DocFile.create(path: 'secondfile')
    doc.save!

    assert(doc.versions.count == 2, "There should be two versions but got #{doc.versions.count.to_s}" )
    assert(doc.versions.last.doc_files.size == 1, "There should only be one doc file for the original version")
    assert(doc.versions.first.doc_files.size == 2, "There should only be two doc files for the latest version")
    assert(doc.versions[1].subjects[0].label == "subject1", "The old subject should load as the previous label")
    assert(doc.versions[0].subjects[0].label == "changed", "The latest version should have picked up the subject change")

    doc.title = 'doc3'
    doc.title = 'doc2'
    doc.save!
    assert(doc.versions.count == 2, "Should only be 2 versions as same data shouldn't make a new one. Got #{doc.versions.count.to_s}" )

    # Test updating to the last first version
    subject.label = 'changed_again'
    subject.save!

    doc.versions.last.save!
    doc.reload #FIXME perhaps?
    assert(doc.versions.count == 3, "There should be three versions now, got: #{doc.versions.count}" )
    assert(doc.title == 'doc1', "Title should be original one... got: #{doc.title}")
    assert(doc.doc_files.size == 1, "There should only be one doc_file again... got: #{doc.doc_files.size}")
    assert(doc.subjects.first.label == 'subject1', "Subject should be the original of 'subject1' but got: #{doc.subjects.first.label}")
    assert(doc.versions[0].subjects[0].label == 'subject1', "Subject should be what the new version is of 'subject1' but got: #{doc.versions[0].subjects[0].label}")

    # Test restoring to the one that used to exist before that version
    doc.versions[1].save
    doc.reload #FIXME perhaps?
    assert(doc.versions.count == 4, "There should be four versions now, got: #{doc.versions.count}" )
    assert(doc.title == 'doc2', "Title should be doc2 ... got: #{doc.title}")
    assert(doc.doc_files.size == 2, "There should only be two doc_files again... got: #{doc.doc_files.size}")
    assert(doc.subjects.first.label == 'changed', "Subject should be what this version had of 'changed' but got: #{doc.subjects.first.label}")
    assert(doc.versions[0].subjects[0].label == 'changed', "Subject should be 'changed' but got: #{doc.versions[0].subjects[0].label}")
  end

  test "single model with associations {all: {}} should work with has_one" do
    class Doc < ActiveRecord::Base
      include ::Hist::Model
      around_save :hist_around_save

      has_hist associations: {all: {}}
      has_one :doc_extra
    end

    class DocExtra < ActiveRecord::Base

    end

    doc = Doc.new(title: 'doc1')
    doc.title = 'doc1'
    doc_extra = DocExtra.new(extra_info: 'Document is best served with ketchup.') # Create can't work due to no doc_id.
    doc.doc_extra = doc_extra
    doc.save!

    assert(ActiveSupport::JSON.decode(doc.raw_versions.last.data).has_key?("doc_extra"), "Doc Files should have doc_extra key")

    doc_extra.extra_info = 'Document is best served with mustard.'
    doc_extra.save!

    doc.reload
    doc.title = 'doc2'
    doc.save!

    assert(doc.versions.count == 2, "There should be two versions but got #{doc.versions.count.to_s}" )
    assert(doc.versions[1].doc_extra.extra_info == "Document is best served with ketchup.", "The old docextra should load as the previous value")
    assert(doc.versions[0].doc_extra.extra_info == "Document is best served with mustard.", "The latest version should have picked up the docextra change")
  end

  test "single model with associations {all: {update_associations_on_save: false}} should work with has_many and has_many_through" do
    class Doc < ActiveRecord::Base
      include ::Hist::Model
      around_save :hist_around_save

      has_hist associations: {all: {update_associations_on_save: false}}
      has_many :doc_files
      has_many :doc_subjects, dependent: :destroy
      has_many :subjects, :through=>:doc_subjects
    end

    class DocFile < ActiveRecord::Base
      belongs_to :doc, optional: true
    end

    class DocSubject < ActiveRecord::Base
      belongs_to :doc
      belongs_to :subject
    end

    class Subject < ActiveRecord::Base
      has_many :doc_subjects, dependent: :destroy
      has_many :docs, :through=>:doc_subjects
    end

    doc = Doc.new(title: 'doc1')
    doc.title = 'doc1'
    doc.doc_files << DocFile.create(path: 'mypath')
    subject = Subject.create(label: 'subject1')
    doc.subjects << subject
    doc.save!

    assert(ActiveSupport::JSON.decode(doc.raw_versions.last.data).has_key?("doc_files"), "Doc Files should have doc_files key")
    assert(ActiveSupport::JSON.decode(doc.raw_versions.last.data).has_key?("subjects"), "Doc Files should have subjects key")

    subject.label = 'changed'
    subject.save!

    doc.reload
    doc.title = 'doc2'
    doc.doc_files << DocFile.create(path: 'secondfile')
    doc.save!

    assert(doc.versions.count == 2, "There should be two versions but got #{doc.versions.count.to_s}" )
    assert(doc.versions.last.doc_files.size == 1, "There should only be one doc file for the original version")
    assert(doc.versions.first.doc_files.size == 2, "There should only be two doc files for the latest version")
    assert(doc.versions[1].subjects[0].label == "subject1", "The old subject should load as the previous label")
    assert(doc.versions[0].subjects[0].label == "changed", "The latest version should have picked up the subject change")

    doc.title = 'doc3'
    doc.title = 'doc2'
    doc.save!
    assert(doc.versions.count == 2, "Should only be 2 versions as same data shouldn't make a new one. Got #{doc.versions.count.to_s}" )

    # Test updating to the last first version
    subject.label = 'changed_again'
    subject.save!

    doc.versions.last.save!
    doc.reload #FIXME perhaps?
    assert(doc.versions.count == 3, "There should be three versions now, got: #{doc.versions.count}" )
    assert(doc.title == 'doc1', "Title should be original one... got: #{doc.title}")
    assert(doc.doc_files.size == 1, "There should only be one doc_file again... got: #{doc.doc_files.size}")
    assert(doc.subjects.first.label == 'changed_again', "Subject should be the original of 'changed_again' but got: #{doc.subjects.first.label}")
    assert(doc.versions[0].subjects[0].label == 'changed_again', "Subject should be what was loaded to the object for the version of 'changed' but got: #{doc.versions[0].subjects[0].label}")

    # Test restoring to the one that used to exist before that version
    doc.versions[1].save!
    doc.reload #FIXME perhaps?
    assert(doc.versions.count == 4, "There should be four versions now, got: #{doc.versions.count}" )
    assert(doc.title == 'doc2', "Title should be doc2 ... got: #{doc.title}")
    assert(doc.doc_files.size == 2, "There should only be two doc_files again... got: #{doc.doc_files.size}")
    assert(doc.subjects.first.label == 'changed_again', "Subject should be what this version had of 'changed_again' but got: #{doc.subjects.first.label}")
    assert(doc.versions[0].subjects[0].label == 'changed_again', "Subject should be 'changed_again' but got: #{doc.versions[0].subjects[0].label}")
  end

  test "single model with associations {all: {}} should work with belongs_to" do
    class Collection < ActiveRecord::Base
      has_many :docs
    end

    class Doc < ActiveRecord::Base
      include ::Hist::Model
      around_save :hist_around_save

      has_hist associations: {all: {}}
      belongs_to :collection, optional: true
    end

    doc = Doc.new(title: 'doc1')
    doc.title = 'doc1'
    doc.save!

    assert(ActiveSupport::JSON.decode(doc.raw_versions.last.data).has_key?("collection_id"), "Doc should have a collection key")
    assert(ActiveSupport::JSON.decode(doc.raw_versions.last.data)["collection_id"].nil?, "Collection key should be nil")

    doc.collection = Collection.create(name: 'my collection')
    doc.save!

    assert(ActiveSupport::JSON.decode(doc.raw_versions.first.data).has_key?("collection"), "Doc should have a collection object")

    doc.title = "doc2"
    doc.collection.name = "my changed name"
    doc.save!

    assert(doc.versions[1].collection.name == 'my collection', "Doc collection should have name 'my collection' but got: #{doc.versions[1].collection.name}")
    assert(doc.versions[0].collection.name == 'my changed name', "Doc collection should have name 'my changed name' but got: #{doc.versions[0].collection.name}")

    doc.versions[1].save!
    doc.reload #FIXME?

    assert(doc.collection.name == "my collection", "Actual collection name should rename to 'my collection' but got: #{doc.collection.name}")

    doc.versions.last.save!
    doc.reload

    assert(doc.collection.nil?, "collection should be nil.")
    assert(doc.versions[0].collection.nil?, "First version should have a nil colection.")
    assert(doc.versions[1].collection.name == "my collection", "Second newest version should have a collection called 'my collection' but got: #{doc.versions[1].collection.name}")
  end



  teardown do

  end
end
