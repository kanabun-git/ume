module MemberPortal
  class BaseController < ApplicationController
    before_action :authenticate_member!
    layout "member_portal"
  end
end
