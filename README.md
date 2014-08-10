# Approvable
### Approve changes to a models attributes before they are applied

Supports: Rails 4.1 + Postgres

### Why
Users can update various database record but you want administrators to approve all changes before they are applied.

### How
```ruby
class Article < ActiveRecord::Base
  acts_as_approvable
end

article = Article.create(title: 'food') #=> #<Article id: 1, title: nil>
article #=> #<Article id: 1, title: nil>
article.with_changes #=> #<Article id: 1, title: 'food'>
article.submit_changes #=> true
article.approve_changes #=> true 
article #=> #<Article id: 1, title: 'food'>
```

Here's the approval process:
```
pending --> submitted --> approved
              OR      --> rejected --> pending -->  ...
              OR      --> unsubmitted --> pending --> ...
```

When an object is submitted, it's attributes cannot be modified (will raise a validtion error on save)

#### Some handy methods
```ruby
article = Article.first
article.foo #=> 'food'
article.change_status #=> nil

  #Making a change
article.title = 'the beach' #=> 'the beach'
article.save #=> true
article.title #=> 'food'
article.with_changes.title #=> 'the beach'
article.change_status #=> 'pending'

  #Making another change
article.update(title: 'space and time') #=> true
article.title #=> 'food'
article.with_changes.title #=> 'space and time'
article.change_status #=> 'pending'

  # Submitting changes
article.submit_changes #=> true
article.change_status #=> 'submitted'

  # Updating after submit
article.update(title: 'hipster beards') #=> false
article.errors #=> {:"current_change_request.base"=>["cannot change a submitted request"]} 

  # Unsubmitting changes
aritlce.unsubmit_changes #=> true
article.update(title: 'hipster beards') #=> true
article.title #=> 'food'
article.with_changes.title #=> 'hipster beards'

  # Rejecting changes
article.reject_changes #=> true
article.change_status #=> 'rejected'

  # Resubmitting changes
article.change_status #=> 'rejected'
article.update(title: 'fixies and coffee')
article.title #=> 'food'
article.with_changes.title #=> 'fixies and coffee'
article.change_status #=> 'pending'
article.submit_changes #=> true
article.change_status #=> 'submitted'


# Approving changes
article.title #=> 'food'
article.approve_changes #=> true
article.title #=> 'fixies and coffee'
article.change_status #=> nil
```

TODO:

write tests for earlier versions of rails
serialize changes in a text field for non-postgres dbs
add reject messages



This project rocks and uses MIT-LICENSE.
