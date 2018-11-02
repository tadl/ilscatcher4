Rails.application.routes.draw do
  root 'main#index'
  match 'index', to: 'main#index', as: 'index', via: [:get, :post]
  match 'search', to: 'search#search', as: 'search', via: [:get, :post]
  match 'details', to: 'item#details', as: 'details', via: [:get, :post]
  match 'login', to: 'user#login', as: 'login', via: [:get, :post]
  match 'logout', to: 'user#logout', as: 'logout', via: [:get, :post]
  match 'checkouts', to: 'user#checkouts', as: 'checkouts', via: [:get, :post]
  match 'renew_checkouts', to: 'user#renew_checkouts', as: 'renew_checkouts', via: [:get, :post]
  match 'holds', to: 'user#holds', as: 'holds', via: [:get, :post]
  match 'place_hold', to: 'user#place_hold', as: 'place_hold', via: [:get, :post]
  match 'preferences', to: 'user#preferences', as: 'preferences', via: [:get, :post]
  match 'missing_token', to: 'user#missing_token', as: 'missing_token', via: [:get, :post]
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
