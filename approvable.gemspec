$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "approvable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "approvable"
  s.version     = Approvable::VERSION
  s.authors     = ["Yonah Forst"]
  s.email       = ["yonaforst@hotmail.com"]
  s.homepage    = "http://gihub.com/joshblour/approvable"
  s.summary     = "Don't change models without approval"
  s.description = "requires model attribute changes to be approved"
  s.license     = "MIT"
  s.test_files = Dir["spec/**/*"]
  
  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.1.4"
  s.add_dependency 'aasm'
  

  s.add_development_dependency "pg"
  s.add_development_dependency 'rspec-rails'
  # s.add_development_dependency 'capybara'
  s.add_development_dependency 'factory_girl_rails'
  
end
