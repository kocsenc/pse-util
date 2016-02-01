require 'vcs'

# Information for an individual student during grading
class Student

  attr_reader :repo, :dce

  # Create the student with the repository. The exact VCS used is unknown
  def initialize( repo, vcs )
    @repo = vcs.new( repo )
    @dce = repo

    # Check that this is a usable repo
    if !@repo.valid?
      raise VCS::VCSException, "#{repo} is not a valid repository"
    end
  end

end
