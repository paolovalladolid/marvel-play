Rails.application.routes.draw do
  get 'welcome/index'
  
  resources :characters
  
  root 'welcome#index'
end
