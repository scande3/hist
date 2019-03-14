require 'rails/generators'

module Hist
  class InitializerGenerator < Rails::Generators::Base

    source_root File.expand_path('../templates', __FILE__)

    desc 'Model Generator Hist Engine'

    def config_initializer_copy
      copy_file 'init/hist.rb', 'config/initializers/hist.rb' unless File::exists?('config/initializers/hist.rb')
    end

  end
end
