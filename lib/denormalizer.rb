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