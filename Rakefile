#!/usr/bin/env rake
require "bundler/gem_tasks"

task :doc do
  puts %x{ yard --protected ./lib }
end

task :pages do
  puts %x{ git checkout gh-pages && git merge master && git push }
end
