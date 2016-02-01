require 'thor'
require 'yaml'
require 'open3'
require 'pp'
require 'vcs'
require 'student'
require 'grader'

EXCLUDED_FILES = %w( . .. gradehelp notes assignments )

class GradeHelp < Thor

  desc "grade ASSIGNMENT_DIR", "begin grading an assignment"
  method_option :student, aliases: "-s", type: :string,
    desc: "Start grading a specific student"
  method_option :"no-pull", type: :boolean,
    desc: "Does not pull from student repositories before grading"
  def grade(assignment_dir)
  	puts("GRADING")
    Assignment.new(
      $stdout,
      $stderr,
      assignment_dir,
      options[:student],
      options[:"no-pull"]
    ).start()
  end

  desc "pull", "pull changes from all student repositories"
  def pull

    ignored = []

    Dir::open( Dir::pwd ).each do |dir|
      if !EXCLUDED_FILES.include?( dir ) && Dir::exists?( dir )
        begin
          puts "Pulling changes for #{dir}..."
          puts Student.new( dir, VCS::Git ).repo.pull_changes
          puts ""
        rescue VCS::VCSException
          ignored << dir
        end
      end
    end
    
  end

  desc "show", "Show the most recent commit message for the student"
  method_option :"no-pull", type: :boolean,
    desc: "Does not pull from the student repository"
  method_option :"no-commit", type: :boolean,
    desc: "Does not show the last commit in the repository"
  method_option :check, type: :string,
    desc: "Indicates a file or directory to ensure exists and print contents"
  def show( student )

    if Dir::exist?( student )

      if !options[:"no-pull"]
        puts "Pulling changes for #{student}..."
        puts Student.new( student, VCS::Git ).repo.pull_changes
        puts ""
      end

      dir_to_check = options[:check]

      if dir_to_check
        Dir::chdir( student ) do
          if File::exist?( dir_to_check )
            puts "#{dir_to_check} exists".green
            puts `tree #{dir_to_check}`
          else
            puts "#{dir_to_check} does not exist!".red
          end

          if !options[:"no-commit"]
            puts ""
            puts `git log -1 --color` 
          end
        end
      end


    else
      puts "Directory \"#{student}\" not found!".red
    end

  end

end

# Handles grading for a single assignment
class Assignment

  attr_reader :output, :error, :assignment, :start_student, :pull_changes

  CONFIG_FILE = "config.yml"
  REQUIRED_CONFIG_FIELDS = %w( folder )

  # Creates a new assignment using the specified path
  def initialize( output, error, assignment, start_student, no_pull )
    @output, @error = output, error
    @assignment = File.expand_path( assignment )
    @start_student = start_student
    @pull_changes = !no_pull

    @students = []
    @grades = []

    @config_file = "#{@assignment}/#{CONFIG_FILE}"
    load_config
  end

  # Raise errors during assignment loading
  def load_error( message )
    raise "Unable to load assignment: #{message}"
  end

  # Load configuration data from the specified file
  def parse_config()
    result = YAML.load_file( @config_file )
    if !result.nil? && !result
      load_error( "Unable to parse #{@config_file}" )
    end

    result
  end

  # Validate the existence of required items
  def load_config()
    
    # Assignment directory must be an included argument
    if @assignment.nil? || @assignment.empty?
      load_error( "No assignment specified!" )

    # Must be a directory
    elsif !File::exists?( @assignment ) || !File::directory?( @assignment )
      load_error( "#{@assignment} is not a directory!" )
    end

    # Check existence of config file
    if !File.exists?( @config_file )
      load_error( "#{CONFIG_FILE} does not exist!" )
    end
    
    @config = parse_config
    @config["assignment_dir"] = File::expand_path( @assignment )

    # Make sure SOMETHING was parsed
    if @config.nil? || @config.empty?
      load_error( "#{@config_file} contains no assignment information!" )
    end

    # Check required fields
    REQUIRED_CONFIG_FIELDS.each do |field|
      if !@config.has_key?( field )
        load_error( "#{@config_file} missing required field '#{field}'" )
      end
    end
  end

  # Begins the grading process
  def start()
    @output.puts "Grading #{@assignment}..."

    load_student_dirs

    @students.each do |student|
      grader = Grader.new( student, @config, @output, @assignment, self )
      grader.grade()
      @grades << grader
    end
  end

  # Gets student directories and initializes them for grading
  def load_student_dirs

    ignored = []

    Dir::open( Dir::pwd ).each do |dir|
      if !EXCLUDED_FILES.include?( dir ) && Dir::exists?( dir )

        # Load students, ignore them if they're not valid repos
        begin
          @students << Student.new( dir, VCS::Git )
        rescue VCS::VCSException
          ignored << dir
        end

      end
    end

    @students.sort_by! { |student| student.dce }

    if !@start_student.nil?
      @students = @students.drop_while { |student| student.dce != @start_student }
    end
    
    @output.puts "Ignoring #{ignored.join( ", " )}"
    @output.puts "Loaded #{@students.count} student repositories"
    @output.puts ""
  end


  # Returns the path to the specified file in the assignment directory
  def path(file)
    "#{@assignment}/#{file}"
  end

end
