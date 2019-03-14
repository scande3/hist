require 'rails/generators'

module Hist
  class InstallGenerator < Rails::Generators::Base

    source_root File.expand_path('../templates', __FILE__)

    desc "InstallGenerator Hist Engine"

    def copy_initializers
      generate 'hist:initializer'
    end

    def generate_migration_scripts
      generate 'hist:db'
    end

    def insert_to_routes
      generate 'hist:routes'
    end

    def bundle_install
      Bundler.with_clean_env do
        run 'bundle install'
      end
    end

  end
end
