# VPS構築手順書

本番環境(https://fuzoku-zero.com)を一から作り直す場合に、同じ環境を再現するための手順書です。2026年8月時点で実際に稼働している構成を元にしています。

## 契約・サーバー情報

- **VPS事業者**: GMOクラウド byGMO(クラウドVPS **Vシリーズ**)
- **OS**: Ubuntu 24.04 LTS
- **IPアドレス**: 153.122.4.236
- **ドメイン**: fuzoku-zero.com(お名前.com等、ドメイン管理会社は別途確認)
- **重要**: GMOクラウドには「VSシリーズ」(末尾S)という別シリーズもあり、そちらはメール送信にリレーサーバーの設定が必須です。**Vシリーズはリレーサーバー不要・25番ポートで直接送信できる**仕様なので、混同しないよう注意してください(過去に誤ってVS向けの手順を適用し、メール送信ができなくなったことがあります)。

---

## 1. OSの初期設定

```bash
sudo apt update && sudo apt upgrade -y
sudo timedatectl set-timezone Asia/Tokyo
```

### 1-1. 作業用ユーザーの作成

rootで直接運用せず、`deploy`ユーザーを作成してsudo権限を与えます。

```bash
sudo adduser deploy
sudo usermod -aG sudo deploy
```

以降の作業は`deploy`ユーザーで行います。

### 1-2. ファイアウォール(ufw)

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 25/tcp
sudo ufw allow 993/tcp
sudo ufw enable
sudo ufw status verbose
```

| ポート | 用途 |
|---|---|
| 22 | SSH |
| 80 | HTTP(HTTPSへのリダイレクト用) |
| 443 | HTTPS(サイト本体) |
| 25 | SMTP(メール送信・受信) |
| 993 | IMAPS(メール受信、Dovecot経由でメールクライアントから閲覧する場合) |

### 1-3. SSHセッションのタイムアウト対策

何も操作しない時間が続くとSSH接続が切断されてしまう場合、原因はサーバー側(sshd)・手元のPC側・間にあるルーターやISPのいずれかのアイドルタイムアウトです。まとめて対策しておきます。

**サーバー側(VPS)**: `/etc/ssh/sshd_config`に以下を追加し、sshdを再起動します。

```bash
sudo nano /etc/ssh/sshd_config
```

```
ClientAliveInterval 60
ClientAliveCountMax 120
```

```bash
sudo systemctl restart sshd
```

60秒ごとに生存確認を送り、応答がなくても120回(=2時間)は切断しないようにする設定です。

**手元のPC側**: `~/.ssh/config`に以下を追加します(ルーター・ISP側のアイドルタイムアウトで切られるのを防ぎます)。

```
Host (接続に使っているホスト名やエイリアス)
  ServerAliveInterval 60
  ServerAliveCountMax 3
```

**`bin/deploy`など長時間かかる作業は`tmux`の中で実行する(最も確実)**: 上記の設定をしても、Wi-Fiの瞬断やPCのスリープなどで結局SSHが切れることはあります。`tmux`のセッション内で作業していれば、SSHが切れても処理自体は止まらず、再接続後に続きを確認できます。

```bash
tmux new -s deploy   # 新しいセッションを開始してこの中で作業する

# 切断されてしまったら、再度SSHログインしてから
tmux attach -t deploy   # 元のセッションに復帰(処理は継続している)
```

---

## 2. 必要パッケージのインストール

```bash
sudo apt install -y nginx postgresql postgresql-contrib postfix dovecot-imapd \
  certbot python3-certbot-nginx git curl build-essential \
  libssl-dev libreadline-dev zlib1g-dev libyaml-dev libpq-dev
```

Postfixのインストール中に設定ウィザードが出た場合は「インターネットサイト」を選び、システムメール名は`fuzoku-zero.com`を指定します。

---

## 3. PostgreSQLのセットアップ

```bash
sudo -u postgres createuser --createdb ume
sudo -u postgres psql -c "ALTER USER ume WITH PASSWORD '(強力なパスワードを設定)';"
sudo -u postgres createdb -O ume ume_production
```

- ロール名: `ume`(Create DB権限のみ、Superuserにはしない)
- データベース名: `ume_production`
- このパスワードは後述の`UME_DATABASE_PASSWORD`環境変数として使います。

---

## 4. Ruby(rbenv)のセットアップ

`deploy`ユーザーとして実行します。システム全体ではなく、ユーザーのホームディレクトリ(`~/.rbenv`)にインストールします。

```bash
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
cd ~/.rbenv && src/configure && make -C src
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

rbenv install 3.3.6   # リポジトリの .ruby-version と同じバージョンを指定
rbenv global 3.3.6
```

**バージョンの確認方法**: アプリのリポジトリ直下にある`.ruby-version`ファイルを見て、そこに書かれているバージョンをインストールしてください(現状は`3.3.6`ですが、更新されている場合があります)。

---

## 5. アプリケーションのデプロイ

```bash
cd /home/deploy
git clone https://github.com/kanabun-git/ume.git ume
cd ume
git checkout claude/email-management-page-wn9tm2   # 本番で動かすブランチ(運用に合わせて調整)

gem install bundler
# --without はBundler 4系でCLIフラグとして廃止されたため、config設定を使う
# (このアプリのディレクトリに記憶され、以後のbundle installにも引き継がれる)
bundle config set --local without 'development test'
bundle install
```

> **注意(2026年8月)**: 以前このドキュメントは `kanabun-git/fuzoku_zero.git` を
> クローン先として案内していましたが、そちらは開発の初期にコピーされたきり
> 更新されていない別リポジトリで、実際の開発は一貫して `kanabun-git/ume.git`
> 側で行われています。既に `fuzoku_zero.git` からデプロイ済みの環境は、
> 以下でリモートを付け替えてください(過去のコミット履歴は共有していないため
> `git fetch` だけでは追従できません)。
>
> ```bash
> cd /home/deploy/ume
> git remote set-url origin https://github.com/kanabun-git/ume.git
> git fetch origin
> git checkout claude/email-management-page-wn9tm2
> git reset --hard origin/claude/email-management-page-wn9tm2
> ```

### 5-1. マスターキーの配置(重要)

`config/master.key`は**gitには含まれていません**(意図的に`.gitignore`対象)。このファイルがないとRailsが暗号化された認証情報(`config/credentials.yml.enc`)を復号できず、アプリが起動しません。

安全な方法(1Password・パスワードマネージャー・直接SCPなど、**Slackやメールに平文で貼らない**)で`config/master.key`を取得し、以下に配置してください。

```bash
# 例: 手元のPCからVPSへ直接転送する場合
scp config/master.key deploy@153.122.4.236:/home/deploy/ume/config/master.key
```

```bash
chmod 600 /home/deploy/ume/config/master.key
```

### 5-2. データベースのセットアップ

```bash
cd /home/deploy/ume
RAILS_ENV=production UME_DATABASE_PASSWORD='(3で設定したパスワード)' bin/rails db:schema:load
```

(新規構築時は`db:schema:load`、既存バックアップから復元する場合は後述の「9. バックアップからの復元」を参照)

### 5-3. アセットのプリコンパイル

```bash
RAILS_ENV=production bin/rails assets:precompile
```

---

## 6. アプリ起動サービス(systemd)

`/etc/systemd/system/ume-puma.service`を作成します。

```ini
[Unit]
Description=Puma HTTP Server for ume
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/home/deploy/ume
Environment=RAILS_ENV=production
Environment=UME_DATABASE_PASSWORD=(3で設定したパスワード)
ExecStart=/home/deploy/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=always
RestartSec=5
StartLimitIntervalSec=300
StartLimitBurst=10

[Install]
WantedBy=multi-user.target
```

`StartLimitIntervalSec`/`StartLimitBurst`は、起動直後に毎回失敗するような壊れ方をしたとき(gem不足など)に無限リスタートし続けるのを防ぐための歯止めです。300秒間に10回失敗したら諦めて`failed`状態になり、`systemctl status`で一目で異常とわかるようになります(歯止めがないと、原因を直すまで5秒おきに再起動を繰り返し続け、気づくのが遅れます)。諦めた状態から復旧するときは、原因を直したあと`sudo systemctl reset-failed ume-puma && sudo systemctl start ume-puma`としてください。

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ume-puma
sudo systemctl status ume-puma --no-pager
```

> **セキュリティメモ**: 上記はDBパスワードをファイルに平文で書く簡易な方法です。余裕があれば`/etc/ume/env`のような`chmod 600`の専用ファイルに分離し、`EnvironmentFile=/etc/ume/env`に置き換えることを推奨します(必須ではありません)。

---

## 7. nginx + SSL(Let's Encrypt)

まず、アップロードサイズの上限を上げます(nginxの既定値は1MBしかなく、アプリ自体が許可している画像5MB・動画50MBのアップロードがそれより先に`413 Request Entity Too Large`で弾かれてしまうため)。`/etc/nginx/nginx.conf`の`http {}`ブロック内に追加してください。

```nginx
http {
    ...
    client_max_body_size 60m;
    ...
}
```

```bash
sudo nginx -t
sudo systemctl reload nginx
```

次に、`/etc/nginx/sites-available/ume`を作成します。

```nginx
server {
    listen 80;
    server_name fuzoku-zero.com www.fuzoku-zero.com;

    location /assets/ {
        root /home/deploy/ume/public;
        expires max;
        add_header Cache-Control public;
    }

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/ume /etc/nginx/sites-enabled/ume
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

DNS側で`fuzoku-zero.com`と`www.fuzoku-zero.com`のAレコードを153.122.4.236に向けてから、証明書を取得します。

```bash
sudo certbot --nginx -d fuzoku-zero.com -d www.fuzoku-zero.com
```

certbotが自動でnginx設定をHTTPS化し、`certbot.timer`による自動更新も有効になります(手動での作業は不要)。更新状況は以下で確認できます。

```bash
sudo certbot certificates
systemctl list-timers | grep certbot
```

---

## 7-1. キャストポータル用の別ドメイン設定(任意・推奨)

在籍キャストが出勤予定・日記の管理に使う「スタッフポータル」(`/cast`以下)は、サイト本体とは別の、業種を連想させない中立なドメインでのみアクセスできるようにできます。キャストが外出先や周囲に人がいる状況でスマホを開いた際、URLやブラウザタブから「風俗店のスタッフ管理画面である」と分からないようにするための機能です。

同じアプリ・同じデータベースをそのまま使うので、DB移行やAPI連携などの追加作業は不要です。以下の設定を追加するだけで有効になります。

1. **中立なドメインを別途取得する**(例: 事業内容を連想させない適当な単語のドメイン)。
2. DNS側でそのドメインのAレコードをこのVPSのIPに向ける(手順7と同様)。
3. `/etc/systemd/system/ume-puma.service`に環境変数を追加します。

   ```ini
   Environment=CAST_PORTAL_HOST=(取得した中立ドメイン。例: staff-xxxxx.example.com)
   ```

   設定後、`sudo systemctl daemon-reload && sudo systemctl restart ume-puma`。この環境変数が設定されると、`/cast`以下はこのドメインでしか開けなくなります(サイト本体のドメインで`/cast`にアクセスすると404になります)。

4. nginxに、そのドメイン用のserver blockを追加します(`server_name`だけが違う、手順7と同じ内容のブロックをもう1つ`/etc/nginx/sites-available/ume`に追記)。

   ```nginx
   server {
       listen 80;
       server_name (取得した中立ドメイン);

       location /assets/ {
           root /home/deploy/ume/public;
           expires max;
           add_header Cache-Control public;
       }

       location / {
           proxy_pass http://127.0.0.1:3000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

   ```bash
   sudo nginx -t
   sudo systemctl reload nginx
   sudo certbot --nginx -d (取得した中立ドメイン)
   ```

設定後は、このドメインの`/cast`からログインすると、サイト本体とは全く異なる配色・タイトル・アイコンの「スタッフポータル」画面が表示されます(ログイン画面も含めて中立デザインです)。キャストへのログインURL案内は、サイト本体のドメインではなく、この中立ドメインの方をお伝えください。

この設定を行わない場合(環境変数を設定しない場合)は、これまで通りサイト本体のドメインの`/cast`からもアクセスできます。

---

## 7-2. メールアドレス管理画面の別ドメイン設定(www.kanabun.tech)

運営している3サイト(`fuzoku-zero.com` / `kanabun.tech` / `puremint.jp`)のメールアドレスを管理する画面は、ポータルサイトとは切り離した独立した管理画面として **https://www.kanabun.tech/mailadmin** で提供します。

キャストポータル(7-1)と同じ仕組みで、同じアプリ・同じデータベースをそのまま使います。設定は以下だけです。

1. DNS側で`kanabun.tech`と`www.kanabun.tech`のAレコードをこのVPSのIPに向ける(手順7と同様)。
2. `/etc/systemd/system/ume-puma.service`に環境変数を追加します。

   ```ini
   Environment=MAIL_ADMIN_HOST=www.kanabun.tech
   Environment=MAIL_ADMIN_HTTP_AUTH_USER=(この画面専用のID。運営者アカウントとは別物)
   Environment=MAIL_ADMIN_HTTP_AUTH_PASSWORD=(この画面専用のパスワード。十分に長いランダム文字列を推奨)
   ```

   設定後、`sudo systemctl daemon-reload && sudo systemctl restart ume-puma`。`MAIL_ADMIN_HOST`を設定すると、

   - `/mailadmin`は**このドメインでしか開けなくなる**(`fuzoku-zero.com/mailadmin`は404)
   - 逆にこのドメインでは、`/mailadmin`(と静的アセット)**以外は何も配信されない**(ポータルサイトのトップページや`/admin`、Deviseの`/users`ログインルートにアクセスしても404)

   という双方向の切り離しが有効になります。

   `/mailadmin`はポータルサイトのログイン(Devise/運営者アカウント)とは無関係の、**この画面専用のBasic認証**で保護されます。ブラウザがID・パスワードを尋ねるネイティブなダイアログを出すだけで、ポータルサイトの名前・デザインが見えることは一切ありません。`MAIL_ADMIN_HTTP_AUTH_USER`/`PASSWORD`のどちらかが未設定のまま起動すると、`/mailadmin`は(誰にも見せずに)503を返します -- 設定漏れで無防備に公開されることはありません。

3. nginxに、このドメイン用のserver blockを追加します(`server_name`だけが違う、手順7と同じ内容のブロック)。

   ```nginx
   server {
       listen 80;
       server_name kanabun.tech www.kanabun.tech;

       location /assets/ {
           root /home/deploy/ume/public;
           expires max;
           add_header Cache-Control public;
       }

       location / {
           proxy_pass http://127.0.0.1:3000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

   ```bash
   sudo nginx -t
   sudo systemctl reload nginx
   sudo certbot --nginx -d kanabun.tech -d www.kanabun.tech
   ```

4. 管理する3ドメインのメールをこのサーバーで受け取るため、各ドメインのDNSに**MXレコード**をこのサーバー宛で設定します(例: `MX 10 mail.fuzoku-zero.com`)。SPFレコードも各ドメインに設定してください(8-1参照)。すでに他社のメールサービスでそのドメインのメールを受けている場合は、MXを切り替えると既存のメールが届かなくなるため、移行の可否を必ず先に確認してください。

5. メールボックスを実際に作成・削除できるようにするサーバー側の設定は「8-4. メールアドレス管理画面の連携」を参照してください。

この設定を行わない場合(環境変数を設定しない場合)は、`/mailadmin`はどのドメインからでも開けます(開発環境と同じ挙動)。

---

## 7-3. 運営会社コーポレートサイトの別ドメイン設定(www.puremint.jp)

運営会社(有限会社ピュアミント)の紹介サイト(会社概要・事業内容・アクセス・お問い合わせ)は、ポータルサイトとは切り離した独立したサイトとして **https://www.puremint.jp/** (トップページそのもの)で提供します。

7-1/7-2と同じ仕組みで、同じアプリ・同じデータベースをそのまま使います。設定は以下だけです。

1. DNS側で`puremint.jp`と`www.puremint.jp`のAレコードをこのVPSのIPに向ける(手順7と同様)。
2. `/etc/systemd/system/ume-puma.service`に環境変数を追加します。

   ```ini
   Environment=PUREMINT_HOST=www.puremint.jp
   ```

   設定後、`sudo systemctl daemon-reload && sudo systemctl restart ume-puma`。`PUREMINT_HOST`を設定すると、

   - コーポレートサイトの各ページは**このドメインでしか開けなくなり**、かつURLの接頭辞なし(`/`が会社紹介トップ、`/company`が会社概要 …)で提供されます(`fuzoku-zero.com`側では引き続き`/corporate`配下でしか開けません)
   - 逆にこのドメインでは、コーポレートサイトの各ページ(と静的アセット)**以外は何も配信されない**(ポータルサイトのトップページや`/admin`、Deviseの`/users`ログインルートにアクセスしても404)

   という双方向の切り離しが有効になります。

3. nginxに、このドメイン用のserver blockを追加します(`server_name`だけが違う、手順7と同じ内容のブロック)。

   ```nginx
   server {
       listen 80;
       server_name puremint.jp www.puremint.jp;

       location /assets/ {
           root /home/deploy/ume/public;
           expires max;
           add_header Cache-Control public;
       }

       location / {
           proxy_pass http://127.0.0.1:3000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

   ```bash
   sudo nginx -t
   sudo systemctl reload nginx
   sudo certbot --nginx -d puremint.jp -d www.puremint.jp
   ```

4. 会社概要ページの住所・代表者名・資本金などは`app/models/corporate/company.rb`にプレースホルダーとして定義されています。公開前に実際の登記情報へ差し替えてリポジトリにコミットし、`bin/deploy`で反映してください。

この設定を行わない場合(環境変数を設定しない場合)は、`/corporate`はどのドメインからでも開けます(開発環境と同じ挙動)。

---

## 7-4. 古着ブランド判定ツールの公開(www.kanabun.tech/vintage)

古着のタグの写真からブランド・製造年代・中古相場の目安を推定するツールを、**https://www.kanabun.tech/vintage** で試験公開します。

`www.kanabun.tech`のDNS・nginx・証明書は**7-2でメールアドレス管理画面のために設定済み**なので、この手順で新しく用意するのは環境変数だけです(nginxの変更もDNSの変更も不要)。

1. `/etc/systemd/system/ume-puma.service`に環境変数を追加します。

   ```ini
   Environment=VINTAGE_HOST=www.kanabun.tech
   Environment=ANTHROPIC_API_KEY=(Anthropicのコンソールで発行したAPIキー)
   ```

   `ANTHROPIC_API_KEY`はキャストの写メ日記のAI下書きと**同じ環境変数**です。すでに設定済みならそのまま使われます。未設定でもフォームと年代判定ガイドは開けますが、判定を実行するとその旨のエラーが表示されます。

2. 反映します。

   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart ume-puma
   ```

3. 動作確認します。

   ```bash
   curl -I https://www.kanabun.tech/vintage        # 200
   curl -I https://fuzoku-zero.com/vintage         # 404(ポータル側には出さない)
   ```

`VINTAGE_HOST`を設定すると、判定ツールは**このドメインでしか開けなくなります**(風俗ポータルのドメインに一般向けのツールが並ばないようにするため)。`www.kanabun.tech`は7-2で「`/mailadmin`以外は何も配信しない」ドメインにしてありますが、`VINTAGE_HOST`が同じホストに設定されている場合に限り`/vintage`だけが例外として通ります(`app/middleware/mail_admin_host_middleware.rb`)。ポータルのトップページや`/admin`が`www.kanabun.tech`で開くようになるわけではありません。

告知に使うURLは**www付き**の`https://www.kanabun.tech/vintage`です。`VINTAGE_HOST`に指定したホスト名と完全に一致するホストでしか開かないため、wwwなしの`kanabun.tech/vintage`は404になります(wwwなしでも開きたい場合は、nginx側でwwwへ301リダイレクトするのが簡単です)。

同じドメインで公開している「やどかりペンションHP」(`/pension_basic/`)はnginxが配信している別物なので、この設定の影響を受けません。

**運用上の注意**

* 判定1回ごとにAnthropicのAPI利用料が発生します。1つのIPからの連続実行(10秒のクールダウン)と1時間あたりの回数(20回)を制限していますが、試験公開の間はAnthropicのコンソールで利用量に上限を設定しておくことを勧めます。制限値は`app/models/vintage/identification.rb`の`COOLDOWN`/`WINDOW_LIMIT`です。
* アップロードされた写真はサーバーに保存されず、判定のためにAPIへ渡されるだけです。
* 表示される中古相場はAIの推定です。買取価格の保証ではない旨を画面にも明記していますが、試験公開の告知でも同様に伝えてください。
* コーポレートサイト(puremint.jp)の事業内容ページからは、`VINTAGE_HOST`を設定すると自動的に`https://www.kanabun.tech/vintage`への絶対URLでリンクされます(`app/models/corporate/company.rb`の`VINTAGE_TOOL_URL`)。

この設定を行わない場合(環境変数を設定しない場合)は、`/vintage`はどのドメインからでも開けます(開発環境と同じ挙動)。

---

## 8. メール送信(Postfix)の設定

**Vシリーズはリレーサーバー不要・直接送信可能**です。追加の設定なしで動くはずですが、以下だけ確認してください。

```bash
sudo cat /etc/postfix/main.cf
```

- `relayhost` の行が**存在しない**こと(存在すると外部リレーを経由しようとして失敗します)
- `mydestination` に `fuzoku-zero.com` が含まれていること(このドメイン宛のメールをサーバー自身で受け取る設定)
- `mynetworks` が `127.0.0.0/8` 等ローカルのみになっていること(第三者に踏み台にされるオープンリレーを防ぐため)

### 8-1. SPFレコード(DNS)

ドメインの管理画面で、以下のTXTレコードを設定してください(**VSシリーズ向けのリレーサーバーを指定するSPFではなく**、このサーバー自身のIPを直接許可する内容にすること)。

```
v=spf1 ip4:153.122.4.236 ~all
```

### 8-2. 受信メールの確認(IMAP)

Dovecotが動いており、`@fuzoku-zero.com`宛のメールはサーバー内のUnixメールボックスに配達されます。メールクライアント(Thunderbird等)からIMAPS(993番ポート)で接続すれば読めます。

### 8-3. 送受信テスト

```bash
# 直接25番ポートで外部に出られるか確認
nc -zv -w5 aspmx.l.google.com 25

# サイトの「パスワードを忘れた場合」から自分宛にテストメールを送信後
sudo tail -30 /var/log/mail.log
```

### 8-4. メールアドレス管理画面の連携(任意)

メールアドレス管理画面(`/mailadmin`、下記7-2)では、運営している複数のサイト(ドメイン)ごとにメールアドレスを追加・削除し、そのアドレスからテストメールを送れます。**この設定を行わない場合、画面での登録は管理画面上の記録にとどまり、サーバー上のメールボックスは作られません**(その旨が画面に表示されます)。

以下を設定すると、画面での追加・削除がそのままPostfix/Dovecotに反映されるようになります。

#### 仕組み

Railsアプリはroot権限を一切持ちません。代わりに、

1. アプリ(`deploy`ユーザー)が、登録内容の全体像を `/var/lib/ume-mail/` 以下の2つのテキストファイルに書き出す
2. root所有の `/usr/local/sbin/ume-mailboxctl` を **引数なしで** `sudo` 実行し、そのスクリプトがファイルを読んでPostfix/Dovecotの設定を作り直す

という2段構成になっています。管理画面に入力された文字列がroot権限のコマンドラインに渡ることはなく、スクリプト側でも書式に合わない行が1つでもあれば何も変更せずに終了します。

#### 手順

```bash
# 1. 仮想メールボックス用のユーザーと置き場所
sudo useradd -r -u 5000 -d /var/mail/vhosts -s /usr/sbin/nologin vmail
sudo mkdir -p /var/mail/vhosts /var/mail/vhosts-removed
sudo chown -R vmail:vmail /var/mail/vhosts /var/mail/vhosts-removed

# 2. アプリが書き出す受け渡しディレクトリ(deployユーザーが書き込めること)
sudo mkdir -p /var/lib/ume-mail
sudo chown deploy:deploy /var/lib/ume-mail
sudo chmod 750 /var/lib/ume-mail

# 3. 反映スクリプトを設置(リポジトリ同梱、root所有・他ユーザーは書き込み不可にする)
sudo install -o root -g root -m 0755 /home/deploy/ume/script/ume-mailboxctl /usr/local/sbin/ume-mailboxctl

# 4. このスクリプトだけ、引数なしでのsudo実行を許可する
echo 'deploy ALL=(root) NOPASSWD: /usr/local/sbin/ume-mailboxctl ""' | sudo tee /etc/sudoers.d/ume-mailboxctl
sudo chmod 440 /etc/sudoers.d/ume-mailboxctl
sudo visudo -c
```

Postfixに仮想メールボックスの設定を追加します。

```bash
sudo postconf -e 'virtual_mailbox_domains = hash:/etc/postfix/virtual_mailbox_domains'
sudo postconf -e 'virtual_mailbox_maps = hash:/etc/postfix/vmailbox'
sudo postconf -e 'virtual_mailbox_base = /var/mail/vhosts'
sudo postconf -e 'virtual_uid_maps = static:5000'
sudo postconf -e 'virtual_gid_maps = static:5000'
```

> **注意**: 同じドメインを `mydestination`(サーバー自身のUnixメールボックスで受け取る設定)と `virtual_mailbox_domains` の両方に書くことはできません。`fuzoku-zero.com` をこの画面で管理する場合は、`sudo postconf -e 'mydestination = localhost'` のように `mydestination` から外してください(既存の`/var/mail/`配下のメールは残りますが、以後の配送先は`/var/mail/vhosts/`に変わります)。

Dovecotで、このパスワードファイルを使って認証するようにします。

```bash
# /etc/dovecot/conf.d/10-auth.conf
passdb {
  driver = passwd-file
  args = scheme=CRYPT username_format=%u /etc/dovecot/users
}
userdb {
  driver = passwd-file
  args = username_format=%u /etc/dovecot/users
}
```

メールソフト(Thunderbird等)から送信できるようにするため、submission(587番ポート)を有効にします。

```bash
# /etc/postfix/master.cf の submission 行のコメントアウトを外す
sudo postconf -M submission/inet="submission inet n - y - - smtpd"
sudo postconf -P submission/inet/smtpd_tls_security_level=encrypt
sudo postconf -P submission/inet/smtpd_sasl_auth_enable=yes
sudo postconf -P submission/inet/smtpd_recipient_restrictions='permit_sasl_authenticated,reject'
sudo systemctl restart postfix
sudo ufw allow 587/tcp
```

SASL認証はDovecot側に任せます(上で設定した`/etc/dovecot/users`のアカウントでそのまま送信できます)。

```bash
sudo postconf -e 'smtpd_sasl_type = dovecot'
sudo postconf -e 'smtpd_sasl_path = private/auth'
```

```
# /etc/dovecot/conf.d/10-master.conf
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
```

最後に、アプリ側に反映コマンドの場所と、パスワード表示用の暗号化鍵を教えます。

```bash
# 暗号化鍵を1つ生成する(この値は再発行するとパスワード表示ができなくなるので、
# パスワードマネージャー等に控えておくこと)
openssl rand -hex 32
```

```ini
# /etc/systemd/system/ume-puma.service の [Service] に追加
Environment=UME_MAILBOXCTL=/usr/local/sbin/ume-mailboxctl
Environment=UME_ENCRYPTION_PRIMARY_KEY=(上で生成した値)
```

`UME_ENCRYPTION_PRIMARY_KEY` は、管理画面でメールアドレスのパスワードを後から確認できるようにするためのものです(パスワードはこの鍵で暗号化して保存されるため、データベースのダンプやバックアップだけが漏れても平文は読めません)。**未設定でもメールアドレスの追加・削除・送信テストは動きます**が、パスワードの確認だけができなくなります。

```bash
sudo systemctl daemon-reload && sudo systemctl restart ume-puma
```

設定後、`/mailadmin`で「メールサーバーへ再反映する」を押すと、現在の登録内容がサーバーに反映されます。一覧の各アドレスが「反映済」になっていれば成功です。

#### 運用上のメモ

- 画面でメールアドレスを削除すると、そのメールボックスは即削除ではなく `/var/mail/vhosts-removed/(日時)/` に退避されます。誤削除に気付いた場合はここから戻せます(不要になったら手動で削除してください)。
- パスワードは2つの形で保存されます。認証に使うSHA-512 cryptハッシュ(復元不可)と、管理画面での確認用に`UME_ENCRYPTION_PRIMARY_KEY`で暗号化したもの。DBのバックアップに平文は含まれません。
- メールソフトの設定値(サーバー名・ポート・パスワード)は、管理画面の各アドレスの「メールソフトの設定とパスワードを表示」から確認できます。受信はIMAPS(993番)、送信はsubmission(587番/STARTTLS)、ユーザー名はメールアドレス全体(`info@example.com`)です。
- 証明書のホスト名と、メールソフトに設定するサーバー名は一致させてください。Let's Encryptの証明書を`mail.example.com`で取得している場合は、管理画面の「サイト情報を編集」→「メールサーバーのホスト名」にそのホスト名を入れておくと、画面の案内もそれに合わせて表示されます。
- 反映に失敗した場合は、画面上部に理由が表示されます。詳しいログは `sudo journalctl -u ume-puma` と `sudo tail -50 /var/log/mail.log` を確認してください。
- 「送受信テスト」は、アプリ自身がそのアドレスからそのアドレス宛にメールを送り、IMAPでログインして実際に届いたかまで確認します。`UME_ENCRYPTION_PRIMARY_KEY`が未設定(パスワードを確認できない)アドレスでは実行できません。また、アプリサーバーが自分自身の公開ホスト名(`mail_host`)の993番ポートに接続できる必要があります -- 一部のVPS/クラウド環境では、サーバーが自分の公開IPに外向きに接続できない(hairpin NAT非対応)ことがあり、その場合は送信は成功するのに受信確認だけ失敗します。その場合は`ufw`や外向き接続の制限を確認してください。

---

## 9. 自動バックアップ

アプリに`bin/rails backup:create`というバックアップコマンドが用意されています(DB全体+添付ファイルを`backups/`以下に保存、7日分保持)。**このコマンドを動かすだけでは自動実行されないため、systemdタイマーの設定が必須です**(2026年8月に、この設定漏れで一度もバックアップが実行されていなかった実績があるため、構築時は必ず設定してください)。

```bash
sudo tee /etc/systemd/system/ume-backup.service > /dev/null << 'EOF'
[Unit]
Description=Daily backup for ume
After=network.target postgresql.service

[Service]
Type=oneshot
User=deploy
WorkingDirectory=/home/deploy/ume
Environment=RAILS_ENV=production
Environment=UME_DATABASE_PASSWORD=(3で設定したパスワード)
ExecStart=/home/deploy/.rbenv/shims/bundle exec rails backup:create
EOF

sudo tee /etc/systemd/system/ume-backup.timer > /dev/null << 'EOF'
[Unit]
Description=Run ume-backup daily

[Timer]
OnCalendar=*-*-* 05:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now ume-backup.timer
```

設定後、必ず一度手動実行して動作確認してください。

```bash
sudo systemctl start ume-backup.service
sudo systemctl status ume-backup.service --no-pager
ls -la /home/deploy/ume/backups/
```

日付名のフォルダが新しく作成されていれば成功です。

### 9-1. バックアップからの復元(サーバー障害時など)

```bash
cd /home/deploy/ume
RAILS_ENV=production UME_DATABASE_PASSWORD='(パスワード)' bin/rails backup:list
RAILS_ENV=production UME_DATABASE_PASSWORD='(パスワード)' bin/rails backup:restore BACKUP_DIR=(表示された名前) CONFIRM=yes
```

**破壊的な操作(現在のDB・添付ファイルを上書き)なので、本当に必要な時以外は実行しないこと。**

### 9-2. お気に入り更新・プレゼント企画リマインドメール

`bin/rails notifications:send_daily`は、お気に入り登録している女の子の新着日記・本日の出勤予定と、お気に入り店舗のプレゼント企画の締切間近リマインドを、対象の個人会員へメール送信するコマンドです。バックアップと同様、**systemdタイマーを設定しないと自動実行されません。**

```bash
sudo tee /etc/systemd/system/ume-notifications.service > /dev/null << 'EOF'
[Unit]
Description=Daily favorite/present-ticket notification emails for ume
After=network.target postgresql.service

[Service]
Type=oneshot
User=deploy
WorkingDirectory=/home/deploy/ume
Environment=RAILS_ENV=production
Environment=UME_DATABASE_PASSWORD=(3で設定したパスワード)
ExecStart=/home/deploy/.rbenv/shims/bundle exec rails notifications:send_daily
EOF

sudo tee /etc/systemd/system/ume-notifications.timer > /dev/null << 'EOF'
[Unit]
Description=Run ume-notifications daily

[Timer]
OnCalendar=*-*-* 09:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now ume-notifications.timer
```

設定後、必ず一度手動実行して動作確認してください。

```bash
sudo systemctl start ume-notifications.service
sudo systemctl status ume-notifications.service --no-pager
```

---

## 10. OS・ミドルウェアの更新

セキュリティのため、定期的に(月1回程度を目安に)以下を実施してください。

```bash
sudo apt update && apt list --upgradable
sudo apt upgrade -y
# カーネル更新が含まれる場合は再起動が必要
sudo reboot
```

再起動後は、以下のサービスが正常に立ち上がっているか確認してください。

```bash
systemctl status ume-puma nginx postgresql postfix dovecot --no-pager
```

---

## 11. 動作確認チェックリスト(構築完了後)

- [ ] `https://fuzoku-zero.com/` がブラウザで表示される
- [ ] `sudo systemctl status ume-puma` が `active (running)`
- [ ] `/users/sign_in` からログインできる
- [ ] 管理画面(`/admin`)・店舗管理画面(`/shop_admin`)・キャストマイページ(`/cast`)にそれぞれログインできる
- [ ] パスワードリセットメールが実際に届く(8-3のテスト)
- [ ] `ls /home/deploy/ume/backups/` に当日日付のバックアップができている
- [ ] SSL証明書が有効(ブラウザで鍵マークが表示される)

---

## 12. よく使う運用コマンド一覧

| 目的 | コマンド |
|---|---|
| アプリの最新化 | `cd /home/deploy/ume && UME_DATABASE_PASSWORD='...' bin/deploy`(`git pull`・`bundle install`・マイグレーション・アセットプリコンパイル・再起動を1コマンドで実行。`git pull`だけで済ませて`bundle install`を忘れると、Gemfile.lockとvendor/bundleがずれてPumaがBundler::GemNotFoundで再起動ループに陥るので、必ずこちらを使うこと) |
| アプリの再起動のみ | `sudo systemctl restart ume-puma` |
| ログ確認 | `sudo journalctl -u ume-puma -f` |
| メールログ確認 | `sudo tail -f /var/log/mail.log` |
| バックアップ一覧 | `cd /home/deploy/ume && RAILS_ENV=production UME_DATABASE_PASSWORD='...' bin/rails backup:list` |

> **注意**: `/home/deploy/ume`で`git clean`は実行しないでください。`vendor/bundle`(インストール済みgemの実体)はGit管理外のディレクトリで、`git clean -fd`のような「作業ツリーを綺麗にする」操作で丸ごと消えてしまいます。消えた場合の復旧は`bin/deploy`(または`bundle install`)の再実行で直ります。

---

## 12-1. 502 Bad Gateway が出たとき

`502 Bad Gateway / nginx` は、**nginxがPuma(アプリ本体)に繋げなかった**ときの表示です。nginx自体は動いているので、原因は必ずPuma側にあります。3サイト(fuzoku-zero.com / kanabun.tech / puremint.jp)すべてが同時に502になるのが特徴です。

まず現在Pumaが生きているかを確認します。

```bash
curl -I http://127.0.0.1:3000/up                                # 301 が返れば応答している
curl -I -H "X-Forwarded-Proto: https" http://127.0.0.1:3000/up  # 200 ならDB接続まで正常
sudo systemctl status ume-puma --no-pager -l
sudo journalctl -u ume-puma -n 100 --no-pager
```

1つ目が`301 Moved Permanently`(`location: https://...`)になるのは**正常**です。productionは`force_ssl`が有効なので、http のリクエストはhttpsへリダイレクトされます。**リダイレクトが返ってきている時点でPumaは生きています**。nginx経由と同じ扱いにするヘッダを付けた2つ目が200なら、データベース接続まで含めて正常です(メンテナンスモードの判定でDBを1回引くため、DBが落ちていればここで500になります)。`Connection refused`や無応答ならPumaが落ちています。

**`systemctl restart`の直後、10〜15秒ほど502になるのは正常です**(Pumaが起動しきるまでの間。`journalctl`で`Stopping ...`から`* Listening on http://[::]:3000`までの時間がその窓です)。リロードして直るならこれで、原因を追う必要はありません。

数十秒以上続く場合、よくある原因は次の3つです。いずれも`journalctl`の最後の数十行に理由が出ます。

| 症状(ログに出るもの) | 原因 | 対処 |
|---|---|---|
| `Bundler::GemNotFound` で再起動を繰り返す | `git pull`だけして`bundle install`を忘れた | `UME_DATABASE_PASSWORD='...' bin/deploy`を実行(12の表を参照) |
| `Unknown key name` / `Failed to parse` / そもそも起動しない | `/etc/systemd/system/ume-puma.service`の編集ミス。`Environment=`の行は必ず`[Service]`セクションの中に、`=`の前後に空白を入れずに書く | `sudo systemd-analyze verify /etc/systemd/system/ume-puma.service`で構文を確認し、直したら`sudo systemctl daemon-reload && sudo systemctl restart ume-puma` |
| `SECRET_KEY_BASE`や`UME_DATABASE_PASSWORD`が無い旨のエラー | unitファイルを編集した際に既存の`Environment=`行を消してしまった | `sudo systemctl show ume-puma -p Environment`で今読み込まれている変数を確認し、不足分を書き戻す |

環境変数を足すときは、**既存の行を消していないか**を`systemctl show`で必ず確認してください(このファイルにはDBのパスワードや暗号化キーが入っており、1行消えるだけでPumaは起動しなくなります)。

なお、`https://fuzoku-zero.com/`が**503**でメンテナンス画面が出る場合は障害ではありません。運営管理画面(`/admin`)で切り替えるメンテナンスモードが有効になっているだけで、Pumaは正常に動いています。
