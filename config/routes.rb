Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
      post "auth/session", to: "auth/sessions#create"

      get "me", to: "me#show"
      patch "me", to: "me#update"
      delete "me", to: "me#destroy"
      namespace :me do
        resources :addresses, only: [ :index, :create, :show, :update, :destroy ]
        resource :preferences, only: [ :show, :update ]
        resources :orders, only: [ :index, :show ]
        resources :invoices, only: [ :index, :show ] do
          member do
            get :download
          end
        end
      end

      namespace :catalog do
        get "categories", to: "categories#index"
        get "products", to: "products#index"
        get "products/:id", to: "products#show"
      end

      get "cart", to: "cart#show"
      post "cart/items", to: "cart_items#create"
      patch "cart/items/:id", to: "cart_items#update"
      delete "cart/items/:id", to: "cart_items#destroy"

      post "orders", to: "orders#create"
      get "orders/:id", to: "orders#show"
      get "orders/:id/status", to: "orders#status"

      namespace :admin do
        namespace :dashboard do
          resource :summary, only: [ :show ], controller: :summaries
        end

        namespace :exports do
          get "orders", to: "orders#csv"
          get "invoices", to: "invoices#csv"
          get "products", to: "products#csv"
        end

        resources :audit_logs, only: [ :index, :show ]

        resources :orders, only: [ :index ] do
          member do
            patch :status
          end
        end
        resources :reviews, only: [ :index ] do
          member do
            patch :status
          end
        end
        resources :invoices, only: [ :index, :show ]
        resources :quotes, only: [ :index, :show ] do
          member do
            patch :status
          end
        end
        resources :products, only: [ :index, :create, :show, :update, :destroy ]
      end

      post "contact", to: "contacts#create"
      resources :quotes, only: [ :create ]
      resources :reviews, only: [ :index, :create ]
      post "reviews/:id/report", to: "reviews#report", as: :report_review

      post "payments/session", to: "payments#create_session"
      post "payments/:order_id/retry", to: "payments#retry", as: :retry_payment
      post "payments/webhook", to: "stripe_webhooks#create"
    end
  end

  # Web routes (non-API)
  root "home#index"

  namespace :admin do
    root "dashboard#show"
    get "dashboard", to: "dashboard#show"
    resource :business_settings, only: [ :show, :update ]
    resources :orders, only: [ :index, :show ] do
      collection do
        patch :bulk_status
      end
      member do
        patch :status
      end
    end
    resources :products do
      collection do
        patch :bulk_update
      end
    end
    resources :quotes, only: [ :index, :show ] do
      collection do
        patch :bulk_status
      end
      member do
        patch :status
      end
    end
    resources :reviews, only: [ :index, :show ] do
      collection do
        patch :bulk_status
      end
      member do
        patch :status
      end
    end
    resources :invoices, only: [ :index, :show ]
    resources :audit_logs, only: [ :index, :show ]
  end

  # Auth
  get "login", to: "auth#login"
  post "auth/login", to: "auth#create"
  get "register", to: "auth#register"
  post "auth/register", to: "auth#register_create"
  post "logout", to: "auth#logout"

  # Catalog
  get "catalog", to: "catalog#index"
  get "products/:id", to: "catalog#show", as: :product

  # Cart
  get "cart", to: "cart#show"
  post "cart/items", to: "cart#add_item", as: :cart_items
  patch "cart/items/:id", to: "cart#update_item", as: :cart_item
  delete "cart/items/:id", to: "cart#remove_item"

  # Checkout
  get "checkout", to: "checkout#show"
  post "orders", to: "checkout#create"
  post "orders/:id/retry-payment", to: "checkout#retry_payment", as: :order_retry_payment
  get "orders/:id/success", to: "checkout#success", as: :order_success
  get "orders/:id/cancel", to: "checkout#cancel", as: :order_cancel

  # Account
  get "me", to: "me#show", as: :me
  get "me/edit", to: "me#edit", as: :edit_me
  patch "me", to: "me#update"
  get "me/orders", to: "me#orders", as: :me_orders
  get "me/orders/:id", to: "me#order", as: :me_order
  get "me/invoices", to: "me#invoices", as: :me_invoices
  get "me/invoices/:id", to: "me#invoice", as: :me_invoice
  get "me/invoices/:id/download", to: "me#download_invoice", as: :download_me_invoice
  get "me/addresses", to: "me#addresses", as: :me_addresses
  get "me/addresses/new", to: "me#add_address", as: :me_new_address
  post "me/addresses", to: "me#create_address", as: :me_create_address
  get "me/addresses/:id/edit", to: "me#edit_address", as: :me_edit_address
  patch "me/addresses/:id", to: "me#update_address", as: :me_update_address
  delete "me/addresses/:id", to: "me#delete_address", as: :me_delete_address
  get "me/preferences", to: "me#preferences", as: :me_preferences
  patch "me/preferences", to: "me#update_preferences", as: :me_update_preferences

  # Contact, Reviews
  get "mentions-legales", to: "legal#mentions_legales", as: :mentions_legales
  get "politique-confidentialite", to: "legal#politique_confidentialite", as: :politique_confidentialite
  get "conditions-generales", to: "legal#conditions_generales", as: :conditions_generales

  get "contact", to: "contacts#new"
  post "contacts", to: "contacts#create"
  get "reviews", to: "reviews#index"
  get "reviews/new", to: "reviews#new", as: :new_review
  post "reviews", to: "reviews#create"
  get "reviews/:id/edit", to: "reviews#edit", as: :edit_review
  patch "reviews/:id", to: "reviews#update"
  delete "reviews/:id", to: "reviews#destroy", as: :review

  # Fallback for unknown routes
  match "*path", to: "application#not_found", via: :all
end
