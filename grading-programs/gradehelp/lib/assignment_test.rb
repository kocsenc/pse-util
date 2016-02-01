# Abstract class for tests that can be run on assignments
class AssignmentTest

  attr_reader :out, :options, :assignment, :errors, :name

  def initialize( assignment, options )
    @assignment = assignment
    @out = assignment.output
    @options = options
    @errors = []
    @name = options["name"]
  end

  # Performs any compilation steps for the test
  def build
    raise "Not implemented"
  end

  # Runs the tests
  def run
    raise "Not implemented"
  end

  # Outputs the results of the test
  def display_results
    raise "Not implemented"
  end

end
