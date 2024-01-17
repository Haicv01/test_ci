module ApplicationHelper
  def free_paging(base_url, per_page, count_all, args = {})
    return nil if base_url.blank? || count_all.to_i.zero?

    options = {
      query: '',
      anchor: '',
      size: 3,
      sep: '&nbsp;',
      page_key: :page,
      page_text: '/',
      link_show: { edge: true, side: true, number: true },
      link_text: { first: '&lt;&lt;先頭', prev: '&lt;前へ', next: '次へ&gt;', last: '最後&gt;&gt;' },
      link_class: { first: 'first', prev: 'prev', current: 'current', page: 'page', next: 'next', last: 'last' },
      remote: {}
    }.update(args.slice(:query, :anchor, :size, :sep, :page_key, :page_text, :remote))

    options[:link_show].update(args[:link_show]) unless args[:link_show].blank?
    options[:link_text].update(args[:link_text]) unless args[:link_text].blank?
    options[:link_class].update(args[:link_class]) unless args[:link_class].blank?

    current_page = params[options[:page_key].to_sym].blank? ? 1 : params[options[:page_key].to_sym].to_i

    per_page = 10 if per_page.to_i.zero?
    last_page, r = count_all.to_i.divmod(per_page.to_i)
    last_page += 1 if r > 0

    paging_window_size = options[:size].to_i

    # pages
    start_page = if current_page < paging_window_size
                   1
                 elsif current_page > last_page - paging_window_size
                   last_page - (paging_window_size * 2)
                 else
                   current_page - paging_window_size
                 end
    start_page = 1 if start_page < 1
    end_page = start_page + (paging_window_size * 2)
    end_page = last_page if end_page > last_page

    html = ''

    if (last_page > (paging_window_size * 2) + 1 && current_page > paging_window_size + 1) && options[:link_show][:edge]
      html << free_paging_link(base_url, 1, options[:link_class][:first], options[:link_text][:first],
                               options)
    end
    if (last_page > 1 && current_page != 1) && options[:link_show][:side]
      html << free_paging_link(base_url, current_page - 1, options[:link_class][:prev], options[:link_text][:prev],
                               options.merge(type: :prev))
    end

    if options[:link_show][:number]
      for pagenum in start_page..end_page
        link_klass = case pagenum
                     when current_page
                       options[:link_class][:current]
                     else
                       options[:link_class][:page]
                     end
        link_text = pagenum
        html << free_paging_link(base_url, pagenum, link_klass, link_text, options)
      end
    end

    if (last_page > 1 && current_page != last_page) && options[:link_show][:side]
      html << free_paging_link(base_url, current_page + 1, options[:link_class][:next], options[:link_text][:next],
                               options.merge(type: :next))
    end
    if (last_page > paging_window_size * 2 && current_page < last_page - paging_window_size) && options[:link_show][:edge]
      html << free_paging_link(base_url, last_page, options[:link_class][:last], options[:link_text][:last],
                               options)
    end

    html.html_safe
  end

  # ページングリンク生成
  def free_paging_link(url, page, klass, text = nil, custom_args = {})
    args = custom_args.clone

    text ||= page
    if klass == args[:link_class][:current]
      klass == 'current' ? %(#{text}#{args[:sep]}) : %(#{content_tag(klass, text)}#{args[:sep]})
    else
      uri = URI.parse(url)
      if args[:page_text][0, 1] == '/'
        uri.path = if page == 1
                     uri.path.to_s
                   else
                     uri.path.to_s + "#{args[:page_text].chomp('/')}/#{page}"
                   end
      elsif args[:query].blank?
        args[:query] =
          "#{args[:page_text]}=#{page}"
      else
        args[:query] << "&#{args[:page_text]}=#{page}"
      end
      unless args[:query].blank?
        uri.query = uri.query.blank? ? args[:query] : uri.query + '&' + args[:query]
      end
      uri.fragment = args[:anchor] unless args[:anchor].blank?
      url = uri.to_s

      case args[:type]
      when :prev
        @prev_link = url
      when :next
        @next_link = url
      end

      if args[:remote].blank?
        %(<a href="#{url}" class="#{klass}">#{text}</a>#{args[:sep]})
      else
        args[:remote].update({ url: })
        args[:remote][:html] = {} if args[:remote][:html].blank?
        args[:remote][:html].update(class: klass)
        link_to_remote(text, args[:remote]) + args[:sep]
      end
    end
  end

  def render_count_digits(str)
    return '' if str.blank?

    chars = str.split('')

    chars.map! do |c|
      if c == ','
        %(<span class="count_num_kanma">#{c}</span>)
      else
        %(<span class="count_num_#{c}">#{c}</span>)
      end
    end

    chars.join
  end

  def event_tracker(category, action, label = nil, opts = {})
    return unless Rails.env.production?

    p_str = "'#{category}'"
    p_str << (opts[:raw_action].present? ? ", #{action}" : ", '#{action}'")
    p_str << (opts[:raw_label].present? ? ", #{label}" : ", '#{label}'") if label
    p_str << ", '#{opts[:optional_value]}'" if opts[:optional_value]
    %(_gaq.push(['_trackEvent', #{p_str}]);).html_safe
  end

  # returns a string with a leading zero number
  def format_with_leading_zero(number)
    format('%02d', number)
  end

  # In serveral cases, field value can is string or integer, so we can't compare them. => Convert to string before comparision
  def sort_by(data, field)
    data.sort { |model1, model2| model1.send(field).to_s <=> model2.send(field).to_s }
  end

  # returns an image tag of car model
  def carsensor_image_tag(src, options = {})
    return no_car_model_image unless src

    image_tag_options = options.fetch(:image_tag_options, {})
    lazyload = options.fetch(:lazyload, true)
    if lazyload
      src_key = 'data-src'
      image_tag_options[:class] = [image_tag_options[:class], 'lazyload'].compact.join(' ')
    else
      src_key = 'src'
    end
    image_tag_options[src_key] = image_path(src)

    tag(:img, image_tag_options)
  end

  # returns a image of blank car model
  def no_car_model_image
    if request.smart_phone?
      image_tag 'common/noimage_maker.jpg', alt: ''
    else
      image_tag 'common/noimage_maker_top.jpg', alt: ''
    end
  end

  # returns true if an image exists
  def image_exists?(img_path)
    File.file? img_path
  end

  def link_to_image_tag(image, url, image_option = {}, link_option = {})
    image_option[:border] = 0 if image_option.exclude?(:border)
    image_option[:alt] = '' if image_option.exclude?(:alt)
    link_to car_image_tag(image, image_option), url, link_option
  end

  def model_year(year, new_flag)
    if new_flag
      '新車'
    elsif year.blank? || Date.today.year < year.to_s.to_i
      '-'
    else
      "#{year.to_i}年"
    end
  end

  def model_year_with_jp(year, new_flag, newline: false)
    if new_flag
      '新車'
    elsif year.blank? || Date.today.year < year.to_s.to_i
      '-'
    else
      "#{year}年"
    end
  end

  def disp_jp_year(year, short: false)
    return '' if year.blank?

    year = year.to_i
    return '(平成元年)' if year == 1989
    return '(令和元年)' if year == 2019

    if year > 2019
      return "(R#{year - 2018})" if short

      "(令和#{year - 2018}年)"
    elsif year < 1989
      "(昭和#{year - 1925}年)"
    else
      return "H#{year - 1988}" if short

      "(平成#{year - 1988}年)"
    end
  end

  def link_to_unless_with_block(condition, options = nil, html_options = nil, &)
    if condition
      capture(&)
    else
      link_to(options, html_options, &)
    end
  end

  def wrap(string, width)
    return '' if string.blank?

    string.gsub(%r{[[:alnum:]\'"/\.\(\)\[\]\$\?\*\-%&=,#!:\+;\~_]{#{width}}[^/]}, '\0 ')
  end

  def current_class(path)
    request.fullpath == path ? 'current' : ''
  end

  def btn_present_text
    return '購入お祝い金' if flashcampaign_info.closed?

    'Wキャンペーン'
  end

  def add_class(condition, cls_name)
    condition ? cls_name : ''
  end

  # Escape HTML string and replace newline character with br tag
  def h_nl2br(string)
    return unless string

    h(string.strip).gsub(/(\r)?\n/, '<br />')
  end

  def build_value_param(value)
    Array.wrap(value).join(',')
  end

  def google_tag_manager
    @data_layers ||= []
    @data_layers << GTM::DataLayer.new({ rails_controller: controller_name, rails_action: action_name })

    # CRITEO用のサイトタイプをセット
    criteo_site_type = request.smart_phone? ? 'm' : 'd'

    @data_layers << GTM::DataLayer.new({ criteo_site_type: })

    # 一覧ページ
    if current_route?(controller: 'search', action: 'index') && @results.cars.present?
      # CRITEOリターゲティング
      @data_layers << GTM::DataLayer.new({ event: 'criteo_list_access',
                                           criteo_list_global_keys: @results.cars.first(3).map(&:global_key) })
    end

    # 詳細ページ
    if current_route?(controller: 'cars', action: 'show') && @car.present?
      # CRITEOリターゲティング
      @data_layers << GTM::DataLayer.new({ event: 'criteo_detail_access',
                                           criteo_detail_global_key: @car[:global_key] })
    end

    if @car_data.present?
      # 入力フォームページ
      if current_route?(controller: 'inquiries', action: 'cs_inquiry')
        # CRITEOリターゲティング
        items = @car_data.map { |car| { id: car.global_key, price: 1, quantity: 1 } }
        @data_layers << GTM::DataLayer.new({ event: 'criteo_form_access', criteo_items: items })
      end

      # フォーム確認ページ
      if current_route?(controller: 'inquiries', action: 'cs_inquiry_confirm')
        # CRITEOリターゲティング
        items = @car_data.map { |car| { id: car.global_key, price: 1, quantity: 1 } }
        @data_layers << GTM::DataLayer.new({ event: 'criteo_confirm_access', criteo_items: items })
      end

      if current_route?(controller: 'inquiries', action: 'cs_inquiry_done')
        @data_layers << GTM::DataLayer.new({ user_type: @cs_unique_mail_in_month })
      end
    end

    GTM::DataLayer.collect_push(@data_layers)
  rescue StandardError => e
    Rails.logger.warn('[*** GOOGLE TAG MANAGER] gtm_tag_error')
    nil
  end

  def vertex_prediction_gtm
    @vertex_gtm_layers ||= []

    if @inquiry_prediction.present?
      @vertex_gtm_layers << GTM::DataLayer.new({ form_value: @inquiry_prediction, currency: 'JPY' })
    end

    GTM::DataLayer.collect_push(@vertex_gtm_layers)
  rescue StandardError => e
    Rails.logger.warn('[*** GOOGLE TAG MANAGER] gtm_tag_error')
    nil
  end

  def current_route?(rounting)
    controller_name == rounting[:controller] && action_name == rounting[:action]
  end

  def needs_leave_popup?
    return false unless @landing_flg

    Settings.needs_leave_popup.any? { |cond| current_route?(cond) }
  end

  def should_display_maker_sidebar?
    (params[:controller] == 'topics' && params[:action] == 'index') ||
      (params[:controller] == 'shop_search' && params[:action] == 'index')
  end

  def check_if_pref_show?
    params[:controller] == 'prefectures' && params[:pref].present? && params[:city].blank?
  end

  def check_if_city_show?
    params[:controller] == 'cities' && params[:pref].present? && params[:city].present?
  end

  def zinfo_display?
    Time.zone.parse(Settings.z_info.start_time) <= Time.zone.now && Time.zone.now <= Time.zone.parse(Settings.z_info.end_time)
  end

  def remove_amp_restricted_attributes(text)
    text.gsub(%r{!important|@charset "UTF-8";|/\*.+\*/}, '')
  end

  def format_query_params(params_hash)
    params_hash.each_with_object({}) do |(name, value), hsh|
      values = Array(value)
      hsh[name] = values.size > 1 ? values.join(',') : values.first
    end
  end

  def top_page?
    controller_name == 'home' && action_name == 'index'
  end

  def kcar_detail_page?
    kcar? && controller_name == 'cars' && action_name == 'show'
  end

  def display_information_boards?
    board_params = %w[maker shashu pref body]
    params.keys.any? { |param| board_params.include?(param) }
  end

  def show_link_company_native_app(url, new_app_version)
    return url unless url == '/sp/corporate'

    return Settings.zigexn_about_company if new_app_version

    url
  end

  def installed_by_store?
    session[:pwa_device] == 'app'
  end

  def installed_by_browser?
    session[:pwa_device] == 'web'
  end

  def is_tablet_device?
    device_detector.device_type == 'tablet'
  end

  def log_hashed_email_script
    return unless @hashed_email

    begin
      data_email_hashed = []
      data_email_hashed << GTM::DataLayer.new({ sha256_email_address: @hashed_email })
      GTM::DataLayer.collect_push(data_email_hashed)
    rescue StandardError => e
      Rails.logger.warn('[*** GOOGLE TAG MANAGER] gtm_tag_error')
      nil
    end
  end

  def include_google_analytics_tag?
    return true unless request.user_agent

    request.user_agent.exclude?('Chrome-Lighthouse')
  end
end
