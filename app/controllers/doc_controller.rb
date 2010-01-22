class DocController < ApplicationController
  def privacy
    set_page_title("Privacy")
  end
  def tos
    set_page_title("Terms of service")
  end
end
