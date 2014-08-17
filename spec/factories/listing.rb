FactoryGirl.define do
  factory :listing do
    sequence(:title) {|n| "Title #{n}"}
    sequence(:description) {|n| "A long description #{n}"}
    
    trait :approved do
      after(:create) do |listing|
        listing.submit_changes
        listing.approve_changes
      end
    end
    
  end
  
  factory :foo do
    sequence(:title) {|n| "Title #{n}"}    
  end
  
  factory :bar do
    sequence(:title) {|n| "Title #{n}"}    
  end
  
  factory :foobar do
    json_hash {{}}
  end
end
