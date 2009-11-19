module SearchesHelper
  def excerpt_with_regexp(text, regexp, *args)
    options = args.extract_options!
    unless args.empty?
      options[:radius] = args[0] || 100
      options[:omission] = args[1] || "..."
    end
    options.reverse_merge!(:radius => 100, :omission => "...")
    if text && regexp
      if found_pos = (text.mb_chars =~ regexp)
        start_pos = [ found_pos - options[:radius], 0 ].max
        end_pos   = [ [ found_pos + 30 + options[:radius] - 1, 0].max, text.mb_chars.length ].min
        prefix  = start_pos > 0 ? options[:omission] : ""
        postfix = end_pos < text.mb_chars.length - 1 ? options[:omission] : ""

        prefix + text.mb_chars[start_pos..end_pos].strip + postfix
      else
        nil
      end
    end
  end
end
