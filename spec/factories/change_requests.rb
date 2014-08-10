# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :change_request, :class => 'Approvable::ChangeRequest' do
    association :approvable, factory: [:listing, :approved]
    requested_changes {{title: "new_#{approvable.title}"}}


    trait :approved do
      state :approved
    end

    trait :pending do
      state :pending
      
    end
    
    trait :submitted do
      state :submitted
    end
    
    trait :rejected do
      state :rejected
    end
    
  end
end
