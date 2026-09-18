module ApplicationHelper
  def page_classes
    [ controller_path.tr("/", "-"), action_name, content_for(:page_class) ].compact.join(" ")
  end

  def format_score(value)
    number_with_delimiter(value.to_i)
  end
end
