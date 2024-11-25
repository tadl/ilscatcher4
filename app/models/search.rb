class Search
  require 'elasticsearch'
  include ActiveModel::Model
  attr_accessor :query, :type, :sort, :fmt, :location, :min_score, :page, :subjects, :view,
                :authors, :genres, :series, :limit_available, :limit_physical, :more_results,
                :facets, :results, :view, :size, :ids, :audiences
  
  def client
    client = Elasticsearch::Client.new host: ENV['ES_URL']
  end

  def get_by_ids
    if self.size.nil?
      self.size = 24
    else
      self.size = self.size.to_i
    end
    if self.page
      item_number = (self.page.to_i * self.size)
    else
      item_number = 0
    end
    ids = self.ids.split(',')
    search = self.client.mget index: ENV['ES_INDEX'], body: { 
      ids: ids 
    }
    process_results(search['docs'], item_number)
  end 

  def get_results
    if self.size.nil?
      self.size = 24
    else
      self.size = self.size.to_i
    end
    if self.page
      item_number = (self.page.to_i * self.size)
    else
      item_number = 0
    end
    search = elastic_search()
    puts search['hits'].except('hits').to_s
    process_results(search['hits']['hits'], item_number)
  end

  def search_type_options
    return [['Keyword', 'keyword'], ['Author / Group / Actor', 'author'],['Title', 'title'],['Subject', 'subject'], ['Series', 'series'], ['Genre', 'single_genre'], ['Call Number', 'call_number']]
  end

  def sort_options
    return [['Relevance', 'relevance'], ['Newest to Oldest', 'pubdateDESC'],['Oldest to Newest', 'pubdateASC'],['Title A to Z', 'titleAZ'], ['Title Z to A', 'titleZA']]
  end

  def audience_options 
    return ['All','Adult','Young Adult','Juvenile']
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

  def process_results(raw_results, item_number)
    results = Array.new
    raw_results.each do |h|
      if h['_source']
        item = Item.new(h['_source'])
        #this line adds availability to items which is a method as if it was an attribute
        item.instance_variable_set(:@score, h['_score'])
        item.instance_variable_set(:@availability, item.check_availability)
        item.instance_variable_set(:@eresource_link, item.check_eresource_link)
        item.instance_variable_set(:@result_order, item_number)
        if item.type_of_resource == 'sound recording-nonmusical' && !item.title_display.nil?
          item.title_display += ' (AUDIOBOOK)'
        end
        if item.type_of_resource == 'sound recording-musical' && item.holdings[0] && item.holdings[0]['location_id'] == 533
          item.title_display += ' (VINYL)'
        end 
        if self.location
          item.instance_variable_set(:@search_location, self.location)
          item.instance_variable_set(:@search_code, self.location_code)
        else
          item.instance_variable_set(:@search_location, Settings.location_default)
        end
        if self.view
          item.instance_variable_set(:@search_view, self.view)
        else
          item.instance_variable_set(:@search_view, Settings.view_default)
        end
        item_number += 1
        results.push(item)
      end
    end 
    if results.size > self.size
      more_results = true
    else
      more_results = false
    end
    #set more_results, facets, and the search results to be attributes of the search
    self.instance_variable_set(:@more_results, more_results)
    self.instance_variable_set(:@facets, process_facets(results))
    self.instance_variable_set(:@results, results.first(self.size))
  end

  def elastic_search()
    if self.page
      page = (self.page.to_i * self.size)
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
        min_score = 1
      end
    elsif self.type == 'author'
      search_scheme = author_search
      if self.min_score 
        min_score = self.min_score
      else
        min_score = 250
      end
    elsif self.type == 'title'
      search_scheme = title_search
      if self.min_score
        min_score = self.min_score
      else
        min_score = 300
      end
    elsif self.type == 'subject'
      search_scheme = subject_search
      if self.min_score
        min_score = self.min_score
      else
        min_score = 270
      end
    elsif self.type == 'series'
      search_scheme = series_search
      if self.min_score
        min_score = self.min_score
      else
        min_score = 9.2
      end
    elsif self.type == 'single_genre'
      search_scheme = single_genre_search
      if self.min_score
        min_score = self.min_score
      else
        min_score = 5
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
    elsif self.type == 'shelving_location' || 'shelf'
      search_scheme = shelving_location_search
      min_score = 1
    end
    self.client.search index: ENV['ES_INDEX'], preference: Digest::MD5.hexdigest(self.query), body: { 
      query: {
        bool: search_scheme,
      },
      sort: sort_strategy,
      size: (self.size + 1),
      from: page,
      min_score: min_score,
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
      ],
      filter: process_filters,
    }
    return query
  end

  def keyword_search
    { 
      must:[
        {
          multi_match: {
            type: "best_fields",
            query: self.query,
            fields: [ 'title.folded', 
                      'title_display', 
                      'title_short.docs', 
                      'title_alt',
                      'title.docs', 
                      'author.folded', 
                      'author_brief',  
                      'author_other',
                      'author_other_brief',
                      'contents',
                      'contents.english',
                      'contents_array',
                      'abstract',
                      'abstract_array',
                      'subjects',
                      'subjects.english',
                      'series',
                      'genres'],
            slop:  100,
            boost: 3,
            fuzziness: 1
          }
        }, 
      ],
      should:[
        {
          multi_match: {
            type: "cross_fields",
            query: self.query,
            fields: [ 'title.folded', 
                      'title_display^4', 
                      'title_short.docs^6',
                      'title', 
                      'title_alt',
                      'title.docs^4', 
                      'author.folded', 
                      'author_brief^8',  
                      'author_other^6',
                      'author_other_brief^6',
                      'contents',
                      'contents.english^2',
                      'abstract',
                      'subjects^4',
                      'subjects.english^2',
                      'series',
                      'genres^3'],
            slop:  20,
            boost: 30,
          }
        },
                {
          multi_match: {
            type: "phrase",
            query: self.query,
            fields: [ 'title.folded', 
                      'title_display^3', 
                      'title_short^6', 
                      'title_alt',
                      'title^4', 
                      'author.folded', 
                      'author_brief',  
                      'author_other^3',
                      'author_other_brief^3',
                      'contents',
                      'contents.english^2',
                      'abstract',
                      'subjects^3',
                      'subjects.english^2',
                      'series',
                      'genres^3'],
            slop:  2,
            boost: 4,
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
      must:[
        {
          multi_match: {
            type: "best_fields",
            query: self.query,
            fields: [ 
                      'author.folded',
                      'author^2', 
                      'author_brief^5',  
                      'author_other^3',
                      'author_other_brief^3',
                    ],
            slop:  100,
            boost: 3,
            fuzziness: 1
          }
        }, 
      ],
      should:[
        {
          multi_match: {
            type: "phrase",
            query: self.query,
            fields: [ 
                      'author.folded', 
                      'author_brief^6',  
                      'author_other^4',
                      'author_other_brief^4',
                    ],
            slop:  20,
            boost: 10,
          }
        },
      ],
      filter: process_filters,
    }
  end

  def title_search
  { 
      must:[
        {
          multi_match: {
            type: "best_fields",
            query: self.query,
            fields: [ 'title.folded^5', 
                      'title_display^3', 
                      'title_short.docs^8', 
                      'title.docs^4', 
                    ],
            slop:  100,
            boost: 3,
            fuzziness: 1
          }
        }, 
      ],
      should:[
        {
          multi_match: {
            type: "phrase",
            query: self.query,
            fields: [ 'title.folded^5', 
                      'title_display^3', 
                      'title_short.folded^8', 
                      'title_alt.folded', 
                    ],
            slop:  20,
            boost: 10,
          }
        },
      ],
      filter: process_filters,
    }
  end

  def subject_search
    { 
      must:[
        {
          multi_match: {
            type: "best_fields",
            query: self.query,
            fields: [ 'contents',
                      'contents.english^2',
                      'contents_array',
                      'abstract',
                      'abstract_array',
                      'subjects^3',
                      'subjects.english^3',
                    ],
            slop:  100,
            boost: 3,
            fuzziness: 1
          }
        }, 
      ],
      should:[
        {
          multi_match: {
            type: "cross_fields",
            query: self.query,
            fields: [ 
                      'contents',
                      'contents.english^2',
                      'abstract',
                      'subjects^3',
                      'subjects.english^3',
                    ],
            slop:  20,
            boost: 10,
          }
        },
      ],
      filter: process_filters,
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
          fuzziness: 1,
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
      sort_type.push({"sort_year": "desc" })
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
    subjects['type_singular'] = 'Subject'
    subjects['subfacets'] = Array.new
    authors = Hash.new
    authors['type'] = 'Authors'
    authors['type_raw'] = 'authors'
    authors['type_singular'] = 'Author'
    authors['subfacets'] = Array.new
    series = Hash.new
    series['type'] = 'Series'
    series['type_raw'] = 'series'
    series['type_singular'] = 'Series'
    series['subfacets'] = Array.new
    genres = Hash.new
    genres['type'] = 'Genres'
    genres['type_raw'] = 'genres'
    genres['type_singular'] = 'Genre'
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
    if self.location && self.location != Settings.location_default || self.location && self.location == '43'
      filters.push(location_filter)
    end
    if self.limit_available == 'true'
      filters.push(available_filter)
    end
    if self.limit_physical == 'true'
      filters.push(term: {"electronic": false})
    end
    if self.audiences && self.audiences != 'All'
      filters.push(audience_filter)
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
          if f.size == 4
            filters.push(term: {"fiction": f[3]})
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
    # Special handling for KCL to not include records found only at schools
    if self.location == '43'
      return {
        bool: {
          should:[
            {
              nested:{
                path: "holdings",
                query:{
                  bool:{
                    should:[
                      {term: {"holdings.circ_lib": "KCL"}},
                      {term: {"holdings.circ_lib": "KCL-COLD"}},
                      {term: {"holdings.circ_lib": "KCL-GARF"}},
                    ]
                  }
                }
              }
            },
            {term: {"electronic": true}}
          ]
        }  
      }
    else
      return {
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
  end

  def audience_filter
    if self.audiences == 'Juvenile'
      { 
        bool:{
          should:[
            {term: {"audiences": "juvenile"}},
            {term: {"audiences": "marc_juvenile"}},
          ]
        }
      }
    elsif self.audiences == 'Adult'
      { 
        bool:{
          should:[
            {term: {"audiences": "adult"}},
            {term: {"audiences": "marc_adult"}},
            {term: {"audiences": "marc_general"}},
          ]
        }
      }
    elsif self.audiences == 'Young Adult'
      { 
        bool:{
          should:[
            {term: {"audiences": "ya"}},
            {term: {"audiences": "marc_adolescent"}},
          ]
        }
      }
    end
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