Hist::Engine.routes.draw do

  resources :versions, path: :version, except: :index do
    collection do
      get 'diff'
    end
  end
end
