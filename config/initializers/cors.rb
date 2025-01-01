Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow requests from the frontend app running on localhost:4200 (development)
    origins 'http://localhost:4200'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end

  allow do
    # Allow requests from api.unishala.in (production or staging)
    origins 'https://www.unishala.in'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
