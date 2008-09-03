class Descriptor < ActiveRecord::Base
  
  has_many :descriptor_values
  
end