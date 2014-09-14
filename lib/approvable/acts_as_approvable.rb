module Approvable
  module ActsAsApprovable
    extend ActiveSupport::Concern
 
    included do
    end
 
    module ClassMethods
      def acts_as_approvable **options      
        include Approvable::ActsAsApprovable::LocalInstanceMethods

        has_many :change_requests, as: :approvable, class_name: 'Approvable::ChangeRequest', dependent: :destroy, validate: false
        has_one :current_change_request, -> {where.not(state: 'approved') }, as: :approvable, class_name: 'Approvable::ChangeRequest', autosave: true, validate: true
        cattr_accessor :filter_attrs, :filter_type

        amoeba { enable }
        
        if options[:except]
          self.filter_type = :except
          self.filter_attrs = options[:except]
        elsif options[:only]
          self.filter_type = :only
          self.filter_attrs = options[:only]
        else
          self.filter_type = :except
          self.filter_attrs = []
        end
                
        unless method_defined?(:assign_attributes_without_change_request)
          alias_method_chain :assign_attributes, :change_request
          alias_method :attributes=, :assign_attributes_with_change_request
        end

        unless method_defined?(:valid_without_changes?)
          alias_method_chain :valid?, :changes if Approvable.validate_with_changes
        end
      end

    end
    
    module LocalInstanceMethods
               
      def requested_changes
        current_change_request ? current_change_request.requested_changes.with_indifferent_access : {}
      end
      
      # use current_change_request here so that we dont get pending from a newly built change_request
      def change_status
        current_change_request ? current_change_request.state : 'approved'
      end

      def change_status_notes
        current_change_request ? current_change_request.notes : {}
      end
            
      def apply_changes
        begin
          Hash[requested_changes.sort].each do |k,v|
            self.assign_attributes_without_change_request v if v.is_a? Hash
          end
        rescue ActiveRecord::UnknownAttributeError => e
          puts p
        end
        self
      end
      
      def submit_changes
        transaction do
          current_change_request.submit! if current_change_request
          reload
        end 
      end
      
      def submit_changes_with_validation
        valid?(:submit) && submit_changes
      end
      
      def submit_changes_with_validation!
        raise(ActiveRecord::RecordInvalid.new(self)) unless submit_changes_with_validation
      end
      
      def unsubmit_changes
        transaction do
          current_change_request.unsubmit! if current_change_request
          reload
        end
      end
      
      def approve_changes
        transaction do
          if current_change_request && apply_changes.save
            current_change_request.approve!
          end
        end
      end
      
      def reject_changes options = {}
        current_change_request.reject! :rejected, options if current_change_request
        reload
      end
      
      def assign_attributes_with_change_request new_attributes
        ignored_changes = ignored_attributes(new_attributes)
        approvable_changes = approvable_attributes(new_attributes)

        if approvable_changes.any?
          current_change_request || build_current_change_request(requested_changes: {})
          current_change_request.requested_changes_will_change!

          current_change_request.requested_changes[Time.now.to_i] = approvable_changes          
        end
      
        assign_attributes_without_change_request ignored_changes
      end      


      def valid_with_changes? options = {}
        errors.clear
        dup = self.amoeba_dup
        dup.apply_changes
        dup.valid_without_changes? options
        dup.errors.each do |attribute, error|
          errors[attribute] = error
        end
        errors.empty?
      end
      
      private
      
      def ignored_attributes(new_attributes)
        process_nested_hash(new_attributes, self.class.filter_attrs, filter_type == :except)
      end
      
      def approvable_attributes(new_attributes)
        process_nested_hash(new_attributes, self.class.filter_attrs, filter_type == :only )
      end
      
      # h = {"first_name"=>"Leif", "last_name"=>"Gensert", "address"=>{"street"=>"Preysinstraße", "city"=>"München"}}
      def process_nested_hash(attributes, keys, should_match)
        old_attrs = attributes.with_indifferent_access
        new_attrs = {}
        [*keys].each do |key|
          if key.is_a? Hash
            key.each do |k,v|
              if old_attrs[k]
                new_attrs[k] = process_nested_hash(old_attrs[k], v, true) 
                old_attrs[k] = process_nested_hash(old_attrs[k], v, false)
              end
            end
          # elsif key.is_a? Array
          #   key.each do|k|
          #     process_nested_hash(attributes[k.to_s], k, should_match) if attributes[k.to_s]
          #   end
          else
            value = old_attrs.delete(key)
            new_attrs[key] = value if value
          end
        end
        
        if should_match
          return new_attrs
        else
          return old_attrs
        end
        
      end

      # process_nested_hash h, [:first_name, {address: :street}], true
      # process_nested_hash h, [:first_name, {address: :street}], false

    end
  end
end
 
ActiveRecord::Base.send :include, Approvable::ActsAsApprovable
