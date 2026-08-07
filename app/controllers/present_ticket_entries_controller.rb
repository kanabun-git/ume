class PresentTicketEntriesController < ApplicationController
  before_action :authenticate_member!

  def create
    ticket = ::PresentTicket.open_for_entry.find(params[:present_ticket_id])

    unless current_member.phone_verified?
      redirect_to new_member_phone_verification_path(return_to: shop_path(ticket.shop)),
        alert: "プレゼント企画への応募にはSMS認証が必要です。"
      return
    end

    current_member.present_ticket_entries.find_or_create_by!(present_ticket: ticket)
    redirect_back fallback_location: shop_path(ticket.shop), notice: "応募しました。抽選結果をお待ちください。"
  end

  def destroy
    entry = current_member.present_ticket_entries.find(params[:id])
    shop = entry.present_ticket.shop

    if entry.pending?
      entry.destroy
      redirect_back fallback_location: shop_path(shop), notice: "応募を取り消しました。"
    else
      redirect_back fallback_location: shop_path(shop), alert: "抽選済みのため取り消せません。"
    end
  end
end
