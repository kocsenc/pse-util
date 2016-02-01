require 'assignment_test'

# Runs `tree` and displays the output
class TreeTest < AssignmentTest

  def initialize( assignment, options )
    super( assignment, options )
    @results = ""
    @dir = options["dir"]
    @dir ||= ""
  end

  # Performs any compilation steps for the test
  def build
  end

  # Runs the tests
  def run
    Open3::popen2e( "tree #{@dir}" ) do |stdin, out, wait_thread|
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
