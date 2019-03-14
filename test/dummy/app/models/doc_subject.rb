class DocSubject < ActiveRecord::Base
  belongs_to :doc
  belongs_to :subject
end
