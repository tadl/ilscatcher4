Rails.application.routes.draw do
  root 'main#index'
  match 'index', to: 'main#index', as: 'index', via: [:get, :post]
  match 'search', to: 'search#search', as: 'search', via: [:get, :post]
  match 'details', to: 'item#details', as: 'details', via: [:get, :post]
  match 'marc_record', to: 'item#marc_record', as: 'marc_record', via: [:get, :post]
  match 'youtube_trailer', to: 'item#youtube_trailer', as: 'youtube_trailer', via: [:get, :post]
  match 'login', to: 'user#login', as: 'login', via: [:get, :post]
  match 'sign_in', to: 'user#sign_in', as: 'sign_in', via: [:get, :post]
  match 'login_and_place_hold', to: 'user#login_and_place_hold', as: 'login_and_place_hold', via: [:get, :post]
  match 'logout', to: 'user#logout', as: 'logout', via: [:get, :post]
  match 'all_account', to: 'user#all_account', as: 'all_account', via: [:get, :post]
  match 'checkouts', to: 'user#checkouts', as: 'checkouts', via: [:get, :post]
  match 'renew_checkouts', to: 'user#renew_checkouts', as: 'renew_checkouts', via: [:get, :post]
  match 'checkout_history', to: 'user#checkout_history', as: 'checkout_history', via: [:get, :post]
  match 'holds', to: 'user#holds', as: 'holds', via: [:get, :post]
  match 'holds_pickup', to: 'user#holds', as: 'holds_pickup', via: [:get, :post], defaults: { ready: 'true' }
  match 'place_hold', to: 'user#place_hold', as: 'place_hold', via: [:get, :post]
  match 'manage_hold', to: 'user#manage_hold', as: 'manage_hold', via: [:get, :post]
  match 'change_hold_pickup', to: 'user#change_hold_pickup', as: 'change_hold_pickup', via: [:get, :post]
  match 'preferences', to: 'user#preferences', as: 'preferences', via: [:get, :post]
  match 'update_preferences', to: 'user#update_preferences', as: 'update_preferences', via: [:get, :post]
  match 'fines', to: 'user#fines', as: 'fines', via: [:get, :post]
  match 'lists', to: 'list#lists', as: 'lists', via: [:get, :post]
  match 'create_list', to: 'list#create_list', as: 'create_list', via: [:get, :post]
  match 'view_list', to: 'list#view_list', as: 'view_list', via: [:get, :post]
  match 'edit_list', to: 'list#edit_list', as: 'edit_list', via: [:get, :post]
  match 'share_list', to: 'list#share_list', as: 'share_list', via: [:get, :post]
  match 'destroy_list', to: 'list#destroy_list', as: 'destroy_list', via: [:get, :post]
  match 'make_default_list', to: 'list#make_default_list', as: 'make_default_list', via: [:get, :post]
  match 'add_item_to_list', to: 'list#add_item', as: 'add_item_to_list', via: [:get, :post]
  match 'remove_item_from_list', to: 'list#remove_item', as: 'remove_item_from_list', via: [:get, :post]
  match 'add_note_to_list', to: 'list#add_note_to_list', as: 'add_note_to_list', via: [:get, :post]
  match 'edit_note', to: 'list#edit_note', as: 'edit_note', via: [:get, :post]
  match 'payments', to: 'user#payments', as: 'payments', via: [:get, :post] 
  match 'missing_token', to: 'user#missing_token', as: 'missing_token', via: [:get, :post]
  match 'register', to: 'registration#register', as: 'register', via: [:get, :post]
  match 'submit_registration', to: 'registration#submit_registration', as: 'submit_registration', via: [:get, :post]
  match 'request_password_reset', to: 'user#request_password_reset', as: 'request_password_reset', via: [:get, :post] 
  match 'submit_password_reset', to: 'user#submit_password_reset', as: 'submit_password_reset', via: [:get, :post]
  match 'change_temp_password', to: 'user#change_temp_password', as: 'change_temp_password', via: [:get, :post]
  match 'save_account_preferences', to: 'user#save_account_preferences', as: 'save_account_preferences', via: [:get, :post]
  # For details on the DSL available within this file, see http://guides.ruby

  # Legacy routes begin here
  # First match to new controller if the params do not need to be manipulated
  match '/main/view_list', to: redirect(path: '/view_list', status: 302), via: [:get, :post]
  # Now any request that do need params manipulated are handled here 
  match '/main/:action', controller: 'legacy', via: [:get, :post]

end