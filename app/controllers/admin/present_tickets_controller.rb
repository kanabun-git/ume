module Admin
  class PresentTicketsController < BaseController
    before_action :set_shop
    before_action :set_present_ticket, only: [:show, :edit, :update, :destroy, :draw, :send_result_emails]

    def index
      @present_tickets = @shop.present_tickets
    end

    def show
      @entries = @present_ticket.present_ticket_entries.includes(:member).order(:created_at)
    end

    def new
      @present_ticket = @shop.present_tickets.build
      authorize @present_ticket
    end

    def create
      @present_ticket = @shop.present_tickets.build(present_ticket_params)
      authorize @present_ticket

      if @present_ticket.save
        redirect_to admin_shop_present_tickets_path(@shop), notice: "プレゼント企画を登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @present_ticket.update(present_ticket_params)
        redirect_to admin_shop_present_tickets_path(@shop), notice: "プレゼント企画を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @present_ticket.destroy
      redirect_to admin_shop_present_tickets_path(@shop), notice: "プレゼント企画を削除しました。"
    end

    def draw
      if @present_ticket.draw!
        redirect_to admin_shop_present_ticket_path(@shop, @present_ticket), notice: "抽選しました。"
      else
        redirect_to admin_shop_present_ticket_path(@shop, @present_ticket), alert: "抽選できませんでした(すでに抽選済みです)。"
      end
    end

    def send_result_emails
      entries = @present_ticket.present_ticket_entries.where(notified_at: nil).where.not(status: :pending)

      sent_count = 0
      entries.find_each do |entry|
        PresentTicketMailer.result_email(entry).deliver_now
        entry.update!(notified_at: Time.current)
        sent_count += 1
      end

      redirect_to admin_shop_present_ticket_path(@shop, @present_ticket), notice: "#{sent_count}件の当落メールを送信しました。"
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:shop_id])
    end

    def set_present_ticket
      @present_ticket = @shop.present_tickets.find(params[:id])
      authorize @present_ticket
    end

    def present_ticket_params
      attrs = params.require(:present_ticket).permit(:name, :description, :capacity, :deadline_at, :fallback_banner, :banner_image)
      if attrs[:banner_image].present?
        # A new file was chosen -- has_one_attached's setter replaces the
        # existing attachment (if any) with this one on save.
      elsif params.dig(:present_ticket, :remove_banner_image) == "1"
        # No new file, but the admin explicitly asked to clear the current
        # one -- assigning nil detaches/purges it.
        attrs[:banner_image] = nil
      else
        # A blank file field submits "" for the attachment, which
        # has_one_attached's setter treats as "remove the current file" --
        # only pass it through when a new file was chosen or removal was
        # requested, so leaving both alone keeps the image as-is.
        attrs.delete(:banner_image)
      end
      attrs
    end
  end
end
