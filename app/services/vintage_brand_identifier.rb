# 古着の写真(タグ・ラベル・全体)と、利用者が読み取った文字情報から、
# ブランド候補・年代の目安・中古相場をAIに推定させる。
#
# どのAIに聞くかは VINTAGE_AI_PROVIDER で切り替える。既定は無料枠のある
# Gemini で、精度を優先したいときは claude を選ぶ -- プロンプトと結果の
# 解釈はここに集約してあるので、切り替えても判定の中身は変わらない。
#
# 結果はあくまで参考情報で、真贋や買取価格を保証するものではない --
# その但し書きは画面側(app/views/vintage)にも必ず出している。
class VintageBrandIdentifier
  class IdentificationError < StandardError; end

  # 判定1件はAIの応答待ちで20〜30秒かかり、その間Pumaのスレッドを1本
  # 占有する。Pumaは既定で3スレッドしかないので、判定が同時に何件も走ると
  # ポータル本体・コーポレートサイトまで巻き込んで応答しなくなる。
  # 同時に走る判定の数をここで絞り、あふれた分は待ってもらう。
  #
  # Pumaをクラスタモードで動かす場合はワーカーごとの上限になるが、
  # 「1ワーカーのスレッドを判定で埋め尽くさない」という目的は変わらない。
  MAX_CONCURRENT = 1
  SLOTS = Concurrent::Semaphore.new(MAX_CONCURRENT)
  BUSY_MESSAGE = "いま判定が混み合っています。30秒ほど待ってから、もう一度お試しください。".freeze

  PROVIDERS = {
    "gemini" => -> { GeminiProvider.new },
    "claude" => -> { ClaudeProvider.new }
  }.freeze
  DEFAULT_PROVIDER = "gemini".freeze

  def self.provider_name
    name = ENV["VINTAGE_AI_PROVIDER"].presence || DEFAULT_PROVIDER
    PROVIDERS.key?(name) ? name : DEFAULT_PROVIDER
  end

  def self.build_provider
    PROVIDERS.fetch(provider_name).call
  end

  # 写真の送り先は利用者にとって重要な情報なので、画面に出す文言も
  # プロバイダの選択と同じ場所に置いておく(view側で分岐させない)。
  def self.privacy_notice
    if provider_name == "gemini"
      "アップロードされた写真はこのサーバーには保存しません。判定のためGoogleのGemini APIへ送信します。" \
        "無料枠での利用中は、送信内容がGoogleのサービス改善(人によるレビューを含む)に利用されることがあります。"
    else
      "アップロードされた写真はこのサーバーには保存しません。判定のためAnthropicのClaude APIへ送信します" \
        "(送信内容がAIの学習に利用されることはありません)。"
    end
  end

  SYSTEM_PROMPT = <<~PROMPT.freeze
    あなたは古着(ヴィンテージ古着)の買い付け・査定を長年行ってきた鑑定者です。
    利用者が持ち込んだ衣類の写真とメモから、ブランドと製造年代を推定してください。

    判定の作法:
    - ブランドロゴそのものより、首元のブランドタグ・洗濯表示・ユニオンチケット・
      縫製(シングルステッチかどうか)・生産国表記・素材表記といった
      「タグまわりの情報」を根拠にすること
    - 参考情報として渡す年代判定の手がかりを踏まえること
    - 断定できないときは無理に断定せず、候補を複数挙げて確度を下げること
    - 根拠は「なぜそう判断したか」が利用者にも確認できる具体的な記述にすること
      (例:「袖口が1本針のシングルステッチ」「タグにMADE IN USAの表記」)
    - 写っていない・読み取れない情報を、あたかも見えたかのように書かないこと
    - 真贋については断定せず、確認すべき点を挙げるにとどめること

    下着・インナーの場合に見るところ:
    - 品質表示タグ(素材・サイズ・製造者)、洗濯絵表示、サイズ表記の書式
      (日本式のB70・C75などのアンダー/カップ表記か、S/M/Lか、海外式の32B等か)
    - ワイヤーの有無、ホックの段数と金具の作り、レースやテープの縫い付け方
    - 日本の品質表示のフォーマットは年代で変わるため、洗濯絵表示が新JIS
      (2016年12月以降の国際規格準拠の記号)か旧JIS(それ以前の日本独自の記号)かが
      年代の大きな手がかりになる

    想定年齢層(target_age)の出し方:
    - これは「そのブランド・ラインが購買層として想定している年齢層」であって、
      その品を着ていた人物の年齢ではない。着用者個人については一切推測しないこと
    - ブランドの位置づけ・価格帯・デザインの傾向から答えること
      (例:「20代前半を中心に、10代後半〜30代前半」)
    - ブランドが特定できない場合はnullにすること

    新品時の定価(original_price)の出し方:
    - そのブランド・アイテムが新品で売られていたときの定価の目安を円で答えること
    - ヴィンテージ品は「当時の定価」、現行品は「現在の定価」とし、どちらの
      つもりで答えたかをnoteに書くこと
    - 分からない場合はnullにすること(推測で数字を置かない)

    中古相場(market_price)の出し方:
    - 日本国内のフリマアプリ・古着屋で、その品が実際に「売られている」価格帯を
      円で答えること(店が買い取る金額ではない)
    - 利用者が申告したコンディションとサイズを反映させること。
      コンディションの申告が無ければ「目立った傷や汚れなし」相当として見積もること
    - ブランドか年代のどちらかが特定できない場合、market_priceはnullにすること
      (根拠のない金額を出さない)
    - 幅は上限が下限の3倍を超えないくらいまでに収め、それ以上ばらつく場合は
      noteでその理由(サイズ・状態・人気の波)を説明すること

    出力は次のキーを持つJSONオブジェクトのみとし、前置き・説明・囲みの記号は
    一切付けないこと。値はすべて日本語で書くこと。

    {
      "item_type": "アイテムの種類(例: デニムジャケット)",
      "brand_candidates": [
        {
          "name": "ブランド名",
          "confidence": "high | medium | low のいずれか",
          "reason": "そのブランドと判断した根拠"
        }
      ],
      "era": "推定年代(例: 1980年代後半〜1990年代前半)",
      "era_reason": "年代をそう推定した根拠",
      "origin": "生産国など分かれば記載",
      "clues": ["写真やメモから読み取れた手がかり"],
      "authenticity_notes": ["真贋・状態について注意して見るべき点"],
      "next_checks": ["判定を絞り込むために追加で撮影・確認するとよい箇所"],
      "target_age": "そのブランドが想定している購買層の年齢層(例: 20代〜30代前半)",
      "target_age_reason": "そう判断した根拠(ブランドの位置づけ・価格帯・デザインの傾向)",
      "original_price": {
        "low": 新品時の定価の下限(日本円の数値のみ),
        "high": 同じく上限(日本円の数値のみ),
        "note": "当時の定価か現在の定価か、どのアイテムを想定したか"
      },
      "market_price": {
        "low": 中古市場で売られている価格帯の下限(日本円の数値のみ。単位や記号は付けない),
        "high": 同じく上限(日本円の数値のみ),
        "note": "その価格帯と判断した前提(想定した状態・サイズ・市場)",
        "factors": ["この品の価格が上下する要因"]
      },
      "summary": "全体の要約(2〜3文)"
    }

    情報が乏しくブランドも年代も推定できない場合は、brand_candidatesを空配列にし、
    next_checksに何を撮れば判定できるようになるかを具体的に書くこと。
  PROMPT

  # @param identification [Vintage::Identification] 入力フォーム
  # @param provider [#configured?, #generate] テストや切り替えのための差し替え口
  def initialize(identification:, provider: nil)
    @identification = identification
    @provider = provider || self.class.build_provider
  end

  def call
    raise IdentificationError, @provider.missing_key_message unless @provider.configured?

    text = with_slot do
      @provider.generate(
        system_prompt: SYSTEM_PROMPT,
        user_prompt: user_prompt,
        images: image_payloads
      )
    end

    Vintage::Result.from_text(text)
  rescue Vintage::Result::ParseError => e
    Rails.logger.error("VintageBrandIdentifier could not parse response: #{e.message}")
    raise IdentificationError, "判定結果をうまく受け取れませんでした。もう一度お試しください。"
  end

  private

  # 空きが無ければ待たせずに断る。待たせるとそのリクエストが結局
  # スレッドを掴んだままになり、守りたかったものが守れない。
  def with_slot
    raise IdentificationError, BUSY_MESSAGE unless SLOTS.try_acquire

    begin
      yield
    ensure
      SLOTS.release
    end
  end

  def user_prompt
    <<~PROMPT
      # 年代判定の参考情報
      #{Vintage::BrandGuide.reference_text}

      # 判定してほしいアイテム
      種類: #{@identification.item_type.presence || "(未選択)"}
      コンディション: #{@identification.condition.presence || "(未選択)"}
      サイズ: #{@identification.size_note.presence || "(記入なし)"}
      写真: #{image_payloads.size}枚
      利用者のメモ(タグの表記など):
      #{@identification.notes.presence || "(記入なし)"}

      上記をもとに、指定のJSON形式でブランドと年代を推定してください。
    PROMPT
  end

  # アップロードされたファイルは一度読んだら読み直しになるので、
  # プロンプトと画像の両方から使えるよう1度だけ取り出す。
  def image_payloads
    @image_payloads ||= @identification.image_payloads
  end
end
