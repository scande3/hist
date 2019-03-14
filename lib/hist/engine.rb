require 'discard'
require 'digest'

module Hist
  class Engine < ::Rails::Engine
    isolate_namespace Hist

    engine_name 'hist'

    config.autoload_paths += %W(
    #{config.root}/app/controllers/concerns
      #{config.root}/app/models/concerns
      #{config.root}/lib/form_builders
      #{config.root}/app/workers
    )

    initializer "hist" do |app|
      # use a proc instead of a string
      app.config.assets.precompile << proc { |path| path =~ /\hist\/.+\.(eot|svg|ttf|woff|png|css|js)\z/ }
    end

    # Could we just run "load_tasks" here instead?
    # This makes our rake tasks visible.
    rake_tasks do
      Dir.chdir(File.expand_path(File.join(File.dirname(__FILE__), '..'))) do
        Dir.glob(File.join('tasks', '*.rake')).each do |railtie|
          load railtie
        end
      end
    end

  end
end
