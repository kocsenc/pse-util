require 'open3'
require 'assignment_test'

# Uses sample input and compares it to expected output
class DiffTest < AssignmentTest

  def initialize( assignment, options, exe )
    super( assignment, options )
    @invalid = false
    @test_diff = ""
    @command = ""
    @exe = exe
    @out = assignment.output

    @test_input = @assignment.path( options["test_file"] )
    @test_output = @assignment.path( options["expected_output"] )
    @args = options.has_key?( "args" ) ? options["args"] : ""
    @exe = options.has_key?( "exe" ) ? options["exe"] : @exe
    @name = options["name"]

    @errors = []
  end

  # Performs any compilation steps for the test
  def build
  end

  # Runs the tests
  def run

    if File::exists?( @exe )

      # See if this is ruby or python, run the script if needed
      executable = "./#{@exe}"
      if @exe.end_with?( "rb" )
        executable = "ruby #{@exe}"
      elsif @exe.end_with?( "py" )
        executable = "python3 #{@exe}" 
      end

      if @test_input 
        @command = "#{executable} #{@args} < #{@test_input} > grading_out.txt"
      else
        @command = "#{executable} #{@args} > grading_out.txt"
      end

      # Which test are we running?
      `#{@command}`

      Open3::popen2e( "diff grading_out.txt #{@test_output}" ) do |stdin, out, wait_thread|
        @test_diff = out.read
      end
      `rm grading_out.txt`

    else
      @errors << "No executable '#{@exe}' exists!"
    end
  end

  # Outputs the results of the test
  def display_results
    if @errors.empty?
      if @test_diff.empty?
        @out.puts "Output matches exactly"
      else
        @out.puts "Test diff:"
        @out.puts @test_diff
      end
    else
      @errors.each {|error| @out.puts error }
    end
  end

end
