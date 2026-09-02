module CorporateHelper
  # 会社概要/アクセスページで共有する住所表示。BUILDINGが未設定(nilや空)の
  # 会社もあるので、その場合は建物名の行を出さない。
  def corporate_address
    lines = ["〒#{Corporate::Company::POSTAL_CODE} #{Corporate::Company::ADDRESS}"]
    lines << Corporate::Company::BUILDING if Corporate::Company::BUILDING.present?
    safe_join(lines, tag.br)
  end
end
