module Vintage
  # 古着ブランド判定ツール(/vintage)の共通土台。ポータル本体ともコーポレート
  # サイトとも独立した、ログイン不要の一般公開ツールなので、認証も権限判定も
  # 持たない -- レイアウトを差し替えるだけ。
  class BaseController < ApplicationController
    layout "vintage"
  end
end
