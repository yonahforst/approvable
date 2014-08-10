FactoryGirl.define do
  factory :listing do
    sequence(:title) {|n| "Title #{n}"}
    sequence(:description) {|n| "A long description #{n}"}
    
    trait :approved do
    end
    
  end
end
