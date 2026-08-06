module Admin
  class MemberRanksController < BaseController
    before_action :set_member_rank, only: [:edit, :update, :destroy]

    def index
      @member_ranks = policy_scope(::MemberRank)
    end

    def new
      @member_rank = ::MemberRank.new
      authorize @member_rank
    end

    def create
      @member_rank = ::MemberRank.new(member_rank_params)
      authorize @member_rank

      if @member_rank.save
        redirect_to admin_member_ranks_path, notice: "会員ランクを登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @member_rank.update(member_rank_params)
        redirect_to admin_member_ranks_path, notice: "会員ランクを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @member_rank.destroy
      redirect_to admin_member_ranks_path, notice: "会員ランクを削除しました。"
    end

    def import
      authorize ::MemberRank.new, :import?

      if params[:file].blank?
        redirect_to admin_member_ranks_path, alert: "CSVファイルを選択してください。"
        return
      end

      result = ::MemberRankImport.call(params[:file])
      redirect_to admin_member_ranks_path, notice: import_notice(result)
    end

    def template
      authorize ::MemberRank.new, :import?
      send_data ::MemberRankImport::TEMPLATE_CSV, filename: "member_ranks_template.csv", type: "text/csv"
    end

    private

    def set_member_rank
      @member_rank = ::MemberRank.find(params[:id])
      authorize @member_rank
    end

    def member_rank_params
      params.require(:member_rank).permit(:name, :min_approved_count)
    end
  end
end
