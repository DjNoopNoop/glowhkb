module Admin
  class PublicationsController < Admin::ApplicationController
    def index
      @publications = Publication.order(year: :desc)
    end
  end
end
