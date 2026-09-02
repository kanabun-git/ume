module Corporate
  # The corporate site's static content pages (トップ / 会社概要 / 事業内容 /
  # アクセス). Deliberately not backed by any DB records -- see
  # Corporate::Company for why.
  class PagesController < BaseController
    def index
      @company = Corporate::Company
    end

    def company
      @company = Corporate::Company
    end

    def business
      @company = Corporate::Company
    end

    def access
      @company = Corporate::Company
    end
  end
end
