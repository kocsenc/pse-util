require 'open3'
require 'difftest'
require 'simplectest'
require 'cucumbertest'
require 'pyunittest'
require 'rubyunittest'
require 'treetest'
require 'colorize'

class Grader

  attr_reader :student, :config, :assignment_path, :assignment
  attr_reader :folder, :last_change

  def initialize( student, config, output, assignment_path, assignment )
    @student = student
    @config = config.clone
    @output = output
    @assignment_path = assignment_path
    @assignment = assignment
  end

  # Do the grading process
  def grade
    print_separator
    @output.puts "Grading #{@student.dce}..."
    @output.puts ""

    if @assignment.pull_changes
      pull_changes
    end

    Dir::chdir( @student.repo.path ) do

      # Check the directory for the submission
      @folder = check_folder
      if @folder.empty?
        @output.puts "Skipping #{@student.dce}"
        @output.puts ""
        return
      end
      @output.puts "Using directory #{@folder}"

      # Start looking at the actual assignment
      check_submission_time
      @output.puts ""

      # display the student's logs
      prompt( "View VCS log?", true ) do
        @student.repo.logs( @folder )
      end

      @output.puts ""
        
      # Start looking at the thing
      Dir::chdir( @folder ) do

        print_separator
        @output.puts "Checking files and building..."
        @output.puts ""
        has_files = has_required_files?
        @output.puts ""

        build_anyway = false
        if !has_files
          build_anyway = prompt( "Missing required files. Continue with build?", false )
        end

        # Make sure all needed files for building exist
        load_support_files

        # Prompt for starting file
        if @config["exe"] && @config["exe"] == "?"
          @output.puts "Possible source files:"
          @output.puts @config["source"].join(" ")
          @output.puts ""
          @output.print "Select entry point (press enter to skip): "
          
          @config["exe"] = $stdin.gets.strip
          return if @config["exe"].empty?
        end

        # Build
        successful_build = false
        if @config["build"] && ( has_files || build_anyway )

          #clean before build
          `#{@config["clean"]}` if @config["clean"]

          @output.puts "Build output:"
          Open3::popen2e( @config["build"] ) do |stdin, out, wait_thread|
            @output.puts out.read
            successful_build = wait_thread.value.to_i == 0
          end

          if !successful_build
            successbul_build = prompt( "Error building project. Continue?", false )
          end
       
        # If there is no build step, assume it's correctly built
        else
          successful_build = true if @config["build"].nil?
        end

        # Check for extra credit
        if @config["bonus_due_date"]
          prompt( "Check for bonus submission?", true ) do
            bonus_date = DateTime.parse( @config["bonus_due_date"] )

            Dir::chdir( ".." ) do 
              has_early_submission = @student.repo.checkout_before( bonus_date, "." ) && Dir::exists?( @folder )

              if has_early_submission
                Dir::chdir( @folder ) do 
                  @output.puts "Commits exist before #{bonus_date.to_s}".green
                
                  bonus_tests = select_tests.select do |test|
                    test.options.include?( "for_bonus" ) && test.options["for_bonus"]
                  end
                  
                  bonus_tests.each do |test|
                    @output.puts ""
                    @output.puts ""
                    @output.puts "#{test.class.name.split("::").last} - #{test.name}"
                    print_separator
                    test.build
                    test.run
                    test.display_results
                  end
                end
              else
                @output.puts "No commits before #{bonus_date.to_s}".red
              end

              prompt( "Press any key to continue...", true )
              @output.puts ""
              @student.repo.reset
            end
          end
        end

        # Run tests
        if successful_build
          select_tests.each do |test|
            @output.puts ""
            @output.puts ""
            @output.puts "#{test.class.name.split("::").last} - #{test.name}"
            print_separator
            test.build
            test.run
            test.display_results
          end
        end

        # Display the student's source file
        if @config["source"]
          prompt( "View source files?", true ) do
            display_source
          end
        end

      end

    end

    @output.puts ""
    @output.puts "Press enter to continue..."
    $stdin.gets
  end

  # Pull changes from the VCS
  def pull_changes
    puts "Pulling changes..."
    begin
      puts @student.repo.pull_changes
    rescue VCS::VCSException => e
      puts "Error pulling changes: #{e.message}"
    end
    puts ""
  end

  # Checks the existence of the required folder. If it does not exist,
  # displays a list of possibilities and prompts for input to proceed.
  def check_folder
    folder = config["folder"]

    if Dir.exists?( folder )
      return folder

    else
      @output.puts "Required folder #{folder} missing!"
      @output.puts "Possible alternatives:"
      @output.puts Dir::glob("*/").map{ |dir| dir.chomp.chomp }.join(" ")
      @output.puts ""
      @output.print "Enter assignment folder (press enter to skip): "

      folder_to_use = $stdin.gets.strip
      if Dir.exists?( folder_to_use )
        return folder_to_use
      else
        return ""
      end
    end
  end

  # Returns the datetime of the most recent change to the current directory
  def newest_change
    @student.repo.last_change( @folder )
  end

  # Checks the submission time and rolls back as needed
  def check_submission_time

      @last_change = newest_change
      @output.puts "Latest change: #{@last_change.strftime("%a %b %d %Y %I:%M%p")}"
      if @config["due"]
        due = DateTime.parse( @config["due"] )
        @output.puts "Submitted #{@last_change <= due ? "ON TIME".green : "LATE".red}"
      end
  end

  # Checks for the existence of required files. Returns true if no required
  # files are missing, false otherwise.
  def has_required_files?
    missing_files = false

    # Files are explicitly listed
    if @config["source"].kind_of?( Array )
      files = @config["source"]
      files.each do |file|
        exists = File::exists?( file )
        @output.puts "#{file}: #{ exists ? "Exists" : "MISSING"}"
        missing_files = true if !exists
      end

      if missing_files
        @output.puts "Directory contains: "
        Dir::open( "." ).each {|f| @output.print "#{f} " }
        @output.puts ""
      end

    # Files use glob syntax
    elsif @config["source"].kind_of?( String )
      files = Dir.glob( @config["source"] )
      @config["source"] = files
    end

    return !missing_files
  end

  # display the student's source files in vim
  def display_source
    system "vim -p #{@config["source"].inject(""){|list, f| list + "#{f} " }}"
  end

  # Prompts the user for a boolean choice. If a block is specified, 
  # its contents will be executed if the result is true
  def prompt( prompt, default )
    @output.puts ""
    @output.puts "#{prompt} (#{default ? "Y/n" : "y/N"})"

    response = $stdin.gets.strip.downcase
    result = response.empty? ? default : response != "n"

    yield if block_given? && result
    result
  end

  # Copies any required support files
  def load_support_files
    return if !@config["support_files"] || @config["support_files"].empty?

    num_copied = 0
    @config["support_files"].each do |file|
      if !File.exists?( file ) || file.include? "Makefile"
        @output.puts "Loading missing file #{file}..."
        FileUtils.cp( @assignment.path( file ), file )
        num_copied += 1
      end
    end

    @output.puts "" if num_copied > 0
  end

  # Outputs a horizontal line of dashes
  def print_separator
    @output.puts (1..60).map { |n| "" }.join("-")
  end

  # Compiles all the tests that should be run
  def select_tests

    tests = []

    # These tests run the compiled executable and test the expected output
    if @config["diff"] && @config["exe"]

      prompt( "Run diff tests?", true ) do
        diff_test = @config["diff"]

        # Handle multiple tests
        if diff_test.kind_of?( Array )
          tests = tests + diff_test.map do |diff|
            DiffTest.new( @assignment, diff, @config["exe"] )
          end

        # There's only one test included
        else 
          tests << DiffTest.new( @assignment, diff_test, @config["exe"] )
        end
      end
    end

    # These tests link a submitted source file against a unit test
    if @config["simplectest"]
      prompt( "Run C unit tests?", true ) do
        tests = tests + @config["simplectest"].map do |test|
          SimpleCTest.new( @assignment, test )
        end
      end
    end

    # These tests use Cucumber at a feature level
    if @config["cucumber"]
      prompt( "Run Cucumber feature tests?", true ) do
        tests = tests + @config["cucumber"].map do |test|
          CucumberTest.new( @assignment, test, @config["exe"] )
        end
      end
    end

    # These tests use PyUnit at a feature level
    if @config["pyunit"]
      prompt( "Run PyUnit tests?", true ) do
        tests = tests + @config["pyunit"].map do |test|
          PyUnitTest.new( @assignment, test )
        end
      end
    end

    # These tests use PyUnit at a feature level
    if @config["rubytestunit"]
      prompt( "Run Ruby Test::Unit tests?", true ) do
        tests = tests + @config["rubytestunit"].map do |test|
          RubyUnitTest.new( @assignment, test )
        end
      end
    end

    # These tests use PyUnit at a feature level
    if @config["tree"]
      prompt( "View source tree?", true ) do
        tests = tests + @config["tree"].map do |test|
          TreeTest.new( @assignment, test )
        end
      end
    end

    tests
  end

end
