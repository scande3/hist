require 'rails/generators'

module Hist
  class RoutesGenerator < Rails::Generators::Base

    source_root File.expand_path('../templates', __FILE__)

    desc """
  This generator makes the following changes to your application:
   1. Injects route declarations into your routes.rb
         """

    # Add auditsdb to the routes
    def inject_hist_routes
      unless IO.read("config/routes.rb").include?('Hist::Engine')
        marker = 'Rails.application.routes.draw do'
        insert_into_file "config/routes.rb", :after => marker do
          %q{
  # routes for Hist
  mount Hist::Engine => '/hist'
}
        end

      end
    end


  end
end
