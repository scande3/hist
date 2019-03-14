$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "hist/versionnumber"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "hist"
  s.version     = Hist::VERSIONNUMBER
  s.authors     = ["Steven Anderson", "Akamai Technologies"]
  s.email       = ["stevencanderson@hotmail.com"]
  s.homepage    = "https://github.com/scande3/hist"
  s.summary     = "Detailed version tracking of an item and its associations in Ruby on Rails. Based on Papertrail."
  s.description = "Detailed version tracking of an item and its associations in Ruby on Rails. Based on Papertrail but with better association handling."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5"
  s.add_dependency 'ace-rails-ap'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'discard', '~> 1'

  s.add_development_dependency "sqlite3"
end
