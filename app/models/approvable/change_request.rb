module Approvable
  class ChangeRequest < ActiveRecord::Base
    belongs_to :approvable, :dependent => :destroy, :polymorphic => true
    belongs_to :approver, :polymorphic => true

    validate :no_outstanding_change_requests, on: :create
    validate :not_submitted_or_approved, if: :requested_changes_changed?

    after_save :update_rejected_to_pending, if: :requested_changes_changed?
    
    scope :unapproved, -> {where.not(state: 'approved')}
    
    state_machine :initial => :pending do        
      event :submit do
        transition [:rejected, :pending] => :submitted
      end
      
      event :unsubmit do
        transition :submitted => :pending
      end

      event :approve do
        transition :submitted => :approved
      end

      event :reject do
        transition :submitted => :rejected
      end
      
      event :unreject do
        transition :rejected => :pending
      end
    end
    
    private
    
    def not_submitted_or_approved
      if approved? || submitted? 
        errors.add(:base, "cannot change a #{state} request")
      end
    end
    
    def no_outstanding_change_requests
      if self.class.where(approvable: approvable).unapproved.any?
        errors.add(:base, 'please use the existing change request')
      end  
    end
    
    def update_rejected_to_pending
      if rejected?
        unreject
      end
    end
    
        
  end
end
