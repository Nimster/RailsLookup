# Author: Nimrod Priell (Twitter: @nimrodpriell)
# 
# See README file or blog post for more.
# This is intended to be included into ActiveRecord entities: Simply
# include ActiveRecord::Lookup
# in your class that extends ActiveRecord::Base
module ActiveRecord
module Lookup
  #These will be defined as class methods.
  module ClassMethods
    #We define only this "macro". In your ActiveRecord entity (say, Car), use
    # lookup :car_type
    # which will create Car#car_type, Car#car_type=, Car#car_type_id,
    # Car#car_type_id= and CarType, an ActiveRecord with a name (String)
    # attribute, that has_many :cars. 
    # 
    # You can also use
    # lookup :car_type, :as => :type
    # which will do the same thing but create Car#type, Car#type=, Car#type_id
    # and Car#type_id= instead.
    def lookup(lookup_name, opts = {})
      as_name = opts[:as] || lookup_name
      mycls = self #Class I'm defined in

      #Create the new ActiveRecord for the lookup
      cls = Class.new(ActiveRecord::Base) do 
        #It has_many of the containing class
        has_many mycls.to_s.split(/[A-Z]/).map(&:downcase).join('_').to_sym

        validates_uniqueness_of :name
        validates :name, :presence => true

        #Query the cache for the DB ID of a certain value
        def self.id_for(name, id = nil)
          class_variable_get(:@@rcaches)[name] ||= id
        end

        #This helper method is the "find_or_create" of the class that also
        #updates the DB. I didn't want to overwrite the original
        #find_or_create_by_name since it is linked with a lot of the rails
        #behaviour and I want to avoid altering that.
        def self.gen_id_for(val)
          id = id_for val
          if id.nil?
            #Define this new possible value
            new_db_obj = find_or_create_by_name val #You could just override this...
            id_for val, new_db_obj.id
            name_for new_db_obj.id, val
            id = new_db_obj.id
          end
          id
        end

        #Query the cache for the value that goes with a certain DB ID
        def self.name_for(id, name = nil)
          class_variable_get(:@@caches)[id] ||= name
        end
      end

      #Bind the created class to a name
      lookup_cls_name = lookup_name.to_s.split("_").map(&:capitalize).join("")
      Object.const_set lookup_cls_name, cls #Define it as a global class

      #Define the setter by string value
      define_method("#{as_name.to_s}=") do |val|
        id = cls.gen_id_for val
        write_attribute "#{as_name.to_s}_id".to_sym, id
      end

      #Define the getter
      define_method("#{as_name.to_s}") do 
        id = read_attribute "#{as_name.to_s}_id".to_sym
        if not id.nil?
          value = cls.name_for id
          if value.nil?
            lookup_obj = cls.find_by_id id
            if not lookup_obj.nil?
              cls.name_for id, lookup_obj.name
              cls.id_for lookup_obj.name, id
            end
          end
        end
        value
      end

      #This sucks but it's the only way I could figure out to create the exact
      #method_missing method signature and still pass it the values I need to
      #use it. Maybe these should be class variables, but the best thing is if
      #they could only be defined in this scope and carried along with the
      #closure to the actual method.
      @as_name = as_name
      @cls = cls 
      #We need to wrap around rails' default finders so that
      #find_by_car_type and similar methods will behave correctly. We translate
      #them on the fly to find_by_car_type_id and give the id instead of the
      #requested name.
      def method_missing(method_id, *arguments, &block)
        if match = ActiveRecord::DynamicFinderMatch.match(method_id)
          #reroute car_type to _car_type_id
          idx = match.attribute_names.find_index { |n| n == @as_name.to_s }
          if not idx.nil?
            self.new.send "#{@as_name}=", arguments[idx] #Make sure there's a cached value
            arguments[idx] = @cls.id_for arguments[idx] #Change the argument
            method_id = method_id.to_s.sub /(by|and)_#{@as_name}$/, "\\1_#{@as_name}_id"
            method_id = method_id.to_s.sub /(by|and)_#{@as_name}_and/, "\\1_#{@as_name}_id_and"
            method_id = method_id.to_sym
          end 
        end 
        super
      end

      #Define the link between the host class and the newly created ActiveRecord
      belongs_to lookup_name.to_s.to_sym, :foreign_key => "#{as_name}_id".to_sym
      validates "#{as_name.to_s}_id".to_sym, :presence => true

      #Prefill the hashes from the DB
      all_vals = cls.all
      cls.class_variable_set(:@@rcaches, all_vals.inject({}) do |r, obj|
        r[obj.name] = obj.id
        r
      end)
      cls.class_variable_set(:@@caches, all_vals.inject([]) do |r, obj|
        r[obj.id] = obj.name
        r
      end)
    end
  end

  # extend host class with class methods when we're included 
  def self.included(host_class)
    host_class.extend(ClassMethods) 
  end
end
end
