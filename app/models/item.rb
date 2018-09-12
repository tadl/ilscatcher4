class Item
  include ActiveModel::Model
  attr_accessor :isbn, :links, :series, :abstract, :publisher_location, :attrs, :create_date,
                :corpauthor, :electronic, :id, :abstract_array, :genres, :physical_description,
                :title, :holdings, :title_alt, :fiction, :source, :subjects, :title_display,
                :contents, :holdable, :title_nonfiling, :contents_array, :edit_date, 
                :type_of_resource, :sort_year, :publisher, :title_short, :author, :hold_count,
                :author_other, :record_year
end