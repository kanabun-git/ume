const pptxgen = require('pptxgenjs');
const fs = require('fs');

const DIR = '/home/user/ume/docs/images/sales/';
const OUT = '/home/user/ume/docs/fuzokuzero_sales_deck.pptx';

// --- palette: taken from the brand logo (brush pink -> violet) ------------
const BRAND = 'E0356B';
const BRAND_D = 'B5204F';
const VIOLET = '7B3F98';   // the violet the logo's brush ring fades into
const DEEP = '5E0F2C';
const DEEPER = '3B0819';
const GOLD = 'C9A227';
const INK = '1F1A24';
const MUTED = '7C7280';
const TINT = 'FDF3F7';
const WHITE = 'FFFFFF';
const LINE = 'EBDDE4';
const PINKLT = 'FFC2D6';

// Brush-calligraphy logo -> a mincho (serif) heading echoes it; body stays
// gothic for legibility at small sizes.
const SERIF = 'Yu Mincho';
const SANS = 'Meiryo';
const LATIN = 'Arial';

const LOGO = 'logo_h_alpha.png';   // white knocked out: sits on any light ground

const pres = new pptxgen();
pres.layout = 'LAYOUT_WIDE'; // 13.333 x 7.5
pres.author = '風俗Zero';
pres.title = '風俗Zero 掲載のご案内';

const W = 13.333, M = 0.62;
let PAGE = 0;

function ar(file) {
  const b = fs.readFileSync(DIR + file);
  return b.readUInt32BE(16) / b.readUInt32BE(20);
}
const sh = (o = {}) => Object.assign(
  { type: 'outer', color: '2E0714', opacity: 0.20, blur: 14, offset: 3, angle: 90 }, o);

function frame(slide, file, x, y, w) {
  const h = w / ar(file);
  slide.addShape(pres.ShapeType.roundRect, {
    x: x - 0.07, y: y - 0.07, w: w + 0.14, h: h + 0.14,
    fill: { color: WHITE }, rectRadius: 0.07,
    line: { color: LINE, width: 0.75 }, shadow: sh(),
  });
  slide.addImage({ path: DIR + file, x, y, w, h });
  return y + h;
}

function card(slide, x, y, w, h, fill = WHITE) {
  slide.addShape(pres.ShapeType.roundRect, {
    x, y, w, h, fill: { color: fill }, rectRadius: 0.1,
    line: { color: LINE, width: 0.75 }, shadow: sh({ opacity: 0.13, blur: 10, offset: 2 }),
  });
}

function numCircle(slide, n, x, y, d = 0.52, bg = BRAND, fg = WHITE) {
  slide.addShape(pres.ShapeType.ellipse, { x, y, w: d, h: d, fill: { color: bg } });
  slide.addText(String(n), {
    x, y, w: d, h: d, align: 'center', valign: 'middle',
    fontFace: SERIF, fontSize: d > 0.5 ? 17 : 13, bold: true, color: fg, margin: 0,
  });
}

function chip(slide, text, x, y, w, h = 0.42, fill = BRAND, color = WHITE, size = 11.5) {
  slide.addShape(pres.ShapeType.roundRect, { x, y, w, h, fill: { color: fill }, rectRadius: 0.2, line: { type: 'none' } });
  slide.addText(text, { x, y, w, h, align: 'center', valign: 'middle', fontFace: SANS, fontSize: size, bold: true, color, margin: 0 });
}

// Header block shared by every content slide: a letterspaced English kicker,
// a mincho headline, then a gothic lede.
function header(slide, kicker, headline, ledeText, opts = {}) {
  const dark = !!opts.dark;
  slide.addText(kicker, {
    x: M, y: 0.40, w: 9.0, h: 0.24, fontFace: LATIN, fontSize: 10, bold: true,
    charSpacing: 3, color: dark ? PINKLT : BRAND, valign: 'middle', margin: 0,
  });
  slide.addText(headline, {
    x: M, y: 0.60, w: 10.3, h: 0.80, fontFace: SERIF, fontSize: opts.size || 33, bold: true,
    charSpacing: 0.6, color: dark ? WHITE : INK, valign: 'middle', margin: 0,
  });
  if (ledeText) {
    slide.addText(ledeText, {
      x: M, y: 1.44, w: opts.ledeW || (W - M * 2), h: opts.ledeH || 0.40, fontFace: SANS, fontSize: 13.5,
      color: opts.ledeColor || (dark ? PINKLT : MUTED), valign: 'top', margin: 0, lineSpacingMultiple: 1.2,
    });
  }
  // brand mark, top right — on dark grounds it needs a light plate to read
  if (dark) {
    slide.addShape(pres.ShapeType.roundRect, {
      x: W - M - 1.42, y: 0.36, w: 1.42, h: 0.62, fill: { color: WHITE }, rectRadius: 0.08, line: { type: 'none' },
    });
    slide.addImage({ path: DIR + LOGO, x: W - M - 1.32, y: 0.45, w: 1.22, h: 1.22 / ar(LOGO) });
  } else {
    slide.addImage({ path: DIR + LOGO, x: W - M - 1.22, y: 0.46, w: 1.22, h: 1.22 / ar(LOGO) });
  }
}

function pageNo(slide, dark = false) {
  PAGE += 1;
  slide.addText(String(PAGE).padStart(2, '0'), {
    x: W - M - 1.0, y: 7.0, w: 1.0, h: 0.3, fontFace: LATIN, fontSize: 9.5,
    charSpacing: 1.5, color: dark ? PINKLT : MUTED, align: 'right', valign: 'middle', margin: 0,
  });
}

function bg(slide, color) { slide.background = { color }; }

// glow blobs used on the dark slides, echoing the logo's pink->violet ring
function glow(slide, x, y, d, color, transparency) {
  slide.addShape(pres.ShapeType.ellipse, { x, y, w: d, h: d, fill: { color, transparency }, line: { type: 'none' } });
}

// ============================================================ 1. cover
{
  const s = pres.addSlide();
  bg(s, DEEP);
  glow(s, -2.0, 4.0, 4.6, BRAND, 76);
  glow(s, 4.9, -2.4, 3.6, VIOLET, 72);
  glow(s, 10.2, 5.6, 4.2, VIOLET, 84);

  // logo on a white plate so the black calligraphy reads against the dark ground
  s.addShape(pres.ShapeType.roundRect, {
    x: 0.85, y: 1.18, w: 4.55, h: 1.72, fill: { color: WHITE }, rectRadius: 0.14,
    line: { type: 'none' }, shadow: sh({ opacity: 0.34, blur: 20, offset: 5 }),
  });
  s.addImage({ path: DIR + LOGO, x: 1.06, y: 1.38, w: 4.13, h: 4.13 / ar(LOGO) });

  s.addText('MEDIA GUIDE FOR SHOPS', {
    x: 0.85, y: 3.22, w: 6.2, h: 0.28, fontFace: LATIN, fontSize: 11, bold: true,
    charSpacing: 4, color: PINKLT, valign: 'middle', margin: 0,
  });
  s.addText('掲載のご案内', {
    x: 0.85, y: 3.52, w: 6.2, h: 0.95, fontFace: SERIF, fontSize: 46, bold: true,
    charSpacing: 2, color: WHITE, valign: 'middle', margin: 0,
  });
  s.addText('エリア・ジャンルから探せる風俗ポータルサイト', {
    x: 0.85, y: 4.52, w: 6.2, h: 0.36, fontFace: SANS, fontSize: 13, color: PINKLT, valign: 'middle', margin: 0,
  });

  chip(s, '体験動画 完全代行', 0.85, 5.14, 2.15, 0.44, BRAND, WHITE, 11);
  chip(s, 'プレゼント企画', 3.10, 5.14, 1.85, 0.44, VIOLET, WHITE, 11);
  chip(s, '自由なページ設計', 5.05, 5.14, 2.05, 0.44, GOLD, DEEPER, 11);

  frame(s, 'pub_top.png', 7.55, 1.60, 5.25);
  s.addText('実際の掲載イメージ(トップページ)', {
    x: 7.55, y: 5.24, w: 5.25, h: 0.3, fontFace: SANS, fontSize: 10, color: PINKLT, align: 'center', margin: 0,
  });
  s.addText('店舗様向け ご提案資料', {
    x: 0.85, y: 6.42, w: 6.2, h: 0.32, fontFace: SANS, fontSize: 11, color: PINKLT, margin: 0,
  });
  s.addNotes('表紙。風俗Zeroは、エリア・ジャンルから店舗と在籍女の子を探せるポータル。本日は掲載メリットを3点に絞ってご説明します。');
  PAGE += 1; // cover is page 1; no number printed on it
}

// ============================================================ 2. what it is
{
  const s = pres.addSlide();
  bg(s, WHITE);
  header(s, 'ABOUT', '風俗Zeroとは',
    'エリア・ジャンル・料金・キャストの条件から探せる総合ポータル。店舗ページ・女の子ページ・写メ日記・出勤・クーポンをまとめて掲載できます。',
    { ledeH: 0.5 });

  const w = 3.83, gap = 0.42;
  const xs = [M, M + w + gap, M + (w + gap) * 2];
  const files = ['pub_casts.png', 'pub_shop_standard.png', 'pub_cast_detail.png'];
  const caps = ['女の子検索', '店舗ページ', '女の子ページ'];
  const subs = ['エリア・ジャンル・年齢・スリーサイズ\nなど条件で横断検索', 'ブロック構成で自由に組める\n店舗の“顔”になるページ', 'プロフィール・出勤・日記・口コミを\n1ページに集約'];
  xs.forEach((x, i) => {
    frame(s, files[i], x, 2.20, w);
    s.addText(caps[i], { x, y: 4.90, w, h: 0.36, fontFace: SERIF, fontSize: 16, bold: true, color: BRAND_D, align: 'center', margin: 0 });
    s.addText(subs[i], { x, y: 5.30, w, h: 0.72, fontFace: SANS, fontSize: 11, color: MUTED, align: 'center', margin: 0, lineSpacingMultiple: 1.15 });
  });
  pageNo(s);
  s.addNotes('掲載範囲の全体像。1店舗の掲載で、店舗ページ・在籍女の子ページ・日記・出勤・クーポンまでカバーされます。');
}

// ============================================================ 3. three reasons
{
  const s = pres.addSlide();
  bg(s, TINT);
  header(s, 'WHY 風俗Zero', '選ばれる3つの理由',
    '「手間をかけずに」「集客につながり」「自店らしく見せられる」— この3点にこだわっています。');

  const w = 3.83, gap = 0.42, y = 2.14, h = 4.16;
  const xs = [M, M + w + gap, M + (w + gap) * 2];
  const kick = ['REASON 01', 'REASON 02', 'REASON 03'];
  const heads = ['体験動画を\n撮影から掲載まで代行', 'プレゼント企画で\n新規とリピートを獲得', 'ページ構成もデザインも\n店舗様の自由'];
  const bodies = [
    '撮影・編集・アップロードまで弊社が担当。店舗様にご用意いただくものはありません。動画は店舗ページと体験動画一覧の両方に掲載されます。',
    '抽選プレゼントをワンクリックで開催。応募にはSMS認証が必須のため、いたずら応募を防ぎながら会員との接点をつくれます。',
    '10種類のブロックを並び替え・表示切替でき、背景色・文字色・基調色・背景画像まで管理画面から変更できます。',
  ];
  xs.forEach((x, i) => {
    card(s, x, y, w, h);
    numCircle(s, i + 1, x + 0.34, y + 0.36, 0.58);
    s.addText(kick[i], {
      x: x + 1.04, y: y + 0.46, w: w - 1.3, h: 0.32, fontFace: LATIN, fontSize: 10, bold: true,
      charSpacing: 2.5, color: BRAND, valign: 'middle', margin: 0,
    });
    s.addText(heads[i], { x: x + 0.34, y: y + 1.14, w: w - 0.68, h: 1.0, fontFace: SERIF, fontSize: 17.5, bold: true, color: INK, margin: 0, lineSpacingMultiple: 1.22 });
    s.addText(bodies[i], { x: x + 0.34, y: y + 2.28, w: w - 0.68, h: 1.7, fontFace: SANS, fontSize: 12, color: MUTED, margin: 0, lineSpacingMultiple: 1.3 });
  });
  pageNo(s);
  s.addNotes('この3点を、次のスライドから順にご説明します。');
}

// ============================================================ 4. reason 1 - video
{
  const s = pres.addSlide();
  bg(s, WHITE);
  header(s, 'REASON 01 — 体験動画', '撮影から掲載まで、すべて弊社が代行',
    '店舗様の作業はゼロ。撮影の日程調整だけで、公開まで弊社が対応します。', { ledeColor: BRAND_D });

  const w = 3.83, gap = 0.42, y = 2.02, h = 1.72;
  const xs = [M, M + w + gap, M + (w + gap) * 2];
  const steps = [
    ['撮影', '弊社スタッフが店舗様へ訪問し撮影。機材・人員のご用意は不要です。'],
    ['編集', 'テロップ・尺の調整まで弊社で編集。掲載に適した形へ仕上げます。'],
    ['掲載', '運営側でアップロード。容量の大きい動画もそのまま掲載できます。'],
  ];
  xs.forEach((x, i) => {
    card(s, x, y, w, h, TINT);
    s.addText(`STEP 0${i + 1}`, { x: x + 0.3, y: y + 0.18, w: w - 0.6, h: 0.24, fontFace: LATIN, fontSize: 9, bold: true, charSpacing: 2, color: BRAND, margin: 0 });
    s.addText(steps[i][0], { x: x + 0.3, y: y + 0.42, w: w - 0.6, h: 0.42, fontFace: SERIF, fontSize: 19, bold: true, color: BRAND_D, margin: 0 });
    s.addText(steps[i][1], { x: x + 0.3, y: y + 0.92, w: w - 0.6, h: 0.72, fontFace: SANS, fontSize: 11, color: MUTED, margin: 0, lineSpacingMultiple: 1.22 });
    if (i < 2) s.addText('▶', { x: x + w + 0.02, y: y + 0.62, w: 0.38, h: 0.5, fontFace: SANS, fontSize: 14, bold: true, color: BRAND, align: 'center', valign: 'middle', margin: 0 });
  });

  frame(s, 'pub_videos.png', M, 4.08, 6.35);
  const rx = 7.35;
  card(s, rx, 4.01, 5.36, 2.88, TINT);
  s.addText('動画がもたらす効果', { x: rx + 0.24, y: 4.22, w: 4.9, h: 0.36, fontFace: SERIF, fontSize: 16, bold: true, color: INK, margin: 0 });
  s.addText([
    { text: '文字と写真だけでは伝わらない店内・接客の雰囲気を訴求', options: { bullet: true, breakLine: true } },
    { text: '「体験動画」一覧ページからの新規流入を獲得', options: { bullet: true, breakLine: true } },
    { text: '店舗ページ内の動画ブロックにも自動で表示', options: { bullet: true, breakLine: true } },
    { text: '撮り直し・差し替えのご相談も随時対応', options: { bullet: true } },
  ], { x: rx + 0.24, y: 4.68, w: 4.9, h: 2.0, fontFace: SANS, fontSize: 11.5, color: INK, margin: 0, paraSpaceAfter: 8 });
  pageNo(s);
  s.addNotes('体験動画は弊社で撮影・編集・アップロードまで実施。店舗様の手間はゼロという点を強調してください。');
}

// ============================================================ 5. reason 2 - present
{
  const s = pres.addSlide();
  bg(s, TINT);
  header(s, 'REASON 02 — プレゼント企画', '新規集客とリピートを、同時に',
    '抽選企画の作成から当落メール送信まで、管理画面だけで完結します。', { ledeColor: BRAND_D });

  const lx = M, lw = 6.0;
  const flow = [
    ['企画を作成', '企画名・当選人数・応募締切を入力するだけ'],
    ['会員が応募', '店舗ページから会員がワンタップで応募'],
    ['ワンクリック抽選', '締切後、当選者を自動でランダム抽選'],
    ['当落メール送信', '当選・落選を一斉送信。送信済みは再送されません'],
  ];
  let y = 2.02;
  flow.forEach((f, i) => {
    numCircle(s, i + 1, lx, y + 0.05, 0.42);
    s.addText(f[0], { x: lx + 0.62, y: y - 0.04, w: lw - 0.62, h: 0.32, fontFace: SERIF, fontSize: 15, bold: true, color: INK, margin: 0 });
    s.addText(f[1], { x: lx + 0.62, y: y + 0.30, w: lw - 0.62, h: 0.3, fontFace: SANS, fontSize: 11, color: MUTED, margin: 0 });
    y += 0.78;
  });

  card(s, lx, 5.26, lw, 1.45, WHITE);
  s.addText('集客につながる理由', { x: lx + 0.28, y: 5.40, w: lw - 0.56, h: 0.32, fontFace: SERIF, fontSize: 14.5, bold: true, color: BRAND_D, margin: 0 });
  s.addText([
    { text: '応募にはSMS認証が必須 — いたずら応募を防ぎ、実在の見込み客だけが集まる', options: { bullet: true, breakLine: true } },
    { text: '締切前はお気に入り会員へリマインドメールが自動配信され、再訪を促せる', options: { bullet: true } },
  ], { x: lx + 0.28, y: 5.76, w: lw - 0.56, h: 0.86, fontFace: SANS, fontSize: 11, color: INK, margin: 0, paraSpaceAfter: 5 });

  const rx = 7.0, rw = 5.71;
  frame(s, 'sa_present_index.png', rx, 2.02, rw);
  s.addText('管理画面:企画の登録と応募状況の確認', { x: rx, y: 3.76, w: rw, h: 0.3, fontFace: SANS, fontSize: 10.5, color: MUTED, align: 'center', margin: 0 });
  frame(s, 'pub_present_section.png', rx, 4.36, rw);
  s.addText('公開ページ:会員はワンタップで応募', { x: rx, y: 6.24, w: rw, h: 0.3, fontFace: SANS, fontSize: 10.5, color: MUTED, align: 'center', margin: 0 });
  pageNo(s);
  s.addNotes('プレゼント企画は集客の目玉。SMS認証で応募者の質が担保される点、締切リマインドメールで再訪導線がある点が差別化。');
}

// ============================================================ 6. reason 3 - blocks
{
  const s = pres.addSlide();
  bg(s, WHITE);
  header(s, 'REASON 03 — ページ構成', 'ブロックを、店舗様が自由に組み替え',
    '10種類のブロックを、並び替え・表示/非表示・背景色の設定で自由に構成できます。制作会社への依頼は不要です。');

  frame(s, 'sa_blocks.png', M, 2.02, 6.5);
  s.addText('管理画面「ページ構成(ブロック管理)」', { x: M, y: 6.52, w: 6.5, h: 0.3, fontFace: SANS, fontSize: 10.5, color: MUTED, align: 'center', margin: 0 });

  const rx = 7.5, rw = 5.21;
  s.addText('使えるブロック(10種類)', { x: rx, y: 2.02, w: rw, h: 0.36, fontFace: SERIF, fontSize: 16, bold: true, color: INK, margin: 0 });
  const blocks = ['店舗フォトギャラリー', '動画', '新人・体験入店', '店長おすすめ', '写メ日記', '週間出勤', '口コミランキング', 'クーポン', '料金表・オプション表', 'フリーテキスト'];
  const cw = 2.5, ch = 0.42;
  blocks.forEach((b, i) => {
    const x = rx + (i % 2) * (cw + 0.21);
    const yy = 2.50 + Math.floor(i / 2) * (ch + 0.13);
    chip(s, b, x, yy, cw, ch, TINT, BRAND_D, 10.5);
  });
  card(s, rx, 5.40, rw, 1.32, TINT);
  s.addText([
    { text: '▲▼ボタンで並び替え、ワンクリックで表示/非表示', options: { bullet: true, breakLine: true } },
    { text: '女の子ページも同様に2カラムで構成を変更可能', options: { bullet: true } },
  ], { x: rx + 0.26, y: 5.58, w: rw - 0.52, h: 1.0, fontFace: SANS, fontSize: 11, color: INK, margin: 0, paraSpaceAfter: 6 });
  pageNo(s);
  s.addNotes('他社ポータルはテンプレート固定が多い。こちらは店舗側で構成を組み替えられる点が強み。');
}

// ============================================================ 7. design freedom
{
  const s = pres.addSlide();
  bg(s, TINT);
  header(s, 'REASON 03 — デザイン', '色も背景も、自店らしく',
    '背景色・基調文字色・基調色(ボタンやバッジの色)・背景画像を、管理画面から設定できます。');

  const w = 5.9, y = 2.38;
  const xs = [M, M + w + 0.29];
  const caps = ['標準デザイン', 'カスタマイズ例(背景・文字・基調色を変更)'];
  ['pub_shop_standard.png', 'pub_shop_themed.png'].forEach((f, i) => {
    chip(s, caps[i], xs[i], 1.94, w, 0.38, i === 0 ? MUTED : BRAND, WHITE, 11);
    frame(s, f, xs[i], y, w);
  });
  s.addText('※ 白いカード内の文字色は自動で読みやすさを保つため、背景を濃くしても店舗情報が読めなくなることはありません。', {
    x: M, y: 6.56, w: W - M * 2, h: 0.4, fontFace: SANS, fontSize: 11, color: MUTED, margin: 0,
  });
  pageNo(s);
  s.addNotes('同一店舗ページの標準/カスタム比較。ブランドカラーを持つ店舗様に刺さる訴求。');
}

// ============================================================ 8. membership
{
  const s = pres.addSlide();
  bg(s, WHITE);
  header(s, 'MEMBERSHIP', '“店舗会員証”でリピーターを育てる',
    '来店回数に応じて自動ランクアップ。ポイントと特典で再来店の動機をつくります。');

  frame(s, 'member_card.png', M, 2.02, 4.1);
  s.addText('会員証には店舗名・会員名・会員番号・発行日を表示', { x: M, y: 4.42, w: 4.1, h: 0.3, fontFace: SANS, fontSize: 10.5, color: MUTED, align: 'center', margin: 0 });
  s.addText([
    { text: '来店回数に応じてランクが自動で上がる', options: { bullet: true, breakLine: true } },
    { text: 'ランク到達で割引券・無料券を自動付与', options: { bullet: true, breakLine: true } },
    { text: '来店ごとのポイント加算・利用も記録できる', options: { bullet: true, breakLine: true } },
    { text: '会員証のデザインはランクごとに差し替え可能', options: { bullet: true, breakLine: true } },
    { text: '事故歴・注意点は店舗内だけで共有(会員には非表示)', options: { bullet: true } },
  ], { x: M, y: 4.88, w: 5.5, h: 2.0, fontFace: SANS, fontSize: 12, color: INK, margin: 0, paraSpaceAfter: 7 });

  const rx = 6.9, rw = 5.81;
  frame(s, 'sa_ranks.png', rx, 2.02, rw);
  s.addText('管理画面:ランクと特典の設定', { x: rx, y: 6.08, w: rw, h: 0.3, fontFace: SANS, fontSize: 10.5, color: MUTED, align: 'center', margin: 0 });
  pageNo(s);
  s.addNotes('会員証は他ポータルにない機能。店舗のCRMをポータル側で持てるため、乗り換え障壁にもなる。');
}

// ============================================================ 9. coupons
{
  const s = pres.addSlide();
  bg(s, TINT);
  header(s, 'COUPON', 'クーポンは「最安値バッジ」と利用実績まで',
    'コース単位で登録でき、サイト内のクーポン一覧にも自動掲載。効果は利用実績で確認できます。');

  frame(s, 'pub_coupons.png', M, 2.02, 6.1);
  s.addText('公開ページ:クーポンで探す', { x: M, y: 6.28, w: 6.1, h: 0.3, fontFace: SANS, fontSize: 10.5, color: MUTED, align: 'center', margin: 0 });

  const rx = 7.1, rw = 5.61;
  frame(s, 'sa_coupons.png', rx, 2.02, rw);
  s.addText('管理画面:クーポン管理と利用実績', { x: rx, y: 3.70, w: rw, h: 0.3, fontFace: SANS, fontSize: 10.5, color: MUTED, align: 'center', margin: 0 });
  card(s, rx, 4.18, rw, 2.38, WHITE);
  s.addText([
    { text: '同一コースで最も安いクーポンに「最安値」バッジを自動表示', options: { bullet: true, breakLine: true } },
    { text: 'ネット予約のクリックは自動で利用実績として記録', options: { bullet: true, breakLine: true } },
    { text: '来店・電話予約はボタン1つで手動記録でき、経路別に集計', options: { bullet: true, breakLine: true } },
    { text: '期間を過ぎたクーポンは自動で非表示。削除の手間なし', options: { bullet: true } },
  ], { x: rx + 0.26, y: 4.38, w: rw - 0.52, h: 2.0, fontFace: SANS, fontSize: 11.5, color: INK, margin: 0, paraSpaceAfter: 7 });
  pageNo(s);
  s.addNotes('クーポンは「出して終わり」ではなく効果測定までできる点を訴求。');
}

// ============================================================ 10. cast operations
{
  const s = pres.addSlide();
  bg(s, WHITE);
  header(s, 'CAST SUPPORT', '日々の更新は、キャスト本人がかんたんに',
    '写メ日記も出勤予定もキャスト本人が更新可能。店舗側の入力負担を減らします。');

  const w = 5.9;
  const xs = [M, M + w + 0.29];
  chip(s, '写メ日記 — AIが下書きを作成', xs[0], 1.94, w, 0.38, BRAND, WHITE, 11.5);
  frame(s, 'cast_portal_diary_new.png', xs[0], 2.36, w);
  s.addText('伝えたいことを一言入れるだけで日記の下書きを自動生成。更新頻度を保てます。', {
    x: xs[0], y: 6.50, w, h: 0.44, fontFace: SANS, fontSize: 10.5, color: MUTED, margin: 0,
  });

  chip(s, '出勤予定 — 期間×曜日で一括登録', xs[1], 1.94, w, 0.38, VIOLET, WHITE, 11.5);
  frame(s, 'sa_shifts.png', xs[1], 2.36, w);
  s.addText('店舗側は期間と曜日を選ぶだけで一括登録。CSV取り込みにも対応しています。', {
    x: xs[1], y: 6.50, w, h: 0.44, fontFace: SANS, fontSize: 10.5, color: MUTED, margin: 0,
  });
  pageNo(s);
  s.addNotes('更新が続くかどうかが掲載効果を左右する。入力負担を下げる仕組みがある点を説明。');
}

// ============================================================ 11. staff portal
{
  const s = pres.addSlide();
  bg(s, TINT);
  header(s, 'PRIVACY', 'キャスト専用ポータルは“バレにくさ”に配慮',
    '在籍キャストが人前でスマホを開いても、業種が分かりにくい設計にしています。求人・定着の訴求材料にもなります。');

  frame(s, 'cast_portal_dash.png', M, 2.06, 6.35);

  const rx = 7.35, rw = 5.36;
  const items = [
    ['専用ドメインで運用できる', 'サイト本体とは別の、業種を連想させないURLでのみ開ける設定にできます。'],
    ['サイト名もロゴも出さない', '画面上の表記は「スタッフポータル」。ログイン画面から中立デザインです。'],
    ['ホーム画面に追加しても安心', 'アイコン名も「スタッフポータル」。並んでいても分かりません。'],
    ['本人が出勤・日記を更新', 'プロフィール・出勤予定・写メ日記をキャスト本人が管理できます。'],
  ];
  let yy = 2.06;
  items.forEach((it, i) => {
    numCircle(s, i + 1, rx, yy + 0.04, 0.42);
    s.addText(it[0], { x: rx + 0.62, y: yy - 0.04, w: rw - 0.62, h: 0.32, fontFace: SERIF, fontSize: 14.5, bold: true, color: INK, margin: 0 });
    s.addText(it[1], { x: rx + 0.62, y: yy + 0.32, w: rw - 0.62, h: 0.62, fontFace: SANS, fontSize: 11, color: MUTED, margin: 0, lineSpacingMultiple: 1.2 });
    yy += 1.12;
  });
  pageNo(s);
  s.addNotes('女の子の採用・定着の観点で刺さるポイント。同一システム・同一データのまま、URLと見た目だけを分けている。');
}

// ============================================================ 12. analytics (dark)
{
  const s = pres.addSlide();
  bg(s, DEEP);
  glow(s, 11.0, -1.8, 4.0, VIOLET, 80);
  glow(s, -1.8, 5.2, 3.6, BRAND, 84);
  header(s, 'ANALYTICS', '掲載効果は「数字」で確認できます',
    '店舗ページ・女の子ページそれぞれの閲覧数を、日別の推移とランキングで確認できます。', { dark: true });

  const w = 5.9;
  const xs = [M, M + w + 0.29];
  chip(s, '店舗ページ別', xs[0], 1.98, w, 0.38, BRAND, WHITE, 11.5);
  frame(s, 'ad_analytics_shop.png', xs[0], 2.42, w);
  chip(s, '女の子ページ別', xs[1], 1.98, w, 0.38, GOLD, DEEPER, 11.5);
  frame(s, 'ad_analytics_cast.png', xs[1], 2.42, w);
  s.addText('直近30日の日別推移／閲覧数の多い順ランキング(累計・直近30日の両方を表示)。どの女の子が集客できているかまで把握できます。', {
    x: M, y: 6.58, w: W - M * 2, h: 0.4, fontFace: SANS, fontSize: 11.5, color: PINKLT, margin: 0,
  });
  pageNo(s, true);
  s.addNotes('掲載料の費用対効果を説明する材料。女の子単位で見られるのは他にあまりない。');
}

// ============================================================ 13. other features
{
  const s = pres.addSlide();
  bg(s, WHITE);
  header(s, 'FEATURES', 'その他の標準搭載機能',
    '掲載プランに関わらず、以下の機能をすべてご利用いただけます。');

  const items = [
    ['口コミ管理', '店舗からの返信と定型文テンプレートに対応'],
    ['SMS認証', '会員は電話番号認証済み。荒らし・不正応募を抑止'],
    ['画像モデレーション', '不適切な写真は運営側で個別に非公開化'],
    ['お気に入り通知メール', '新着日記・本日出勤を会員へ自動配信し再訪を促進'],
    ['ランキング掲載', '閲覧数・口コミ評価をもとにサイト内で露出'],
    ['エリア・ジャンル検索', '料金やカップ数など条件検索の対象に'],
    ['PRバッジ', '表示期間を店舗様ご自身で設定可能'],
    ['日次自動バックアップ', 'データは毎日自動で保全'],
  ];
  const cw = 2.9, chh = 1.72, gx = 0.17, gy = 0.2;
  items.forEach((it, i) => {
    const x = M + (i % 4) * (cw + gx);
    const y = 2.18 + Math.floor(i / 4) * (chh + gy);
    card(s, x, y, cw, chh, TINT);
    s.addShape(pres.ShapeType.ellipse, { x: x + 0.26, y: y + 0.28, w: 0.32, h: 0.32, fill: { color: BRAND } });
    s.addText(it[0], { x: x + 0.68, y: y + 0.22, w: cw - 0.92, h: 0.44, fontFace: SERIF, fontSize: 13, bold: true, color: INK, valign: 'middle', margin: 0 });
    s.addText(it[1], { x: x + 0.26, y: y + 0.76, w: cw - 0.52, h: 0.82, fontFace: SANS, fontSize: 10.5, color: MUTED, margin: 0, lineSpacingMultiple: 1.2 });
  });

  card(s, M, 6.02, W - M * 2, 0.92, WHITE);
  s.addText('掲載プランはフリー／スタンダード／プレミアムの3段階。プランにより検索結果での掲載順位の優先度と「Zeroお勧め」バッジの有無が変わります(料金は別途ご案内)。', {
    x: M + 0.3, y: 6.16, w: W - M * 2 - 0.6, h: 0.64, fontFace: SANS, fontSize: 11.5, color: INK, valign: 'middle', margin: 0,
  });
  pageNo(s);
  s.addNotes('機能の網羅性を見せるスライド。プラン料金はここでは出さず、別紙・口頭でご案内。');
}

// ============================================================ 14. flow + CTA (dark)
{
  const s = pres.addSlide();
  bg(s, DEEP);
  glow(s, -2.0, 4.8, 4.2, BRAND, 78);
  glow(s, 10.6, -2.0, 3.6, VIOLET, 82);
  header(s, 'FLOW & CONTACT', '掲載までの流れ',
    'お問い合わせから公開まで、専任の担当がサポートいたします。', { dark: true });

  const w = 2.9, gx = 0.17, y = 2.06, hh = 2.05;
  const steps = [
    ['お問い合わせ', 'サイトの「掲載のお問い合わせ」フォーム、またはご担当者まで'],
    ['ヒアリング', '掲載内容・プラン・撮影日程をご相談'],
    ['撮影・ページ制作', '体験動画の撮影・編集、店舗ページを準備'],
    ['公開・運用サポート', '公開後もページ構成や企画運用をサポート'],
  ];
  steps.forEach((st, i) => {
    const x = M + i * (w + gx);
    card(s, x, y, w, hh, WHITE);
    numCircle(s, i + 1, x + 0.26, y + 0.24, 0.46);
    s.addText(st[0], { x: x + 0.26, y: y + 0.84, w: w - 0.52, h: 0.36, fontFace: SERIF, fontSize: 14, bold: true, color: INK, margin: 0 });
    s.addText(st[1], { x: x + 0.26, y: y + 1.22, w: w - 0.52, h: 0.72, fontFace: SANS, fontSize: 10.5, color: MUTED, margin: 0, lineSpacingMultiple: 1.2 });
    if (i < 3) s.addText('▶', { x: x + w, y: y + 0.80, w: 0.17, h: 0.4, fontFace: SANS, fontSize: 12, bold: true, color: PINKLT, align: 'center', valign: 'middle', margin: 0 });
  });

  s.addShape(pres.ShapeType.roundRect, {
    x: M, y: 4.52, w: W - M * 2, h: 1.70, fill: { color: BRAND }, rectRadius: 0.14,
    line: { type: 'none' }, shadow: sh({ opacity: 0.32, blur: 18, offset: 4 }),
  });
  s.addText('掲載のご相談・お見積りはお気軽にどうぞ', {
    x: M + 0.5, y: 4.74, w: 11.1, h: 0.5, fontFace: SERIF, fontSize: 22, bold: true, charSpacing: 1, color: WHITE, valign: 'middle', margin: 0,
  });
  s.addText('サイト内「掲載のお問い合わせ」フォーム、または担当者へご連絡ください。掲載プラン・料金は内容に応じて個別にご案内いたします。', {
    x: M + 0.5, y: 5.30, w: 11.1, h: 0.72, fontFace: SANS, fontSize: 11.5, color: 'FFE3EC', margin: 0, lineSpacingMultiple: 1.2,
  });

  s.addText('ゼロから始める風俗体験', {
    x: M, y: 6.48, w: W - M * 2, h: 0.34, fontFace: SERIF, fontSize: 12, charSpacing: 3, color: PINKLT, align: 'center', margin: 0,
  });
  pageNo(s, true);
  s.addNotes('クロージング。料金は個別見積りである旨を伝え、次アクション(ヒアリング日程)を握る。');
}

pres.writeFile({ fileName: OUT }).then(() => console.log('written: ' + OUT));
