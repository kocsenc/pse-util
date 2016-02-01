require 'assignment_test'

# Runs Ruby Test::Unit tests
class RubyUnitTest < AssignmentTest

  def initialize( assignment, options )
    super( assignment, options )
    @results = ""
  end

  # Performs any compilation steps for the test
  def build
  end

  # Runs the tests
  def run
    if @options["submitted"]
      file = "./#{@options["test_file"]}"
    else
      file = @assignment.path( @options["test_file"] )
    end

    Open3::popen2e( "ruby #{file}" ) do |stdin, out, wait_thread|
      @results = out.read
    end
  end
  

  # Outputs the results of the test
  def display_results
    if @errors.empty?
      @out.puts @results
    else
      @errors.each{ |error| @out.puts error }
    end
  end

end
