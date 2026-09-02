# Public endpoint a member's phone hits after scanning a cast's personal
# check-in QR code (see Cast#checkin_token, CastPortal::CheckInQrController).
# Recording the visit requires a signed-in Member -- if none is signed in,
# the token is stashed in the session and the member is bounced through
# sign-in/sign-up, then redirected back here by
# ApplicationController#after_sign_in_path_for.
class CastCheckInsController < ApplicationController
  before_action :set_cast

  def show
    if member_signed_in?
      @membership = find_or_create_membership
      @already_checked_in_today = @membership.shop_visits.where(visited_at: Time.zone.now.all_day).exists?
      @visit = record_check_in! unless @already_checked_in_today
    else
      session[:pending_cast_check_in_token] = params[:token]
      redirect_to new_member_session_path, notice: "来店ポイントを記録するには会員ログイン(初めての方は会員登録)が必要です。"
    end
  end

  private

  def set_cast
    @cast = Cast.find_by!(checkin_token: params[:token])
  end

  def find_or_create_membership
    current_member.shop_memberships.find_or_create_by!(shop: @cast.shop)
  end

  def record_check_in!
    @membership.record_visit!(visited_at: Time.current, cast: @cast, checked_in_by_qr: true)
  end
end
