Gradehelp
=========

Configurable grading tool

Setup
-----
Gradehelp is a Ruby gem. After cloning the repository, you can install it using
the following commands:

    bundle install
    rake

This should add the gradehelp gem executable to your path.

Usage
-----
To get usage information for Gradehelp commands, run `gradehelp help`

###Grading
Gradehelp relies on a configuration directory for running automated tests and
checking due dates. This directory should contain:

    * `config.yml`
    * Test inputs and outputs for diff tests
    * Additional tests that should be linked into the program

When running `gradehelp grade`, the only mandatory argument is a configuration
directory that contains the `config.yml` file.

In order to grade assignments, gradehelp should be run from the root directory
into which all student repositories were cloned.
