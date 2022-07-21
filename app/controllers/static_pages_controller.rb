class StaticPagesController < ApplicationController
  def home
    @micropost = current_user.microposts.build if logged_in?
    @feed_items = current_user.feed.paginate(page: params[:page], per_page: 5) if logged_in?
  end

  def help
  end

  def about
  end

  def contact
  end
end
