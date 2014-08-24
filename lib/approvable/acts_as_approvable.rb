module Approvable
  module ActsAsApprovable
    extend ActiveSupport::Concern
 
    included do
    end
 
    module ClassMethods
      def acts_as_approvable **options      
        include Approvable::ActsAsApprovable::LocalInstanceMethods

        has_many :change_requests, as: :approvable, class_name: 'Approvable::ChangeRequest', dependent: :destroy
        has_one :current_change_request, -> {where.not(state: 'approved') }, as: :approvable, class_name: 'Approvable::ChangeRequest', autosave: true
        
        before_save :apply_changes, if: :auto_approve?
        after_save :force_approve!, if: :auto_approve?
        
        cattr_accessor :filter_attrs, :filter_type
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
        self.assign_attributes_without_change_request requested_changes
        self
      end
      
      def submit_changes
        transaction do
          current_change_request.submit! if current_change_request
          reload
        end 
      end
      
      def unsubmit_changes
        transaction do
          current_change_request.unsubmit! if current_change_request
          reload
        end
      end
      
      def approve_changes
        transaction do
          if current_change_request && apply_changes.save!
            current_change_request.approve!
            reload
          end
        end
      end
      
      def reject_changes options = {}
        current_change_request.reject! :rejected, options if current_change_request
        reload
      end
      
      def assign_attributes_with_change_request new_attributes
        ignored_params = ignored_attributes(new_attributes)
        approvable_params = approvable_attributes(new_attributes)

        if approvable_params.any?
          current_change_request || build_current_change_request(requested_changes: {})       
          current_change_request.requested_changes = requested_changes.merge approvable_params
        end
      
        assign_attributes_without_change_request ignored_params
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
        attributes = attributes.dup.stringify_keys!
        hash = {}
        [*keys].each do |key|
          if key.is_a? Hash
            key.each do |k,v| 
              hash[k.to_s] = process_nested_hash(attributes[k.to_s], v, should_match) if attributes[k.to_s]
            end
          elsif key.is_a? Array
            key.each do|k|
              process_nested_hash(attributes[k.to_s], k, should_match) if attributes[k.to_s]
            end
          else
            value = attributes.delete(key.to_s)  
            hash[key.to_s] = value if value
          end
        end
        
        if should_match
          return hash
        else
          return attributes
        end
        
      end

      # process_nested_hash h, [:first_name, {address: :street}], true
      # process_nested_hash h, [:first_name, {address: :street}], false
      
      def auto_approve?
        Approvable.auto_approve == true
      end
      
      def force_approve!
        current_change_request.update_column :state, 'approved' if current_change_request
      end

    end
  end
end
 
ActiveRecord::Base.send :include, Approvable::ActsAsApprovable
