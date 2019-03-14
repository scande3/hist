class DocExtra < ActiveRecord::Base
  belongs_to :doc, optional: true
end
