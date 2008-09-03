require 'denormalizer'

ActiveRecord::Base.class_eval do
  include Denormalizer
end