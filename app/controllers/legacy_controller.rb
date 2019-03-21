class LegacyController < ApplicationController

  def search
    request_params = params.to_enum.to_h
    request_params[:type] = request_params['qtype']
    if request_params[:type] == 'shelf'
      request_params['query'] = ''
      request_params['shelving_location'].each do |s|
        request_params['query'] += s+','
      end
    end
    request_params[:location] = request_params['loc']
    request_params[:view] = request_params['layout']
    if request_params['physical'] == 'on'
      request_params[:limit_physical] = 'true'
    else
      request_params[:limit_physical] = 'false'
    end
    if request_params['availability'] == 'on'
      request_params[:limit_available] = 'true'
    else
      request_params[:limit_available] = 'false'
    end
    request_params.except!( 'shelving_location',
                            'qtype','search_title',
                            'loc',
                            'physical',
                            'in_progress',
                            'action',
                            'controller',
                            'layout',
                            'availability',
                          ) 
    redirect_to :controller => 'search', :action => 'search', :params => request_params
  end

  private

  # Need way to map legacy format codes to new format codes
  # Very doable but lacking the mental horsepower to tackle right now
  def legacy_format_mapper(legacy_format)

  end

end