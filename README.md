# Approvable
### Approve changes to a models attributes before they are applied

Supports: Rails 4.1 + Postgres

### Why
Users can update objects through the web but you want administrators to approve all changes before they are applied.

### What
```ruby
class Article < ActiveRecord::Base
  acts_as_approvable
end

article = Article.create(title: 'food') #=> #<Article id: 1, title: nil>
article #=> #<Article id: 1, title: nil>
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

#### How

Approvable works by aliasing `assign_attributes` and `attributes=` to `assign_attributes_with_change_request`. (the old `assign_attribtues` method can still be accessed via `assign_attributes_without_change_request`).

After this alias, all parameters passed to either `assign_attributes` or `attributes=` will be stored in a JSON column on the change_request table. When the change request is approved, those attributes are applied to the model instance and saved.

This is intended to work with web forms, where changes are submitted as a parameter hash.

Caveat 1: only works with attribute values that can be serialized into json. For images and other file attachemnts, you can create a new column in your model (i.e. 'approved_image') then do something like this:
```
  class Article < ActiveRecord::Base
  .....
    mount_uploader :image, ImageUploader 
    mount_uploader :approved_image, ImageUploader 
    
    def approve_changes_with_images
      transaction do
        approve_changes_without_images
        approve_image
      end
    end
    
    alias_method_chain :approve_changes, :images
    
    def approve_image
      if image.present? && update(remote_approved_image_url: image.url)
        remove_image!
        save
      end
    end
  ......
  end
```

Caveat 2: only overrides methods that use `assign_attributes` underneath (such as `update`). Assigning attributes directly via `some_attribute = 'foobar'` will skip the change request process.


#### Some handy methods
```ruby
article = Article.first
article.foo #=> 'food'
article.change_status #=> nil

    mount_uploader :approved_image, ImageUploader 
    
    def approve_image
      if image.present? && update(remote_approved_image_url: image.url)
        self.remove_image!
        self.save
      end
    end
  #Making a change
article.update(title: 'the beach') #=> true
article.title #=> 'food'
article.change_request[:title] #=> 'the beach'
article.change_status #=> 'pending'

  #Making another change
article.update(title: 'space and time') #=> true
article.title #=> 'food'
article.change_request[:title] #=> 'space and time'
article.change_status #=> 'pending'

  # Submitting changes
article.submit_changes #=> true
article.change_status #=> 'submitted'

  # Unsubmitting changes
aritlce.unsubmit_changes #=> true
article.update(title: 'hipster beards') #=> true
article.title #=> 'food'
article.change_request[:title] #=> 'hipster beards'

  # Rejecting changes
article.reject_changes #=> true
article.change_status #=> 'rejected'

  # Resubmitting changes
article.change_status #=> 'rejected'
article.update(title: 'fixies and coffee')
article.title #=> 'food'
article.change_request[:title] #=> 'fixies and coffee'
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
