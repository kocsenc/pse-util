require 'open3'
require 'fileutils'

# Uses SimpleCTest framework
# Sample config:
# 
# simplectest:
# - name: OrderedList tests
#   test:
#     source: [testOrderedList.c]
#     object: testOrderedList.o
#     compiler_flags: "-g"
#   target:
#     object: OrderedList.o
#     build: make OrderedList.o
#     exe: testOrderedList
#   args: ""
#   
class SimpleCTest < AssignmentTest

  def initialize( assignment, options )
    super( assignment, options )
  end

  # Performs any compilation steps for the test
  def build
    @results = ""

    source = @options["test"]["source"]
    flags = @options["test"]["compiler_flags"]
    test_object = @options["test"]["object"]
    target_object = @options["target"]["object"]
    exe = @options["exe"]
    puts exe

    # If we have the test executable, don't rebuild
    return if File.exists?( exe )

    # If the test object exists, don't rebuild
    if !File.exists?( @assignment.path( test_object ) )
      compile_test_object( source, flags, test_object )
    end

    link_test_exe( exe, test_object, target_object )

  end

  # Runs the tests
  def run
    build
    return if !@errors.empty?

    Open3::popen2e( "./#{@options["exe"]}" ) do |stdin, out, wait_thread|
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

  # Build the test object in the assignment directory
  def compile_test_object( source, flags, object )
    Dir::chdir( @assignment.assignment ) do
      command = "gcc -c #{flags} -o #{object} #{source.join(" ")}"
      @out.puts command

      exit_code = 0
      Open3::popen2e( command ) do |stdin, out, wait_thread|
        output = out.read
        @out.puts output if !output.empty?
        exit_code = wait_thread.value.to_i
      end

      # Display any errors, invalidate this test
      if exit_code != 0
        @errors << "Failed to build #{object}"
      end
    end
  end

  # Build the test executable
  def link_test_exe( exe, object, target_object )
    command = "gcc -o #{exe} #{@assignment.path( object )} #{target_object}"
    @out.puts command

    exit_code = 0
    Open3::popen2e( command ) do |stdin, out, wait_thread|
        output = out.read
        @out.puts output if !output.empty?
      exit_code = wait_thread.value.to_i
    end
    
    # Display any errors, invalidate this test
    if exit_code != 0
      @out.puts "Failed to build #{object}"
      @invalid = true
    end
  end

end
