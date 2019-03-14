require "singleton"

module Hist
  class Config
    include Singleton

    attr_accessor :default_diff_exclude
  end

end
