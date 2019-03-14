class Subject < ActiveRecord::Base
  has_many :doc_subjects, dependent: :destroy
  has_many :docs, :through=>:doc_subjects
end
