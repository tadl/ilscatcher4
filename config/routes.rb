Rails.application.routes.draw do
  root 'main#index'
  match 'index', to: 'main#index', as: 'index', via: [:get, :post]
  match 'search', to: 'search#search', as: 'search', via: [:get, :post]
  match 'details', to: 'item#details', as: 'details', via: [:get, :post]
  match 'login', to: 'user#login', as: 'login', via: [:get, :post]

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
