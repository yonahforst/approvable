require 'rails_helper'

module Approvable
  describe ActsAsApprovable do
    before do
      @listing = create(:listing, :approved)
    end
    
    it 'responds to acts_as_approvable to class' do
      expect(Listing).to respond_to :acts_as_approvable
    end
    
    it 'has_many change_requests' do
      expect(@listing).to respond_to :change_requests
    end
        
    context '#apply_changes' do
      it 'responds to apply_changes method' do
        expect(@listing).to respond_to :apply_changes
      end
      
      it 'returns listing with requested changes' do
        @listing.update(title: 'a brand new title')

        expect(@listing.title).not_to eq 'a brand new title'      
        expect(@listing.apply_changes.title).to eq 'a brand new title'
      end
      
      
      it 'returns listing as is if no current_change_request ' do
        expect(@listing.apply_changes.title).to eq @listing.title
      end
    end
    

    
    context '#current_change_request' do
      
      it 'has_one current_change_request' do
        expect(@listing).to respond_to :current_change_request
      end
      
    
      it 'returns last unapproved change request' do
        create(:change_request, :approved, approvable: @listing )
        create(:change_request, :approved, approvable: @listing )
        change_request = create(:change_request, :submitted, approvable: @listing )
        @listing.reload
      
        expect(@listing.current_change_request).to eq change_request
      end
    
      it 'returns nil if no unapproved change request' do
        create(:change_request, :approved, approvable: @listing )
        create(:change_request, :approved, approvable: @listing )
      
        expect(@listing.current_change_request).to be nil
      end
    
    end

    context '#change_status' do
      
      
    
      it 'delegates change_status to current_change_request' do
        create(:change_request, :approved, approvable: @listing )
        create(:change_request, :submitted, approvable: @listing )
        @listing.reload
      
        expect(@listing.change_status).to eq 'submitted'
      end
    
      it 'returns approved if no current_change_request' do
        create(:change_request, :approved, approvable: @listing )
        create(:change_request, :approved, approvable: @listing )
      
        expect(@listing.change_status).to eq 'approved'
      end
    end
    
    context '#save/#update' do
    
      it 'wont create a new change request if there is a current one' do
        create(:change_request, :approved, approvable: @listing )
        create(:change_request, :approved, approvable: @listing )
        create(:change_request, :submitted, approvable: @listing )
      
        expect{
          create(:change_request, :submitted, approvable: @listing )
        }.to raise_error ActiveRecord::RecordInvalid
      end

      it 'creates a new change request for an new listing' do
        expect{
          @listing.update(title: 'a brand new title')
        }.to change {@listing.change_requests.count}.by(1)
      end
    

    
      it 'creates a new change request for an approved listing and doesnt change exiting' do
        change_request = create(:change_request, :approved, approvable: @listing )
        expect{
          @listing.update(title: 'a brand new title')
        }.to change {@listing.change_requests.count}.by(1)
      
        change_request.reload      
        expect(change_request.changed_attributes).not_to match title: 'a brand new title'
      end
      
    
    it 'updates a pending change request for a pending listing' do
        change_request = create(:change_request, :pending, approvable: @listing )
        @listing.reload
      
        expect{
          @listing.update(title: 'a brand new title')
        }.not_to change {@listing.change_requests.count}

        change_request.reload      
        expect(change_request.requested_changes).to match "title" => 'a brand new title'
        expect(change_request.state).to eq 'pending'
      end
    
      it 'keeps previous changes and adds new changes' do
        change_request = create(:change_request, :pending, requested_changes: {"title" => 'a brand new title'}, approvable: @listing )
        @listing.reload
      
        expect{
          @listing.update!(description: 'a hot bod')
        }.not_to change {@listing.change_requests.count}

        change_request.reload      
        expect(change_request.requested_changes).to match "title" => 'a brand new title', "description" => 'a hot bod'
        expect(change_request.state).to eq 'pending'
      end
    
      it 'cant update an existing listing if a change is already submitted' do
        change_request = create(:change_request, :submitted, approvable: @listing )
        @listing.reload
      
        expect{
          @listing.update!(title: 'a brand new title')
          puts change_request.errors.full_messages.inspect
          puts @listing.errors.full_messages.inspect
        
        }.to raise_error ActiveRecord::RecordInvalid
      
        change_request.reload
        expect(change_request.requested_changes).not_to match "title" => 'a brand new title'
        expect(change_request.state).to eq 'submitted'
      end
    
      it 'updates an existing change request for a rejected listing and changes the status to pending' do
        change_request = create(:change_request, :rejected, approvable: @listing )
        @listing.reload
      
        expect{
          @listing.update!(title: 'a brand new title')
        }.not_to change {@listing.change_requests.count}

        change_request.reload
      
        expect(change_request.requested_changes).to match "title" => 'a brand new title'
        expect(change_request.state).to eq 'pending'
      end
    end
    
    context '#submit/#unsubmit/#approve/#reject' do
      it 'submits changes' do
        @listing.update!(title: 'a brand new title')
        @listing.submit_changes
      
        expect(@listing.change_status).to eq 'submitted'
        @listing.reload
      
        expect(@listing.title).not_to eq 'a brand new title'
      end
    
      it 'unsubmits changes' do
        @listing.update!(title: 'a brand new title')
        @listing.submit_changes
        @listing.unsubmit_changes
      
        expect(@listing.change_status).to eq 'pending'
        @listing.reload
      
        expect(@listing.title).not_to eq 'a brand new title'
      end
    
      it 'approves changes' do
        @listing.update!(title: 'a brand new title')
        @listing.submit_changes
            
        @listing.approve_changes
        @listing.reload
      
        expect(@listing.title).to eq 'a brand new title'
        expect(@listing.current_change_request).to be nil
        expect(@listing.change_status).to eq 'approved'
      end
    
      it 'rejects changes' do
        @listing.update!(title: 'a brand new title')
        @listing.submit_changes
        @listing.reject_changes
        @listing.reload
      
        expect(@listing.title).not_to eq 'a brand new title'
        expect(@listing.change_status).to eq 'rejected'
      end
      
      it 'rejects with notes' do
        @listing.update!(title: 'a brand new title')
        @listing.submit_changes
        @listing.reject_changes(note: 'i dont like it')
        @listing.reload
      
        expect(@listing.title).not_to eq 'a brand new title'
        expect(@listing.change_status).to eq 'rejected'
        
        notes = @listing.change_status_notes
        expect(notes).to be_kind_of Hash
        expect(Time.parse(notes.keys.first)).to be_kind_of Time
        expect(notes.values.first).to eq 'i dont like it'        
      end
    end
    
    context '#_with_changes' do
      it 'returns attribtue with new value' do
        @listing.update!(title: 'a brand new title')
        expect(@listing.title).not_to eq 'a brand new title'
        expect(@listing.title_with_changes).to eq 'a brand new title'
      end
      
      it 'returns existing value it unchanged' do
        @listing.update!(title: 'a brand new title')
        expect(@listing.description_with_changes).to eq @listing.description
      end
      
      it 'returns existing value if no current_change_request' do
        expect(@listing.title_with_changes).to eq @listing.title_with_changes
      end
    end
    
    
  end
end
