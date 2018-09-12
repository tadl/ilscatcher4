module ApplicationHelper
  def check_selected(current, option)
    if current == option
      return 'selected'
    end
  end
end
