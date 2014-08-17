require 'rails_helper'

module Approvable
  describe ChangeRequest, :type => :model do
    
    before(:each) {@request = create(:change_request)}
    
    
    it 'creates a change request as pending' do
      expect(@request.state).to eq 'pending'
    end
    
    # it 'wont create new request unless all others are approved' do
    #   approvable = @request.approvable
    #   expect{create(:change_request, approvable: approvable)}.to raise_error ActiveRecord::RecordInvalid
    #
    #   @request.submit!
    #   expect{create(:change_request, approvable: approvable)}.to raise_error ActiveRecord::RecordInvalid
    #
    #   @request.reject!
    #   expect{create(:change_request, approvable: approvable)}.to raise_error ActiveRecord::RecordInvalid
    #
    #   @request.submit!
    #   @request.approve!
    #   expect{create(:change_request, approvable: approvable)}.not_to raise_error
    # end
    #
    # it 'cannot update requested_changes once submitted' do
    #   @request.submit!
    #   expect{
    #     @request.update!(requested_changes: {title: 'a brand new title'})
    #   }.to raise_error ActiveRecord::RecordInvalid
    # end
    #
    # it 'cannot update requested_changes once approved' do
    #   @request.submit!
    #   @request.approve!
    #   expect{
    #     @request.update!(requested_changes: {title: 'a brand new title'})
    #   }.to raise_error ActiveRecord::RecordInvalid
    # end
    
    it 'cannot transition out of approved' do
      @request.submit!
      @request.approve!
      
      expect{@request.reject!}.to raise_error AASM::InvalidTransition
      expect{@request.submit!}.to raise_error AASM::InvalidTransition
      expect{@request.unreject!}.to raise_error AASM::InvalidTransition
    end
    
    it 'rejected reverts to pending after changed_attributes change' do
      @request.submit!
      @request.reject!
      @request.update(requested_changes: {title: 'a brand new title'})
      
      expect(@request.state).to eq 'pending'
    end
    
  end
end
