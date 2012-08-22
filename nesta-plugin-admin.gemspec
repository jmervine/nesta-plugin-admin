# -*- encoding: utf-8 -*-
require File.expand_path('../lib/nesta-plugin-admin/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Joshua Mervine"]
  gem.email         = ["joshua@mervine.net"]
  gem.description   = %q{An admin interface for Nesta.}
  gem.summary       = %q{An admin interface for Nesta focusing around adding, removing and editing pages.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "nesta-plugin-admin"
  gem.require_paths = ["lib"]
  gem.version       = Nesta::Plugin::Admin::VERSION
  gem.add_dependency("nesta", ">= 0.9.11")
  gem.add_development_dependency("rake")
end
