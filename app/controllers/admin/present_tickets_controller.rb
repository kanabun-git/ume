module Admin
  class PresentTicketsController < BaseController
    before_action :set_shop

    def index
      @present_tickets = @shop.present_tickets
    end

    def show
      @present_ticket = @shop.present_tickets.find(params[:id])
      authorize @present_ticket
      @entries = @present_ticket.present_ticket_entries.includes(:member).order(:created_at)
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:shop_id])
    end
  end
end
