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
git clone https://github.com/kanabun-git/fuzoku_zero.git ume
cd ume
git checkout main   # 本番で動かすブランチ(運用に合わせて調整)

gem install bundler
bundle install --without development test
```

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

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ume-puma
sudo systemctl status ume-puma --no-pager
```

> **セキュリティメモ**: 上記はDBパスワードをファイルに平文で書く簡易な方法です。余裕があれば`/etc/ume/env`のような`chmod 600`の専用ファイルに分離し、`EnvironmentFile=/etc/ume/env`に置き換えることを推奨します(必須ではありません)。

---

## 7. nginx + SSL(Let's Encrypt)

`/etc/nginx/sites-available/ume`を作成します。

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
| アプリの最新化 | `cd /home/deploy/ume && git pull && bundle install && RAILS_ENV=production UME_DATABASE_PASSWORD='...' bin/rails db:migrate && RAILS_ENV=production bin/rails assets:precompile && sudo systemctl restart ume-puma` |
| アプリの再起動のみ | `sudo systemctl restart ume-puma` |
| ログ確認 | `sudo journalctl -u ume-puma -f` |
| メールログ確認 | `sudo tail -f /var/log/mail.log` |
| バックアップ一覧 | `cd /home/deploy/ume && RAILS_ENV=production UME_DATABASE_PASSWORD='...' bin/rails backup:list` |
