# Author: Nimrod Priell (Twitter: @nimrodpriell)
# 
# See README file or blog post for more.
# This is intended to be included into ActiveRecord entities: Simply
# include ActiveRecord::Lookup
# in your class that extends ActiveRecord::Base
module ActiveRecord
  module Lookup
    #These will be defined as class methods so they can be called as "macros"
    #like belongs_to
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

        #Define the setter for the attribute by textual value
        mycls = self #Class I'm defined in
        #Ignore anonymous classes:
        mycls_sym = mycls.name.tableize.to_sym unless mycls.to_s =~ /#<.*>/ 
        lookup_cls_name = lookup_name.to_s.camelize
        begin
          #If it exists, just tack on the extra has_many
          cls = Object.const_get lookup_cls_name
          cls.has_many mycls_sym unless mycls_sym.blank? #for annon classes
        rescue NameError
          #Otherwise, actually define it
          cls = Class.new(ActiveRecord::Base) do 
            has_many mycls_sym unless mycls_sym.blank? #For anon classes
            validates_uniqueness_of :name
            validates :name, :presence => true

            def self.id_for(name, id = nil)
              class_variable_get(:@@rcaches)[name] ||= id
            end

            def self.gen_id_for(val)
              id = id_for val
              if id.nil?
                #Define this new possible value
                #You could just override this...
                new_db_obj = find_or_create_by_name val 
                id_for val, new_db_obj.id
                name_for new_db_obj.id, val
                id = new_db_obj.id
              end
              id
            end

            def self.name_for(id, name = nil)
              class_variable_get(:@@caches)[id] ||= name
            end

            #This is especially useful for tests - you want deletion to also
            #clear the caches otherwise odd stuff might happen
            def self.delete_all(*args)
              class_variable_set :@@caches, []
              class_variable_set :@@rcaches, {}
              super *args
            end
          end

          Object.const_set lookup_cls_name, cls #Define it as a global class
        end


        define_method("#{as_name.to_s}_id=") do |id|
          write_attribute "#{as_name.to_s}".to_sym, id
        end

        define_method("#{as_name.to_s}=") do |val|
          id = cls.gen_id_for val #TODO: Just call #{as_name.to_s}_id=
          write_attribute "#{as_name.to_s}".to_sym, id
        end

        define_method("#{as_name.to_s}_id") do 
          read_attribute "#{as_name.to_s}".to_sym
        end

        #Define the getter
        define_method("#{as_name.to_s}") do 
          id = read_attribute "#{as_name.to_s}".to_sym
          if not id.nil?
            value = cls.name_for id
            if value.nil?
              lookup_obj = cls.find_by_id id
              if not lookup_obj.nil?
                #TODO: Extract to a method
                cls.name_for id, lookup_obj.name
                cls.id_for lookup_obj.name, id
              end
            end
          end
          value
        end


        #Rails ActiveRecord support:
        @cls_for_name = {} if @cls_for_name.nil?
        @cls_for_name[as_name.to_s.to_sym] = cls

        #This makes find_and_create_by, find_all and where methods all work as
        #they should. This will not work if you use reset_column_information,
        #like if you use find_by_session_id in SessionStore. You must redefine
        #it so it re-sets rel to this singleton object
        rel = ActiveRecord::Relation.new(self, arel_table)
        def rel.where(opts, *rest)
          if opts.is_a? Hash
            mapped = opts.map do |k,v| 
              if @cls_for_name.has_key?(k.to_sym) 
                [k, @cls_for_name[k.to_sym].id_for(v)] 
              else
                [k, v] 
              end
            end
            opts = Hash[mapped]
          end
          super(opts, *rest)
        end

        def rel.cls_for_name=(cls_for_name)
          @cls_for_name = cls_for_name
        end

        rel.cls_for_name = @cls_for_name
        instance_variable_set(:@relation, rel)

        #Might need to be in class_eval
        belongs_to lookup_name.to_s.to_sym, :foreign_key => "#{as_name}"
        validates as_name.to_s.to_sym, :presence => true

        # Prefill the hashes from the DB - requires an active connection
        all_vals = cls.all
        # No need for the class_exec
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
