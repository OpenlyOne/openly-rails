# frozen_string_literal: true

Enumerable.module_eval do
  def split_with_delimiter
    slice_when do |element1, element2|
      yield(element1) || yield(element2)
    end
  end
end
