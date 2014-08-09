# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :change_request, :class => 'Approvable::ChangeRequest' do
    association :approvable, factory: [:listing, :approved]
    requested_changes {{title: "new_#{approvable.title}"}}


    trait :approved do
      after(:create) {|c| c.submit!; c.approve!}
    end

    trait :pending do
    end
    
    trait :submitted do
      after(:create) {|c| c.submit!}
    end
    
    trait :rejected do
      after(:create) {|c| c.submit!; c.reject!}
    end

        
    # trait :pending do
    #   submitted_at nil
    #   approved_at nil
    #   rejected_at nil
    # end
    #
    # trait :submitted do
    #   submitted_at {Time.now}
    #   approved_at nil
    #   rejected_at nil
    # end
    #
    # trait :approved do
    #   submitted_at {Time.now}
    #   approved_at {Time.now}
    #   rejected_at nil
    # end
    #
    # trait :rejected do
    #   submitted_at {Time.now}
    #   approved_at nil
    #   rejected_at {Time.now}
    # end
    
  end
end
