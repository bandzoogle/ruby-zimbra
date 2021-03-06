# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "zimbra"
  s.version = "0.0.5"
  s.description = 'Interface to Zimbra management API'
  s.summary = 'Interface to Zimbra management API'
  s.email = %q{derek@vedit.com mwilson@vedit.com}
  s.authors = ["People"]

  
  s.files = ['README'] + Dir.glob("lib/**/*.rb")
  s.require_paths = ["lib"]
  
  s.add_dependency "handsoap"
  s.add_development_dependency "rspec"
end
