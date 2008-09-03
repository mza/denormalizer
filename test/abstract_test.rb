require 'rubygems'
require 'active_record'
require 'active_record/fixtures'
require 'test/unit'

class Test::Unit::TestCase #:nodoc:
  self.fixture_path = File.dirname(__FILE__) + "/fixtures/"
end