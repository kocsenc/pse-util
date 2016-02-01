require 'open3'

module VCS

  # Custom exception for working with VCS's
  class VCSException < Exception
  end


  # Abstract class for VCS's that could be used in the grading script
  class VCS

    attr_reader :path

    # Constructor
    # repo - the path to the repository
    def initialize( repo )
      @path = File::absolute_path( repo )
    end
    
    # Change current directory to repo
    def move_to_repo()
      if Dir::pwd != @path
        Dir::chdir( @path )
      end
    end

    # Validates that the repo can be used
    def valid?
      raise "Not implemented"
    end

    # Pulls any changes from the VCS remote
    def pull_changes
      raise "Not implemented"
    end

    # Returns a DateTime of the last commit to the specified path
    def last_change( path )
      raise "Not implemented"
    end

    # Checks out the last version before the specified timestamp
    def checkout_before( timestamp, path )
      raise "Not implemented"
    end

    # Resets the repo to the original main state
    def reset
      raise "Not implemented"
    end

    # Retrieves the change logs for the item at the specified path
    def logs( path )
      raise "Not implemented"
    end

  end


  # Handler for Git
  class Git < VCS

    # Successful return code
    STATUS_OK = 0

    # Validates that the repo can be used
    def valid?
      return Dir::exists?( "#{@path}/.git" )
    end


    # Pulls any changes from the VCS remote and returns the output of the
    # pull command. May throw a VCSException if it was unable to pull changes
    def pull_changes
      reset
      Dir::chdir( @path ) do 
        Open3::popen3( "git pull" ) do |stdin, stdout, stderr, wait_thread|

          if wait_thread.value != STATUS_OK
            raise VCSException, stderr.read
          end

          return stdout.read
        end
      end
    end

    # Resets the repository to the clean master branch
    def reset
      Dir::chdir( @path ) do 
        `git checkout master`
        `git clean -dxf`
      end
    end

    # Returns a DateTime of the last commit to the specified path, or nil if
    # there is no valid timestamp for the path. Path should be relative to
    # the repository root
    def last_change( path )
      move_to_repo
      timestamp = `git log -1 --pretty="tformat:%ad" --date=iso #{path}`
      
      begin
        return DateTime.parse( timestamp )
      rescue
        return nil
      end
    end

    # Checks out the last version before the specified timestamp. Returns
    # true if the working directory changed, false otherwise. Path should be
    # relative to the repository root.
    def checkout_before( timestamp, path )
      change_before = `git rev-list -n 1 --before="#{timestamp.to_s}" master`

      if change_before.nil? || change_before.empty?
        return false
      else
        `git checkout #{change_before}`
        return true
      end
    end

    # Retrieves the change logs for the item at the specified path. Path
    # should be relative to the repository root
    def logs( path )
      move_to_repo
      system "git log #{path}"
    end

  end

end
