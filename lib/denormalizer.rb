# Copyright (c) 2008 Genome Research Ltd.
# Author: Matt Wood <matt.wood@sanger.ac.uk>

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#  
#    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
#    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
#    3. The name of the author may not be used to endorse or promote products derived from this software without specific prior written permission.
#  
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

module Denormalizer
  
  # Include class methods
  def self.included(mod)
    mod.extend(ClassMethods)
  end
  
  # Methods defined here are included in the originating Class
  module ClassMethods
    def denormalizes(field, options)
      include Denormalizer::InstanceMethods
      write_inheritable_hash :denormalizations, field => options
      class_inheritable_reader :denormalizations
      before_save :prepare_denormalization
      before_save :denormalize_attributes
      after_save :perform_denormalization
    end
  end  
  
  # Methods defined here are made available to instances of
  # the originating Class
  module InstanceMethods
    
    def denormalize_attributes
      logger.debug "+ DENORMALIZING COMPUTED VALUES"
      denormalizations.each do |key, options|
        unless options[:using].nil?
          value = options[:using]
          logger.debug "DENORMALIZING #{value} to #{key}"
          self.send("#{key}=", self.send("#{value}"))
        end
      end      
    end
    
    def prepare_denormalization
      logger.debug "+ PREPARING DENORMALIZED VALUES"
      denormalizations.each do |key, options|
        unless options[:from].nil?
          value = options[:from]
          association = value.to_s
          associated_klass = association.camelize.singularize.constantize
          s = self.send("#{value}")
          unless s.nil?
            self.send("#{value}_#{key}=", s.send("#{key}"))
            logger.debug "---> Denormalizing #{key} to #{associated_klass.to_s} #{s.id}"
          end
        end
      end
      
    end
    
    def perform_denormalization
      logger.debug "+ UPDATING DENORMALIZED VALUES"
      denormalizations.each do |key, options|
        unless options[:to].nil?
          value = options[:to]
          parent = self.class.to_s.camelize.downcase
          association = value.to_s
          associated_klass = association.camelize.singularize.constantize
          logger.debug "---> Denormalizing #{parent} #{key} to #{associated_klass.to_s}"
          self.send(value.to_s).update_all [ "#{parent}_#{key} = ?", self.send(key) ]
        end
      end
    end
    
    def denormalizations
      read_inheritable_attribute(:denormalizations) || write_inheritable_attribute(:denormalizations, {})
    end
    
  end
  
end