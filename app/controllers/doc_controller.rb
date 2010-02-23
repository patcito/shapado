class DocController < ApplicationController
  def privacy
    set_page_title("Privacy")
  end
  def tos
    set_page_title("Terms of service")
  end

  def plans
    set_page_title(t('doc.plans.title'))
  end

  def chat
    set_page_title(t('doc.chat.title'))
  end
end
