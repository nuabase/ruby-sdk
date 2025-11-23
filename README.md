# Nuabase Ruby SDK

Nuabase turns LLM prompts into type-safe functions and call them directly from your front-end. Set up your free account
now at [Nuabase](https://nuabase.com).

This is the Ruby SDK that is intended only to generate short-lived JWT tokens, to be passed to the Nuabase front-end
SDK [Nuabase TypeScript SDK](https://github.com/nuabase/ts-sdk). This will let you use Nuabase directly from your
front-end to make typed LLM requests.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add nuabase

## Usage

### Prerequisites

Obtain a Signing Key Secret from the [Nuabase Console](https://console.nuabase.com/dashboard/signing-keys/new).

This key is a secret and must be stored securely on your backend server. It must **not** be exposed to the client-side
code. We recommend storing it as an encrypted Rails credential or as an environment variable named
`NUABASE_SIGNING_KEY_SECRET`.

The Signing Key Secret is used by your backend to generate short-lived JWT tokens via this SDK.

### Basic Usage

```ruby
require 'nuabase'

# Initialize the generator with your signing key secret and the user ID
generator = Nuabase::NuaTokenGenerator.new(
  signing_key_secret: 'pk_...', # Your Nuabase Signing Key Secret
  user_id: 'user_123' # The ID of the user in your system
)

# Generate the token
token_data = generator.generate

# token_data is a Hash containing:
# {
#   access_token: "eyJhbGci...",
#   expires_in: 180,
#   expires_at: 1732398765
# }
puts token_data[:access_token]
```

### Rails Integration

You can integrate Nuabase into your Rails application by creating a controller to serve the token.

1. Add the route in `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  # ... other routes

  namespace :nuabase, path: ".well-known/nuabase", defaults: { format: :json } do
    resource :token, only: :create
  end
end
```

2. Create the controller `app/controllers/nuabase/tokens_controller.rb`:

```ruby

module Nuabase
  class TokensController < ApplicationController
    # IMPORTANT: Ensure the user is authenticated.
    # Replace `authenticate_user!` with your application's authentication filter.
    before_action :authenticate_user!

    def create
      # Replace `current_user` with whatever object stores the authenticated user in your app
      token = Nuabase::NuaTokenGenerator.new(
        user_id: current_user.id,
        signing_key_secret: ENV['NUABASE_SIGNING_KEY_SECRET']
      ).generate

      render json: token, status: :ok
    end
  end
end
```

## Workflow

The typical workflow is:

1. Expose an endpoint on your backend (e.g., `POST /.well-known/nuabase/token`).
2. **IMPORTANT**: This endpoint MUST be authenticated. You must verify the user's identity before generating a token. Do
   not expose this endpoint publicly.
3. Your frontend, loaded by an authenticated user, calls this endpoint.
4. Your backend uses the Nuabase SDK to generate a token for that specific user.
5. The frontend receives the token and uses it to directly make authenticated LLM calls to the Nuabase server, using
   the [Nuabase TypeScript SDK](https://github.com/nuabase/ts-sdk).

### Token Expiration and Automatic Refresh

Tokens expire after 180 seconds by default. You can override the TTL by passing `expiry_seconds:` when instantiating
`Nuabase::NuaTokenGenerator`:

```ruby
token_data = Nuabase::NuaTokenGenerator.new(
  signing_key_secret: 'pk_...',
  user_id: 'user_123',
  expiry_seconds: 300 # token will last for 5 minutes
).generate
```

Keep the expiration short, to prevent abuse of leaked token. The Nuabase TypeScript SDK will automatically refresh the
token when it expires.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nuabase/ruby-sdk
