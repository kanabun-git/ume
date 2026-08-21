module Admin
  # Sales-lead tracker for shops listed on competing portal sites: not the
  # same thing as Shop (an actual tenant of this platform). Rows are added
  # by hand or via CSV import (#import) — never scraped automatically.
  class ShopProspectsController < BaseController
    before_action :set_prospect, only: [:edit, :update, :destroy]

    def index
      @prospects = policy_scope(::ShopProspect)
      @prospects = @prospects.where(status: params[:status]) if params[:status].present?
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

    def send_outreach_emails
      authorize ::ShopProspect.new, :send_outreach_emails?

      ids = Array(params[:shop_prospect_ids]).reject(&:blank?)
      if ids.empty?
        redirect_to admin_shop_prospects_path, alert: "送信先の営業先候補を選択してください。"
        return
      end

      sent_count = 0
      skipped_count = 0
      policy_scope(::ShopProspect).where(id: ids).find_each do |prospect|
        if prospect.email.blank?
          skipped_count += 1
          next
        end

        ShopProspectMailer.outreach_email(prospect).deliver_now
        prospect.update!(outreach_email_sent_at: Time.current)
        sent_count += 1
      end

      notice = "#{sent_count}件に営業メールを送信しました。"
      notice += "(#{skipped_count}件はメールアドレス未登録のためスキップしました)" if skipped_count > 0
      redirect_to admin_shop_prospects_path, notice: notice
    end

    private

    def set_prospect
      @prospect = ::ShopProspect.find(params[:id])
      authorize @prospect
    end

    def prospect_params
      params.require(:shop_prospect).permit(:name, :phone, :email, :listing_site_name, :listing_url, :status, :memo)
    end
  end
end
