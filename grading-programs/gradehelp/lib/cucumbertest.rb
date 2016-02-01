require 'open3'
require 'assignment_test'

# Uses Cucumber test framework
class CucumberTest < AssignmentTest

  def initialize( assignment, options, exe )
    super( assignment, options )
    @name = options["name"]
    @features = options["features"]
    @results = ""
    @exe = exe
  end

  # Performs any compilation steps for the test
  def build
  end

  # Runs the tests
  def run

    command = "cucumber ENTRY_POINT=#{@exe} -c --no-source #{@features.map{|feature| @assignment.path( "#{feature}.feature" ) }.join( " ")}"
    Open3::popen2e( command ) do |stdin, out, wait_thread|
      @results = out.read
    end

  end

  # Outputs the results of the test
  def display_results
    if @errors.empty?
      @out.puts @results
    else
      @errors.each {|error| @out.puts error }
    end
  end

end
