ActionController::Routing::Routes.draw do |map|
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.register '/register', :controller => 'users', :action => 'create'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.moderate '/moderate', :controller => 'admin/moderate', :action => 'index'
  map.ban '/moderate/ban', :controller => 'admin/moderate', :action => 'ban'

  map.settings '/settings', :controller => 'users', :action => 'edit'

  map.resources :users
  map.resource :session
  map.resources :questions, :collection => {:tags => :get,
                                            :unanswered => :get},
                            :member => {:solve => :get,
                                        :unsolve => :get,
                                        :flag => :get} do |questions|
    questions.resources :answers, :member => {:flag => :get}
  end
  map.resources :votes
  map.resources :flags

  map.search '/search', :controller => "welcome", :action => "search"
  map.root :controller => "welcome"

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
