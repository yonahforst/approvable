require 'rails_helper'

module Approvable
  describe ActsAsApprovable do
    before(:each) do
      Approvable.auto_approve = false
      @listing = create(:listing, :approved)
    end
    
    context ".acts_as_approvable" do
      it 'responds' do
        expect(Listing).to respond_to :acts_as_approvable
      end
      
      it 'applies changes and auto approves' do
        Approvable.auto_approve = true

        @listing.update(title: 'a brand new title')
        @listing.reload

        expect(@listing.title).to eq 'a brand new title'
      end
      
      it 'works with validation' do
        expect{
          @listing.update!(title: nil)
        }.to raise_error ActiveRecord::RecordInvalid
      end
      
      it 'doesnt track attribute excluded by except option' do
        Listing.class_eval { acts_as_approvable except: :title }

        expect{
          @listing.update(title: 'a brand new title')
        }.not_to change {@listing.change_requests.count}
        @listing.reload

        expect(@listing.title).to eq 'a brand new title'
      end

      it 'doesnt track attribute array excluded by except option' do
        Listing.class_eval { acts_as_approvable except: [:title, :image]}
        expect{
          @listing.update(title: 'a brand new title', image: 'me.jpg')
        }.not_to change {@listing.change_requests.count}
        @listing.reload
        expect(@listing.title).to eq 'a brand new title'
        expect(@listing.image).to eq 'me.jpg'
      end

      it 'doesnt track attribute not included by only option' do
        Listing.class_eval { acts_as_approvable only: :image }

        expect{
          @listing.update(title: 'a brand new title')
        }.not_to change {@listing.change_requests.count}
        @listing.reload

        expect(@listing.title).to eq 'a brand new title'
      end

      it 'doesnt track attributes not included by only array' do
        Listing.class_eval { acts_as_approvable only: [:description, :deleted]}
        expect{
          @listing.update(title: 'a brand new title', image: 'me.jpg')
        }.not_to change {@listing.change_requests.count}
        @listing.reload
        expect(@listing.title).to eq 'a brand new title'
        expect(@listing.image).to eq 'me.jpg'
      end

      it 'tracks attributes not excluded by except' do
        
        Listing.class_eval { acts_as_approvable except: :description }

        expect{
          @listing.update(title: 'a brand new title')
        }.to change {@listing.change_requests.count}.by(1)

        expect(@listing.title).not_to eq 'a brand new title'
      end

      it 'tracks attributes included by only' do
        Listing.class_eval { acts_as_approvable only: :title }

        expect{
          @listing.update(title: 'a brand new title')
        }.to change {@listing.change_requests.count}.by(1)

        expect(@listing.title).not_to eq 'a brand new title'
      end
      
      it 'accepts nested except attribtues' do
        Foobar.class_eval { acts_as_approvable except: [foo: [:image, :title], bar: :description ] }
        
        foobar = Foobar.new(
          foo: {image: 'photo.jpg', title: 'me, on the hill', tags: ['me', 'hill', 'on']}, 
          bar: {description: 'test test test', title: 'blahhhh'}
        )
        
        expect(foobar.foo).to eq({image: 'photo.jpg', title: 'me, on the hill'}.stringify_keys)
        expect(foobar.bar).to eq({description: 'test test test'}.stringify_keys)

        expect(foobar.requested_changes).to match({foo: {tags: ['me', 'hill', 'on']}, bar: {title: 'blahhhh'}}.stringify_keys)
      end
      
      it 'accepts nested only attribtues' do
        Foobar.class_eval { acts_as_approvable only: [foo: [:image, :title], bar: :description ] }
        
        foobar = Foobar.new(
          foo: {image: 'photo.jpg', title: 'me, on the hill', tags: ['me', 'hill', 'on']}, 
          bar: {description: 'test test test', title: 'blahhhh'}
        )
        
        expect(foobar.foo).to eq({tags: ['me', 'hill', 'on']})
        expect(foobar.bar).to eq({title: 'blahhhh'})
        expect(foobar.requested_changes).to match(foo: {image: 'photo.jpg', title: 'me, on the hill'}, bar: {description: 'test test test'} )
      end
      
    end

    it 'has_many change_requests' do
      expect(@listing).to respond_to :change_requests
    end

    context '#apply_changes' do
      it 'responds' do
        expect(@listing).to respond_to :apply_changes
      end

      it 'returns listing with requested changes' do
        @listing.update(title: 'a brand new title')

        @listing.reload

        expect(@listing.title).not_to eq 'a brand new title'
        expect(@listing.apply_changes.title).to eq 'a brand new title'
      end


      it 'returns listing as is if no current_change_request ' do
        expect(@listing.apply_changes.title).to eq @listing.title
      end

    end



    context '#current_change_request' do

      it 'has_one' do
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
      it 'delegates to current_change_request' do
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


      it 'updates a pending change request for a listing' do
        @listing.update title: 'blah blah', description: 'another one'        
        @listing.reload
        expect(@listing.requested_changes).to eq 'title' => 'blah blah', "description" => 'another one'

        expect{
          @listing.update(title: 'new title!!!')
        }.not_to change {@listing.change_requests.count}

        @listing.reload
        expect(@listing.requested_changes).to eq 'title' => 'new title!!!', "description" => 'another one'
        expect(@listing.change_status).to eq 'pending'
      end
      
      it 'reverts changed attribute back to original' do
        original_title = @listing.title
        @listing.update title: 'blah blah', description: 'another one'        
        
        @listing.reload
        expect(@listing.requested_changes).to include "title" => 'blah blah'

        expect{
          @listing.update(title: original_title)
        }.not_to change {@listing.change_requests.count}

        @listing.reload
        expect(@listing.requested_changes).to eq "title" => original_title, "description" => 'another one'
        expect(@listing.change_status).to eq 'pending'
      end

      it 'updates a change request for a rejected listing' do
        @listing.update title: 'blah blah', description: 'another one'

        @listing.submit_changes
        @listing.reject_changes

        expect{
          @listing.update(title: 'a brand new title')
        }.not_to change {@listing.change_requests.count}

        @listing.reload
        expect(@listing.requested_changes).to match "title" => 'a brand new title', 'description' => 'another one'
        expect(@listing.change_status).to eq 'pending'
      end

      it 'keeps previous changes and adds new changes' do
        change_request = create(:change_request, :pending, requested_changes: {"title" => 'a brand new title'}, approvable: @listing )
        @listing.reload

        expect{
          @listing.update(description: 'a hot bod')
        }.not_to change {@listing.change_requests.count}

        change_request.reload
        expect(change_request.requested_changes).to match "title" => 'a brand new title', "description" => 'a hot bod'
        expect(change_request.state).to eq 'pending'
      end

      it 'updates an existing change request for a rejected listing and changes the status to pending' do
        change_request = create(:change_request, :rejected, approvable: @listing )
        @listing.reload

        expect{
          @listing.update(title: 'a brand new title')
        }.not_to change {@listing.change_requests.count}

        change_request.reload

        expect(change_request.requested_changes).to match "title" => 'a brand new title'
        expect(change_request.state).to eq 'pending'
      end
    end

    context '#submit/#unsubmit/#approve/#reject' do
      it 'submits changes' do
        @listing.update(title: 'a brand new title')
        @listing.submit_changes

        expect(@listing.change_status).to eq 'submitted'
        @listing.reload

        expect(@listing.title).not_to eq 'a brand new title'
      end

      it 'unsubmits changes' do
        @listing.update(title: 'a brand new title')
        @listing.submit_changes
        @listing.unsubmit_changes

        expect(@listing.change_status).to eq 'pending'
        @listing.reload

        expect(@listing.title).not_to eq 'a brand new title'
      end

      it 'approves changes' do
        @listing.update(title: 'a brand new title')
        @listing.submit_changes

        @listing.approve_changes
        @listing.reload

        expect(@listing.title).to eq 'a brand new title'
        expect(@listing.current_change_request).to be nil
        expect(@listing.change_status).to eq 'approved'
      end

      it 'rejects changes' do
        @listing.update(title: 'a brand new title')
        @listing.submit_changes
        @listing.reject_changes
        @listing.reload

        expect(@listing.title).not_to eq 'a brand new title'
        expect(@listing.change_status).to eq 'rejected'
      end

      it 'rejects with notes' do
        @listing.update(title: 'a brand new title')
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

      it 'rejects and adds to existing notes' do
        @listing.update(title: 'a brand new title')
        @listing.submit_changes
        @listing.reject_changes(note: 'i dont like it')
        @listing.update(title: 'something else')
        @listing.submit_changes
        sleep 1
        @listing.reject_changes(note: 'even worse!!')

        @listing.reload

        expect(@listing.title).not_to eq 'a brand new title'
        expect(@listing.title).not_to eq 'something else'
        expect(@listing.change_status).to eq 'rejected'

        notes = @listing.change_status_notes
        expect(notes.count).to eq 2
        expect(notes.values.first).to eq 'i dont like it'
        expect(notes.values.last).to eq 'even worse!!'
      end
    end

    
    context '#store_accessor' do
      it 'also captures store_accessor methods' do
        foobar = create(:foobar)
        foobar.update(foo: 'test', bar: 'sets')
        foobar.reload
        
        expect(foobar.foo).to be nil
        expect(foobar.bar).to be nil
        
        foobar.apply_changes
        
        expect(foobar.foo).to eq 'test'
        expect(foobar.bar).to eq 'sets'
        
      end
    end
    
  end
end
