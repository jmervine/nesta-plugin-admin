require File.join("..", "lib", "nesta-plugin-admin")

module SpecHelpers
  extend self
  TEMP_DIR=File.expand_path("tmp", File.dirname(__FILE__))
  def setup_project
    [
      "cd #{TEMP_DIR}",
      "cp ../Gemfile.spec Gemfile",
      "bundle exec install --path ./vendor/bundle",
      "bundle exec nesta new spec_site",
      ""
    ].join(" && ")
  end
  def breakdown_project

  end
end
