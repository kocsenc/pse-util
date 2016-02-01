require 'assignment_test'

# Runs PyUnit tests
class PyUnitTest < AssignmentTest

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

    env = {
      "PYTHONPATH" => Dir::pwd
    }

    Open3::popen2e( env, "python3 #{file}" ) do |stdin, out, wait_thread|
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
