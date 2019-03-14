class Doc < ActiveRecord::Base
  include ::Hist::Model
  #after_save :after_save_actions
  around_save :hist_around_save

  #has_hist associations: {doc_files: {}}
  has_hist associations: {all: {update_associations_on_save: false}}

  # Normal file relationships
  has_many :doc_files

  # Has Many Through
  has_many :doc_subjects, dependent: :destroy
  has_many :subjects, :through=>:doc_subjects

  # Belongs To relationship
  belongs_to :collection, optional: true

  # Has one relationship
  has_one :doc_extra


  def after_save_actions
    #record_version
    #hist_save_actions
  end
end
