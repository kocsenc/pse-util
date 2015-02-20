Gem::Specification.new do |s|
  s.name        = 'gradehelp'
  s.version     = '2.2.2'
  s.date        = '2013-03-23'
  s.summary     = "Grading utility for SE 350/250"
  s.authors     = ["Derek Erdmann"]
  s.email       = 'derek@derekerdmann.com'
  s.files        = Dir["{lib}/**/*.rb", "bin/*", "*.markdown"]
  s.homepage    = 'http://github.com/derekerdmann'
  s.executables << "gradehelp"

  # Just load the README for the description
  if File.exists?( "README.markdown" )
    File.open( "README.markdown" ) do |f|
      s.description = f.read
    end
  end
  
end
