class UtilController < ApplicationController
    include ApplicationHelper
    layout "youtube"
    respond_to :html

    def youtube
        @id = params[:id]
        render :template => "util/youtube"
    end
end