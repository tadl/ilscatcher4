class Search
  require 'elasticsearch'
  include ActiveModel::Model
  attr_accessor :query, :type, :sort, :fmt, :location, :min_score, :page, :subjects,
                :authors, :genres, :series, :limit_available, :limit_physical, :more_results,
                :facets, :results
  
  def client
    client = Elasticsearch::Client.new host: ENV['ES_URL']
  end

  def get_results
    search = elastic_search()
    results = Array.new
    search['hits']['hits'].each do |h|
      item = Item.new(h['_source'])
      #this line adds availability to items which is a method as if it was an attribute
      item.instance_variable_set(:@availability, item.check_availability)
      results.push(item)
    end 
    if results.size > 24
      more_results = true
    else
      more_results = false
    end
    #set more_results, facets, and the search results to be attributes of the search
    self.instance_variable_set(:@more_results, more_results)
    self.instance_variable_set(:@facets, process_facets(results))
    self.instance_variable_set(:@results, results.first(24))
  end

  def search_type_options
    return [['Keyword', 'keyword'], ['Author / Group / Actor', 'author'],['Title', 'title'],['Subject', 'subject'], ['Series', 'series'], ['Genre', 'single_genre'], ['Call Number', 'call_number']]
  end

  def sort_options
    return [['Relevance', 'relevance'], ['Newest to Oldest', 'pubdateDESC'],['Oldest to Newest', 'pubdateASC'],['Title A to Z', 'titleAZ'], ['Title Z to A', 'titleZA']]
  end

  def format_options
    return Settings.format_options
  end

  def location_options
    return Settings.location_options
  end

  def location_code
    self.location_options.each do |l|
      if l[1] == self.location
        return l[2]
      end
    end
  end

  private

  def elastic_search()
    if self.page
      page = (self.page.to_i * 24)
    else
      page = 0
    end
    if !self.query || self.query == '' 
      search_scheme = blank_search
      if self.min_score 
        min_score = self.min_score
      else
        min_score = 0.01
      end
    elsif !self.type || self.type == 'keyword'
      search_scheme = keyword_search
      if self.min_score 
        min_score = self.min_score
      else
        min_score = 10
      end
    elsif self.type == 'author'
      search_scheme = author_search
      if self.min_score 
        min_score = self.min_score
      else
        min_score = 1
      end
    elsif self.type == 'title'
      search_scheme = title_search
      if self.min_score
        min_score = self.min_score
      else
        min_score = 0.24
      end
    elsif self.type == 'subject'
      search_scheme = subject_search
      if self.min_score
        min_score = self.min_score
      else
        min_score = 0.6
      end
    elsif self.type == 'series'
      search_scheme = series_search
      if self.min_score
        min_score = self.min_score
      else
        min_score = 0.6
      end
    elsif self.type == 'single_genre'
      search_scheme = single_genre_search
      if self.min_score
        min_score = self.min_score
      else
        min_score = 0.24
      end
    elsif self.type == 'record_id'
      search_scheme = record_id_search
      min_score = 1
    elsif self.type == 'isbn'
      search_scheme = isbn_search
      min_score = 3
    elsif self.type == 'call_number'
      search_scheme = call_number_search
      min_score = 1
    elsif self.type == 'shelving_location'
      search_scheme = shelving_location_search
      min_score = 1
    end
      self.client.search index: ENV['ES_INDEX'], body: { 
        query: {
          bool: search_scheme,
        },
        sort: sort_strategy,
        size: 25,
        from: page,
        min_score: min_score
      }
  end

  def blank_search
    {
      must: {"match_all":{}},
      filter: process_filters
    }
  end

  def shelving_location_search
    shelving_locations = self.query.split(',')
    should_query = Array.new
    shelving_locations.each do |f|
      should_query.push(term: {"holdings.location_id": f})
    end
    query = {
      should:[
        {
          nested:{
            path: "holdings",
            query:{
              bool:{
                should: should_query
              }
            }
          }
        }
      ]
    }
    return query
  end

  def keyword_search
    { 
      should:[
        {
          multi_match: {
            type: "phrase",
            query: self.query,
            fields: ['title.folded^10', 'title.raw^10', 'title_short', 'author^7', 'title_alt', 'author_other^3','contents^5','abstract^5','subjects^3','series^6','genres'],
            slop:  100,
            boost: 14
          }
        },
        {
          multi_match: {
            type: 'cross_fields',
            query: self.query,
            fields: ['title.folded^10', 'title.raw^10','author^2','contents','series'],
            slop:  10,
            boost: 25
          }
        },
        {
          multi_match: {
            type: 'most_fields',
            query: self.query,
            fields: ['title.folded^10', 'title.raw','author', 'title_alt', 'author_other','contents','abstract','subjects','series','genres'],
            fuzziness: 2,
            slop:  100,
            boost: 1
          }
        },        
      ],
      filter: process_filters,
    }
  end

  def isbn_search
    {
      should: [
        {
          term:{
            "isbn": self.query
          }
        }
      ],
      filter: process_filters
    }
  end

  def call_number_search
    {
      :should =>[
        :nested => {
          path: 'holdings',
          query:{
            :match_phrase_prefix => {'holdings.call_number': self.query}
          }
        }
      ],
      filter: process_filters
    }
  end

  def author_search
    {
      should:[
        {
          multi_match: {
          type: 'phrase',
          query: self.query,
          fields: ['author^2', 'author_other'],
          slop:  3
          }
        },
        {
          multi_match: {
          type: 'best_fields',
          query: self.query,
          fields: ['author^2', 'author_other'],
          fuzziness: 2,
          }
        }
      ],
      filter: process_filters
    }
  end

  def title_search
    {
      should:[
        {
          multi_match: {
            type: 'phrase',
            query: self.query,
            fields: ['title_short', 'title_alt', 'title.raw^20'],
            slop:  3,
            boost: 10
          }
        },
        {
          multi_match: {
          type: 'most_fields',
          query: self.query,
          fields: ['title_short', 'title_alt', 'title.raw^20'],
          fuzziness: 1,
          boost: 1
          }
        }
      ],
      filter: process_filters
    }
  end

  def subject_search
    {
      should:[
        {
          multi_match: {
          type: 'phrase',
          query: self.query,
          fields: ['subjects^3', 'abstract', 'contents'],
          slop:  3,
          boost: 10
          }
        },
        {
          multi_match: {
          type: 'best_fields',
          query: self.query,
          fields: ['subjects^3', 'abstract', 'contents'],
          fuzziness: 2,
          boost: 1
          }
        }
      ],
      filter: process_filters
    }
  end

  def series_search
    {
      should:[
        {
          multi_match: {
          type: 'phrase',
          query: self.query,
          fields: ['series'],
          slop:  3,
          boost: 10
          }
        },
        {
          multi_match: {
          type: 'best_fields',
          query: self.query,
          fields: ['series'],
          fuzziness: 2,
          boost: 1
          }
        }
      ],
      filter: process_filters
    }
  end

  def single_genre_search
    {
      should:[
        {
          multi_match: {
          type: 'phrase',
          query: self.query,
          fields: ['genres'],
          slop:  3,
          boost: 10
          }
        },
        {
          multi_match: {
          type: 'best_fields',
          query: self.query,
          fields: ['genres'],
          fuzziness: 2,
          boost: 1
          }
        }
      ],
      filter: process_filters
    }
  end


  def record_id_search
    record_ids = self.query.split(',')
    record_id_array = Array.new
    record_ids.each do |r|
      record_id_array.push(:term => {"id" => r})
    end
    puts record_id_array.to_s
    {
      should:[
        record_id_array
      ],
      filter: process_filters
    }
  end

  def sort_strategy
    sort_type = Array.new
    if self.sort == nil || self.sort == '' || self.sort == 'relevance'
      sort_type.push("_score")
      sort_type.push({ "author.raw": "asc" })
      sort_type.push({ "title_nonfiling.sort": "asc" })
    else
      if sort == 'titleAZ'
        sort_type.push({ "title_nonfiling.sort": "asc" })
      elsif sort == 'titleZA'
        sort_type.push({ "title_nonfiling.sort": "desc" })
      elsif sort == 'AuthorAZ'
        sort_type.push({ "author.raw": "asc" })
      elsif sort == 'AuthorZA'
        sort_type.push({ "author.raw": "desc" })
      elsif sort == 'createDESC'
        sort_type.push({"create_date": "desc" })
        sort_type.push({"sort_year": "desc" })
      elsif sort == 'createASC'
        sort_type.push({"create_date": "asc" })
        sort_type.push({"sort_year": "asc" })
      elsif sort == 'pubdateDESC'
        sort_type.push({"sort_year": "desc" })
        sort_type.push({"create_date": "desc" }) 
      elsif sort == 'pubdateASC'
        sort_type.push({"sort_year": "asc" })
        sort_type.push({"create_date": "asc" })
      end
      sort_type.push("_score")
    end
    return sort_type
  end

  def process_facets(results = [])
    facets = Array.new
    subjects = Hash.new
    subjects['type'] = 'Subjects'
    subjects['type_raw'] = 'subjects'
    subjects['subfacets'] = Array.new
    authors = Hash.new
    authors['type'] = 'Authors'
    authors['type_raw'] = 'authors'
    authors['subfacets'] = Array.new
    series = Hash.new
    series['type'] = 'Series'
    series['type_raw'] = 'series'
    series['subfacets'] = Array.new
    genres = Hash.new
    genres['type'] = 'Genres'
    genres['type_raw'] = 'genres'
    genres['subfacets'] = Array.new
    results.each do |r|
      authors['subfacets'].push(r.author)
      if r.subjects.kind_of?(Array)
        r.subjects.each do |subject|
          subjects['subfacets'].push(subject)
        end
      end
      if r.genres.kind_of?(Array)
        r.genres.each do |genre|
          genres['subfacets'].push(genre)
        end
      end
      if r.series.kind_of?(Array)
        r.series.each do |serie|
          series['subfacets'].push(serie)
        end
      end
    end
    #remove empty values
    subjects['subfacets'].reject!(&:empty?)
    authors['subfacets'].reject!(&:empty?)
    series['subfacets'].reject!(&:empty?)
    genres['subfacets'].reject!(&:empty?)
    #sort by most commmon values and only indclude uniques
    subjects['subfacets'].sort_by! { |u| subjects['subfacets'].count(u) }.reverse!.uniq!
    authors['subfacets'].sort_by! { |u| authors['subfacets'].count(u) }.reverse!.uniq!
    series['subfacets'].sort_by! { |u| series['subfacets'].count(u) }.reverse!.uniq!
    genres['subfacets'].sort_by! { |u| genres['subfacets'].count(u) }.reverse!.uniq!
    #get the first ten values 
    subjects['subfacets'] = subjects['subfacets'].first(10).sort_by!{|u| u.downcase}
    authors['subfacets'] = authors['subfacets'].first(10).sort_by!{|u| u.downcase}
    series['subfacets'] = series['subfacets'].first(10).sort_by!{|u| u.downcase}
    genres['subfacets'] = genres['subfacets'].first(10).sort_by!{|u| u.downcase}
    facets += [subjects, authors, series, genres]
    return facets
  end

  def process_filters
    filters = Array.new
    self.subjects.each do |s|
      filters.push(term: {"subjects.raw": URI.unescape(s)})
    end unless self.subjects.nil?
    self.genres.each do |s|
      filters.push(term: {"genres.raw": URI.unescape(s)})
    end unless self.genres.nil?
    self.series.each do |s|
      filters.push(term: {"series.raw": URI.unescape(s)})
    end unless self.series.nil?
    self.authors.each do |s|
      filters.push(term: {"author.raw": URI.unescape(s)})
    end unless self.authors.nil?
    if self.location && self.location != Settings.location_default
      filters.push(location_filter)
    end
    if self.limit_available == 'true'
      filters.push(available_filter)
    end
    if self.limit_physical == 'true'
      filters.push(term: {"electronic": false})
    end
    if self.fmt != "All Formats"
      self.format_options.each do |f|
        if f[0] == self.fmt
          if f[1] == 'fmt'
            filters.push(format_filter(f[2]))
          elsif f[1] == 'shelving_location'
            filters.push(shelving_location_filter(f[2]))
          elsif f[1] == 'call_prefix'
            filters.push(call_prefix_filter(f[2]))
          elsif f[1] == 'electronic'
            filters.push(electronic_filter(f[2]))
          end
        end
      end
    end unless self.fmt.nil?
    return filters
  end

  def format_filter(format_code)
    format_array = code_to_format(format_code)
    should_query = Array.new
    format_array.each do |f|
      should_query.push(term: {"type_of_resource": f})
    end
    {
      bool:{
        should: should_query
      }
    }
  end

  def electronic_filter(format_code)
    should_query = Array.new
    Settings.format_electronic.each do |e|
      if e[0] == format_code
        e[1].each do |p|
          should_query.push(term: {"source": p})
        end
        e[2].each do |f|
          should_query.push(term: {"type_of_resource": f})
        end
      end
    end
    did_it = {
      bool:{
        should: should_query,
        minimum_should_match: 2
      }
    }
    puts did_it.to_s
    return did_it
  end

  def code_to_format(format_code)
    if format_code == 'a'
      return ['text', 'kit', 'cartographic']
    elsif format_code == 'g'
      return ['moving image']
    elsif format_code == 'j'
      return ['sound recording-musical']
    elsif format_code == 'ebooks'
      return [['Safari','OverDrive','Hoopla'],['text', 'kit', 'sound recording-nonmusical', 'cartographic', 'software, multimedia']]
    end
  end

  def call_prefix_filter(prefix)
    {
      bool:{
        should:[
          {
            nested:{
              path: "holdings",
              query:{
                prefix: {'holdings.call_number': prefix}
              }
            }
          },
        ]
      }
    }
  end

  def shelving_location_filter(locations)
    shelving_locations = locations.split(',')
    should_query = Array.new
    shelving_locations.each do |f|
      should_query.push(term: {"holdings.location_id": f})
    end
    {
      bool:{
        should:[
          {
            nested:{
              path: "holdings",
              query:{
                bool:{
                  should: should_query
                }
              }
            }
          },
        ]
      }
    }
  end

  def location_filter
   {
      bool: {
        should:[
          {
            nested:{
              path: "holdings",
              query:{
                bool:{
                  should:[
                    {term: {"holdings.circ_lib": self.location_code}},
                  ]
                }
              }
            }
          },
          {term:{"electronic": true}}
        ]
      }
    }
  end

  def available_filter
    if self.location && self.location != Settings.location_default
      {
        bool:{
          should:[
            {
              nested:{
                path: "holdings",
                query: {
                  bool:{
                    must:[
                      {term: {"holdings.circ_lib": self.location_code}}
                    ],
                    should:[
                      {term: {"holdings.status": "Available"}},
                      {term: {"holdings.status": "Reshelving"}},
                    ]
                  }
                }
              }
            },
            {
              term:{
                "electronic": true
              }
            }
          ]  
        }
      }
    else
      {
        bool:{
          should:[
            {
              nested: {
                path: "holdings",
                query:{
                  bool:{
                    should:[
                      {term: {"holdings.status": "Available"}},
                      {term: {"holdings.status": "Reshelving"}},
                    ]
                  }
                }
              }
            },
            {term: {"electronic": true}}
          ]  
        }
      }
    end
  end
end
