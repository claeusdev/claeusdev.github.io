---
layout: "post"
date: 2023-08-20
title: "Filtering Sensitive Data in Ruby on Rails with ActiveSupport::ParameterFilter"
categories: "rails"
---

When developing Rails applications, it's common to log requests and responses to diagnose issues or monitor the application. However, some data, like passwords or API keys, is sensitive and should never be exposed in logs. Thankfully, Rails provides `ActiveSupport::ParameterFilter` to help!

## What is ActiveSupport::ParameterFilter?

`ActiveSupport::ParameterFilter` is a utility that allows developers to specify a list of parameters to be filtered out. When a key matches any of the specified filters, its value is replaced with "[FILTERED]".

## How to use it?

Using `ActiveSupport::ParameterFilter` is straightforward:

```rb
filter = ActiveSupport::ParameterFilter.new([:password, :api_key])

filtered_params = filter.filter({
username: 'alice',
password: 'supersecret',
api_key: 'my_api_key',
email: 'alice@example.com'
})

puts filtered_params

# => {:username=>"alice", :password=>"[FILTERED]", :api_key=>"[FILTERED]", :email=>"alice@example.com"}
```

## Advanced Filtering

Beyond simple key matching, `ActiveSupport::ParameterFilter` supports:

1. **Regular Expressions**: Match keys based on patterns.

   ```ruby
   filter = ActiveSupport::ParameterFilter.new([/token/i, :password])
   ```

2. **Custom Replacement**: Replace matched parameters with a custom value.

   ```ruby
   filter = ActiveSupport::ParameterFilter.new(password: ->(original_value) { "REDACTED" })
   ```

## Parameter Filtering in Rails

Rails developers might be familiar with `config.filter_parameters` in the application's configuration. This uses `ActiveSupport::ParameterFilter` behind the scenes.

For instance, in a Rails application:

```ruby
# config/application.rb
config.filter_parameters += [:password, :token, /credit_card/]
```

By default, Rails will filter out any parameter named `password`.

## Conclusion

`ActiveSupport::ParameterFilter` is a handy utility for protecting sensitive data in your Rails applications. Whether you're manually filtering parameters or relying on Rails' built-in configurations, it's essential to ensure that sensitive data remains confidential and out of logs. Always review which parameters are being filtered and update them as needed to maintain application security.

[Read more about this class](https://api.rubyonrails.org/classes/ActiveSupport/ParameterFilter.html)
