# Public endpoint a member's phone hits after scanning a cast's personal
# check-in QR code (see Cast#checkin_token, CastPortal::CheckInQrController).
# Recording the visit requires a signed-in Member -- if none is signed in,
# the token is stashed in the session and the member is bounced through
# sign-in/sign-up, then redirected back here by
# ApplicationController#after_sign_in_path_for.
class CastCheckInsController < ApplicationController
  # Blocks a second QR scan too soon after the last one, regardless of
  # which cast's QR either scan was -- guards against the same visit
  # earning points/rank progress twice (an accidental double tap, a phone
  # camera app scanning the same code repeatedly, re-opening the link from
  # browser history, etc), while still allowing a genuinely separate visit
  # later the same day.
  COOLDOWN_MINUTES = 60

  before_action :set_cast

  def show
    if member_signed_in?
      @membership = find_or_create_membership
      last_visit = @membership.shop_visits.first
      @cooldown_ends_at = last_visit && last_visit.visited_at + COOLDOWN_MINUTES.minutes
      @in_cooldown = @cooldown_ends_at.present? && Time.current < @cooldown_ends_at
      @visit = record_check_in! unless @in_cooldown
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
