module Approvable
  class ChangeRequest < ActiveRecord::Base
    belongs_to :approvable, :polymorphic => true
    belongs_to :approver, :polymorphic => true

    validate :no_outstanding_change_requests, on: :create
    # validate :not_submitted_or_approved, if: :requested_changes_changed?

    after_save :update_rejected_to_pending, if: :requested_changes_changed?
    
    scope :unapproved, -> {where.not(state: 'approved')}
    
    include AASM
    
    aasm column: :state do
      
      state :pending, :initial => true
      state :submitted
      state :rejected
      state :approved
      
      event :submit do
        transitions from: [:rejected, :pending], to: :submitted
      end
      
      event :unsubmit do
        transitions from: :submitted, to: :pending
      end

      event :approve do
        transitions from: :submitted, to: :approved
      end
      
      event :reject do
        transitions from: :submitted, to: :rejected, :on_transition => Proc.new {|obj, *args| obj.transition_options(*args)}
      end
      
      event :unreject do
        transitions from: :rejected, to: :pending
      end
    end
    
    def transition_options(options = {})
      note = options[:note] if options
      self.notes_will_change! if note
      self.notes ||= {}
      self.notes[Time.now.to_s] = note if note      
    end
    
    private
    
    def not_submitted_or_approved
      if ['approved', 'submitted'].include? state_was
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
        unreject!
      end
    end
    
        
  end
end
