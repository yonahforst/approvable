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
        
        cattr_accessor :ignored_attrs
        self.ignored_attrs = [*options[:except]] + [:id, :created_at, :updated_at]
        self.ignored_attrs = self.attribute_names.map(&:to_sym) - [*options[:only]] if options[:only]
        self.ignored_attrs.map!(&:to_s)
        
        unless method_defined?(:assign_attributes_without_change_request)
          alias_method_chain :assign_attributes, :change_request
        end
      end

    end
    
    module LocalInstanceMethods
               
      def requested_changes
        current_change_request ? current_change_request.requested_changes : {}
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
          current_change_request.approve! if current_change_request
          apply_changes.save
          reload
        end
      end
      
      def reject_changes options = {}
        current_change_request.reject! :rejected, options if current_change_request
        reload
      end
      
      def assign_attributes_with_change_request new_attributes
        new_attributes.stringify_keys!
        ignored_params = new_attributes.slice(*self.class.ignored_attrs)
        approvable_params = new_attributes.except(*self.class.ignored_attrs)

        if approvable_params.any?
          current_change_request || build_current_change_request(requested_changes: {})       
          current_change_request.requested_changes = requested_changes.merge approvable_params
        end
      
        assign_attributes_without_change_request ignored_params
      end
      

      private
      
      def auto_approve?
        Approvable.auto_approve == true
      end
      
      def force_approve!
        current_change_request.update_column :state, 'approved'
      end

    end
  end
end
 
ActiveRecord::Base.send :include, Approvable::ActsAsApprovable
