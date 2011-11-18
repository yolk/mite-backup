# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mite-backup/version"

Gem::Specification.new do |s|
  s.name        = "mite-backup"
  s.version     = MiteBackup::VERSION
  s.authors     = ["Sebastian"]
  s.email       = ["sebastian@yo.lk"]
  s.homepage    = "http://mite.yo.lk/"
  s.summary     = %q{Download a backup of your mite account from the command-line.}
  s.description = %q{Download a backup of your mite account from the command-line.}

  s.rubyforge_project = "mite-backup"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "multi_json"
end
