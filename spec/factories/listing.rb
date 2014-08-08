FactoryGirl.define do
  factory :listing do
    sequence(:title) {|n| "Title #{n}"}
    sequence(:description) {|n| "A long description #{n}"}
    
    trait :approved do
      after(:create) do |listing|
        listing.submit_changes
        listing.approve_changes
        listing.reload
      end
    end
    
  end
end
