class DocFile < ActiveRecord::Base
  belongs_to :doc, optional: true
end
