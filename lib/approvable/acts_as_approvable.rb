module Approvable
  module ActsAsApprovable
    extend ActiveSupport::Concern
 
    included do
    end
 
    module ClassMethods
      def acts_as_approvable(options = {})
        include Approvable::ActsAsApprovable::LocalInstanceMethods

        has_many :change_requests, as: :approvable, class_name: 'Approvable::ChangeRequest'
        has_one :current_change_request, -> {where.not(state: 'approved') }, as: :approvable, class_name: 'Approvable::ChangeRequest'
                
        alias_method_chain :save, :change_request
        alias_method_chain :save!, :change_request
        accepts_nested_attributes_for :current_change_request, update_only: true
        
      end
    end
    
    module LocalInstanceMethods
      
      def change_status
        current_change_request.state if current_change_request
      end
      
      def with_changes
        self.attributes = current_change_request.requested_changes || {}
        self
      end
      
      def submit_changes
        current_change_request.submit
      end
      
      def unsubmit_changes
        current_change_request.unsubmit
      end
      
      def approve_changes
        if with_changes.save_without_change_request
          current_change_request.approve
        end
      end
      
      def reject_changes
        current_change_request.reject
      end
      
      private
      
      def existing_changes
        current_change_request.try(:requested_changes) || {}
      end
      
      def new_changes
        self.attributes.select {|k,v| changed_attributes.keys.include? k}
      end
        
      
      def all_changes
        existing_changes.merge new_changes
      end
      
      def move_changes_to_change_request
        self.current_change_request_attributes = {requested_changes: all_changes}
        self.attributes = self.changed_attributes
      end
      
      def save_with_change_request
        move_changes_to_change_request
        save_without_change_request
      end
      
      def save_with_change_request!
        move_changes_to_change_request
        save_without_change_request!
      end
      
    end
  end
end
 
ActiveRecord::Base.send :include, Approvable::ActsAsApprovable
