# These tests are for cases when previous stored data has been removed to ensure it isn't trying to load old models incorrectly. Additionally,
# this can test deleting versions.
require 'test_helper'

class DeletionTest < ActiveSupport::TestCase
  setup do

  end

  test "single model with associations {all: {}} should work with has_many and has_many_through when previous content is deleted" do
    class Doc < ActiveRecord::Base
      include ::Hist::Model
      around_save :hist_around_save

      has_hist associations: {all: {}}
      has_many :doc_files
      has_many :doc_subjects, dependent: :destroy
      has_many :subjects, :through=>:doc_subjects

      has_one :doc_extra
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

    class DocExtra < ActiveRecord::Base
      belongs_to :doc, optional: true
    end

    doc = Doc.new(title: 'doc1')
    doc.title = 'doc1'
    first_subject = Subject.create(label: 'subject1')
    first_file = DocFile.create(path: 'firstfile')
    first_doc_extra = DocExtra.new(extra_info: 'DocExtra1.') # Create can't work due to no doc_id.
    doc.doc_extra = first_doc_extra
    doc.doc_files << first_file
    doc.subjects << first_subject
    doc.save!

    second_subject = Subject.create(label: 'subject2')
    second_file = DocFile.create(path: 'secondfile')
    doc.subjects = [second_subject]
    doc.doc_files << second_file
    second_doc_extra = DocExtra.new(extra_info: 'DocExtra2.') # Create can't work due to no doc_id.
    doc.doc_extra = second_doc_extra
    doc.title = 'doc2'
    doc.save!

    assert(doc.doc_extra.extra_info == 'DocExtra2.', "Expected the current DocExtra to be DocExtra2. but got: #{doc.doc_extra.extra_info.to_s}")

    first_file.destroy!
    first_subject.destroy!
    first_doc_extra.destroy!

    doc.reload
    assert(doc.doc_extra.extra_info == 'DocExtra2.', "Expected the current DocExtra to be DocExtra2. but got: #{doc.doc_extra.extra_info.to_s}")

    # Numberic Checks
    assert(doc.doc_files.count == 1, "There should now only be one file for the current document but got: #{doc.doc_files.count.to_s}" )
    assert(doc.versions.count == 2, "There should be two versions but got #{doc.versions.count.to_s}" )
    assert(doc.versions.first.doc_files.size == 2, "The recorded recent version should still have two doc files but got: #{doc.versions.first.doc_files.count.to_s}" )
    assert(doc.versions.last.doc_files.size == 1, "The recorded first version should have only one file but got: #{doc.versions.first.doc_files.count.to_s}" )

    # Content Checks

    # Files
    assert(doc.doc_files[0].path == 'secondfile', "Expected the docfile path to be secondfile but got: #{doc.doc_files[0].path.to_s}")
    assert(doc.versions.first.doc_files[0].path == 'firstfile', "Expected the most recent versions's first file to be firstfile but got: #{doc.versions.first.doc_files[0].path.to_s}")
    assert(doc.versions.first.doc_files[1].path == 'secondfile', "Expected the most recent versions's second file to be secondfile but got: #{doc.versions.first.doc_files[1].path.to_s}")
    assert(doc.versions.last.doc_files[0].path == 'firstfile', "Expected the initial versions's file to be firstfile but got: #{doc.versions.last.doc_files[0].path.to_s}")

    # Subjects
    assert(doc.subjects[0].label == 'subject2', "Expected the current subject label to be subject2 but got: #{doc.subjects[0].label.to_s}")
    assert(doc.versions.first.subjects[0].label == 'subject2', "Expected the most recent version's subject to be subject1 but got: #{doc.versions.first.subjects[0].label.to_s}")
    assert(doc.versions.last.subjects[0].label == 'subject1', "Expected the initial versions's subject to be subject1 but got: #{doc.versions.last.subjects[0].label.to_s}")

    # DocExtra
    assert(doc.doc_extra.extra_info == 'DocExtra2.', "Expected the current DocExtra to be DocExtra2. but got: #{doc.doc_extra.extra_info.to_s}")
    assert(doc.versions.first.doc_extra.extra_info == 'DocExtra2.', "Expected the most recent version's DocExtra to be DocExtra2. but got: #{doc.versions.first.doc_extra.extra_info.to_s}")
    assert(doc.versions.last.doc_extra.extra_info == 'DocExtra1.', "Expected the initial versions's DocExtra to be DocExtra1. but got: #{doc.versions.last.doc_extra.extra_info.to_s}")
  end

  teardown do

  end
end
