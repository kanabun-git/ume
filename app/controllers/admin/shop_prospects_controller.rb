module Admin
  # Sales-lead tracker for shops listed on competing portal sites: not the
  # same thing as Shop (an actual tenant of this platform). Rows are added
  # by hand or via CSV import (#import) — never scraped automatically.
  class ShopProspectsController < BaseController
    before_action :set_prospect, only: [:edit, :update, :destroy]

    OUTREACH_STATS_RANGE_DAYS = 30

    def index
      @prospects = filtered_prospects.includes(:shop_prospect_district, :shop_inquiries)
      # Grouped by district and rendered as collapsible <details> sections
      # (see the view) instead of paginated -- with a couple hundred
      # prospects across ~50 districts, a flat 50-per-page list made it easy
      # to miss rows sitting on a different page (see 営業メール一斉送信 fix).
      # Folding keeps every row in the page/DOM (so "select all" and bulk
      # actions always see the complete filtered set) while only showing
      # a handful of district sections at a time.
      @grouped_prospects = @prospects.group_by(&:shop_prospect_district).sort_by do |district, _|
        district ? [0, district.prefecture, district.name] : [1, "", ""]
      end
      @districts = ::ShopProspectDistrict.all
      @prefectures = ::ShopProspectDistrict.distinct.reorder(:prefecture).pluck(:prefecture)

      load_outreach_click_stats
    end

    def new
      @prospect = ::ShopProspect.new
      authorize @prospect
    end

    def create
      @prospect = ::ShopProspect.new(prospect_params)
      authorize @prospect

      if @prospect.save
        redirect_to admin_shop_prospects_path, notice: "営業先候補を登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @prospect.update(prospect_params)
        redirect_to admin_shop_prospects_path, notice: "営業先候補を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @prospect.destroy
      redirect_to admin_shop_prospects_path, notice: "営業先候補を削除しました。"
    end

    def import
      authorize ::ShopProspect.new, :import?

      if params[:file].blank?
        redirect_to admin_shop_prospects_path, alert: "CSVファイルを選択してください。"
        return
      end

      result = ::ShopProspectImport.call(params[:file])
      notice = "#{result.created_count}件登録しました。"
      notice += "(#{result.error_rows.size}件はエラーのためスキップしました。1行目はヘッダー行です: #{result.error_rows.map { |r| "#{r[:line]}行目(#{r[:errors]})" }.join("、")})" if result.error_rows.any?
      redirect_to admin_shop_prospects_path, notice: notice
    end

    def template
      authorize ::ShopProspect.new, :import?
      send_data ::ShopProspectImport::TEMPLATE_CSV, filename: "shop_prospects_template.csv", type: "text/csv"
    end

    # Respects the same ?status=/?district_id= filters as #index, so an
    # admin can export just what they're currently looking at.
    def export
      authorize ::ShopProspect.new, :export?
      send_data ::ShopProspectImport.export(filtered_prospects), filename: "shop_prospects_#{Date.current}.csv", type: "text/csv"
    end

    # Bulk-clears bad CSV imports without deleting one row at a time.
    # Respects the same ?status=/?district_id= filters as #index so an admin
    # can wipe just one bucket (e.g. a single district re-imported by
    # mistake) instead of every prospect.
    def destroy_all
      authorize ::ShopProspect.new, :destroy?

      count = filtered_prospects.count
      filtered_prospects.destroy_all

      redirect_to admin_shop_prospects_path(status: params[:status], district_id: params[:district_id], prefecture: params[:prefecture], sent: params[:sent]),
        notice: "#{count}件の営業先候補を削除しました。"
    end

    def send_outreach_emails
      authorize ::ShopProspect.new, :send_outreach_emails?

      ids = Array(params[:shop_prospect_ids]).reject(&:blank?)
      if ids.empty?
        redirect_to admin_shop_prospects_path, alert: "送信先の営業先候補を選択してください。"
        return
      end

      sent_count = 0
      skipped_count = 0
      failed_count = 0
      policy_scope(::ShopProspect).where(id: ids).find_each do |prospect|
        if prospect.email.blank?
          skipped_count += 1
          next
        end

        begin
          ShopProspectMailer.outreach_email(prospect).deliver_now

          attrs = { outreach_email_sent_at: Time.current }
          # Only advance a still-untouched lead -- don't knock a prospect
          # already further along (negotiating/won/lost) back down to
          # merely "contacted" just because they got a re-send.
          attrs[:status] = :contacted if prospect.not_contacted?
          prospect.update!(attrs)

          sent_count += 1
        rescue StandardError => e
          # One bad recipient (malformed address, delivery rejection, etc.)
          # used to raise and abort the whole batch, silently leaving every
          # prospect after it in the selection unsent. Log and keep going
          # instead, so a large "select all" batch always finishes.
          failed_count += 1
          Rails.logger.error("営業メール送信に失敗しました prospect_id=#{prospect.id}: #{e.class}: #{e.message}")
        end
      end

      notice = "#{sent_count}件に営業メールを送信しました。"
      notice += "(#{skipped_count}件はメールアドレス未登録のためスキップしました)" if skipped_count > 0
      notice += "(#{failed_count}件は送信に失敗しました。メールアドレスをご確認のうえ再度お試しください)" if failed_count > 0
      redirect_to admin_shop_prospects_path, notice: notice
    end

    private

    # Click-through performance for the outreach emails matched by the
    # current filter (status/prefecture/district_id -- deliberately ignores
    # the sent/not_sent filter itself, since these stats are only about
    # emails that were actually sent). "件別のクリック率" buckets by the day
    # the email was *sent*, not the day it was clicked, so each day's rate
    # is a running conversion figure for that day's batch (it can keep
    # climbing after the fact as more recipients click later).
    def load_outreach_click_stats
      sent_scope = base_prospects_scope.where.not(outreach_email_sent_at: nil)

      @outreach_sent_count = sent_scope.count
      @outreach_clicked_count = sent_scope.where.not(outreach_link_clicked_at: nil).count
      @outreach_click_rate = rate_percent(@outreach_clicked_count, @outreach_sent_count)
      @outreach_converted_count = sent_scope.where.not(outreach_link_clicked_at: nil).joins(:shop_inquiries).distinct.count

      sent_by_day = Hash.new(0)
      clicked_by_day = Hash.new(0)
      sent_scope.pluck(:outreach_email_sent_at, :outreach_link_clicked_at).each do |sent_at, clicked_at|
        day = sent_at.to_date
        sent_by_day[day] += 1
        clicked_by_day[day] += 1 if clicked_at
      end

      @outreach_stats_range_days = OUTREACH_STATS_RANGE_DAYS
      range_start = Date.current - (@outreach_stats_range_days - 1)
      @outreach_daily_stats = (range_start..Date.current).map do |date|
        { date: date, sent: sent_by_day[date], clicked: clicked_by_day[date], rate: rate_percent(clicked_by_day[date], sent_by_day[date]) }
      end
    end

    def rate_percent(numerator, denominator)
      return 0.0 if denominator.zero?

      (numerator.to_f / denominator * 100).round(1)
    end

    # Status/prefecture/district filters shared by the main list and the
    # outreach click stats -- the sent/not_sent filter is applied on top of
    # this only for the main list (see filtered_prospects), since the click
    # stats are about sent emails specifically regardless of that filter.
    def base_prospects_scope
      prospects = policy_scope(::ShopProspect)
      prospects = prospects.where(status: params[:status]) if params[:status].present?
      prospects = prospects.where(shop_prospect_district_id: params[:district_id]) if params[:district_id].present?
      if params[:prefecture].present?
        prospects = prospects.joins(:shop_prospect_district).where(shop_prospect_districts: { prefecture: params[:prefecture] })
      end
      prospects
    end

    def filtered_prospects
      case params[:sent]
      when "sent" then base_prospects_scope.where.not(outreach_email_sent_at: nil)
      when "not_sent" then base_prospects_scope.where(outreach_email_sent_at: nil)
      else base_prospects_scope
      end
    end

    def set_prospect
      @prospect = ::ShopProspect.find(params[:id])
      authorize @prospect
    end

    def prospect_params
      params.require(:shop_prospect).permit(:name, :genre, :phone, :email, :listing_site_name, :listing_url, :status, :memo)
    end
  end
end
