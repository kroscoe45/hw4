Rails.application.routes.draw do
  namespace :api do
    get "playlists/index"
    get "playlists/show"
    get "playlists/tracks"
    get "playlists/create"
    get "playlists/update"
    get "playlists/destroy"
    get "playlists/add_track"
    get "playlists/remove_track"
    get "playlists/update_tracks"
    get "playlists/add_tag"
    get "playlists/remove_tag"
    get "tags/index"
    get "tags/show"
    get "tags/create"
    get "tags/vote"
    get "tracks/index"
    get "tracks/show"
    get "tracks/create"
    get "users/show"
    get "users/create"
    get "users/update"
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
