# Public link-tracking endpoint embedded in ShopProspectMailer#outreach_email.
# Records the prospect's first click (so 営業先候補一覧 shows they came from
# this campaign) then sends them on to the same 掲載のお問い合わせ form any
# other visitor would use -- there's no separate self-service signup screen.
class ShopProspectOutreachController < ApplicationController
  def click
    prospect = ShopProspect.find_by(outreach_token: params[:token])

    if prospect
      prospect.update_column(:outreach_link_clicked_at, Time.current) if prospect.outreach_link_clicked_at.nil?
      # Stashed in session (rather than a URL/hidden-field param) so the
      # link back to this prospect survives the visitor browsing away from
      # the inquiry form and coming back before submitting -- see
      # ShopInquiriesController#create, which reads and clears this.
      session[:shop_prospect_outreach_token] = prospect.outreach_token
    end

    redirect_to new_shop_inquiry_path
  end
end
