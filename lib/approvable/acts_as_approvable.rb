module Approvable
  module ActsAsApprovable
    extend ActiveSupport::Concern
 
    included do
    end
 
    module ClassMethods
      def acts_as_approvable **options
        unless Approvable.disabled == true 
        
          include Approvable::ActsAsApprovable::LocalInstanceMethods

          has_many :change_requests, as: :approvable, class_name: 'Approvable::ChangeRequest', dependent: :destroy
          has_one :current_change_request, -> {where.not(state: 'approved') }, as: :approvable, class_name: 'Approvable::ChangeRequest', autosave: true

          validate :changes_are_not_submitted
          
          around_save :move_changes_to_change_request

          amoeba {enable}
        
          cattr_accessor :ignored_attrs
          cattr_accessor :approvable
          self.ignored_attrs = [*options[:except]] + [:id, :created_at, :updated_at]
          self.ignored_attrs = self.attribute_names.map(&:to_sym) - [*options[:only]] if options[:only]
          self.ignored_attrs.map!(&:to_s)
        end
      end
      
      def approvable_associations
        self.reflect_on_all_associations.select do |a| 
          [:has_many, :has_one].include?(a.macro) && a.klass.respond_to?(:approvable)
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
        # current_change_request.requested_changes.each do |attr_name, value|
        #   write_attribute attr_name, value, true
        # end if current_change_request
        self.assign_attributes requested_changes
        associated_approvable_records.each(&:apply_changes)
        self
      end
      
      def associated_approvable_records
        self.class.approvable_associations.inject([]) do |array, associaton|
          array = array + [*self.send(associaton.name)]
        end
      end
      
      def preview_changes
        dup = self.amoeba_dup
        dup.apply_changes.readonly!
        dup
      end
      
      def submit_changes
        transaction do
          current_change_request.submit! if current_change_request
          associated_approvable_records.each(&:submit_changes)
          reload
        end 
      end
      
      def unsubmit_changes
        transaction do
          current_change_request.unsubmit! if current_change_request
          associated_approvable_records.each(&:unsubmit_changes)
          reload
        end
      end
      
      def approve_changes
        transaction do
          current_change_request.approve! if current_change_request
          apply_changes.save!
          associated_approvable_records.each(&:approve_changes) #each {|a| a.change_request.approve!}
          reload
        end
      end
      
      def reject_changes options = {}
        current_change_request.reject! :rejected, options if current_change_request
        reload
      end
      
      def write_attribute attr_name, value
        if current_change_request
          current_change_request.requested_changes = requested_changes.except(attr_name.to_s)
        end
        
        super attr_name, value
      end

      private

      def method_missing(meth, *args, &block)
        if meth.to_s =~ /^(.+)_with_changes$/
          _with_changes($1, *args, &block)

        else
          super # You *must* call super if you don't handle the
                # method, otherwise you'll mess up Ruby's method
                # lookup.
        end
      end

      def _with_changes name, *args, &block
        if current_change_request && new_value = current_change_request.requested_changes[name]
          new_value
        else
          send name, *args, &block
        end
      end

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
        approvable_attributes = all_changes.except(*self.class.ignored_attrs)
        if approvable_attributes.any?
          current_change_request || build_current_change_request
          current_change_request.requested_changes = approvable_attributes
          old_values = self.changed_attributes.except(*self.class.ignored_attrs)          
        end
        yield
        self.update_columns(old_values) if old_values && old_values.any? && !current_change_request.approved? 
      end
      
      def changes_are_not_submitted
        ignored_attrs = self.class.ignored_attrs
  
        if change_status == 'submitted' && changed_attributes.except(*ignored_attrs).any?
          changed_attributes.except(*ignored_attrs).keys.each do |attribute|
            errors.add(attribute, 'Cannot make changes once submitted for approval.')
          end
        end
      end
      
    end
  end
end
 
ActiveRecord::Base.send :include, Approvable::ActsAsApprovable
