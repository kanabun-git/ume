require "test_helper"

module Admin
  class PresentTicketsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @shop = create_shop
      @admin = create_user(role: :platform_admin)
      sign_in @admin
    end

    test "a platform admin can create, update, and delete a shop's present ticket" do
      post admin_shop_present_tickets_path(@shop), params: {
        present_ticket: { name: "運営者企画", capacity: 3, deadline_at: 1.day.from_now }
      }
      assert_redirected_to admin_shop_present_tickets_path(@shop)
      ticket = @shop.present_tickets.find_by(name: "運営者企画")
      assert ticket.present?

      patch admin_shop_present_ticket_path(@shop, ticket), params: { present_ticket: { name: "更新後企画" } }
      assert_equal "更新後企画", ticket.reload.name

      delete admin_shop_present_ticket_path(@shop, ticket)
      assert_not PresentTicket.exists?(ticket.id)
    end

    test "draw picks winners and moves the ticket to drawn" do
      ticket = @shop.present_tickets.create!(name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)
      3.times { ticket.present_ticket_entries.create!(member: create_member) }

      post draw_admin_shop_present_ticket_path(@shop, ticket)

      assert_redirected_to admin_shop_present_ticket_path(@shop, ticket)
      assert_equal "drawn", ticket.reload.status
      assert_equal 1, ticket.present_ticket_entries.won.count
    end

    test "send_result_emails emails every un-notified won/lost entry" do
      ticket = @shop.present_tickets.create!(name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)
      3.times { ticket.present_ticket_entries.create!(member: create_member) }
      ticket.draw!

      assert_emails 3 do
        post send_result_emails_admin_shop_present_ticket_path(@shop, ticket)
      end

      assert ticket.present_ticket_entries.all?(&:notified?)
    end

    test "a shop admin cannot manage present tickets from the admin namespace" do
      shop_admin = create_user(role: :shop_admin, shop: @shop)
      sign_out @admin
      sign_in shop_admin

      get admin_shop_present_tickets_path(@shop)

      assert_redirected_to root_path
    end

    test "show hints that no banner is set yet, and renders one once set" do
      ticket = @shop.present_tickets.create!(name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)

      get admin_shop_present_ticket_path(@shop, ticket)
      assert_match "バナー画像は設定されていません", response.body

      ticket.update!(fallback_banner: :default_banner)

      get admin_shop_present_ticket_path(@shop, ticket)
      assert_select "img"
      assert_no_match "バナー画像は設定されていません", response.body
    end

    test "a platform admin can upload a banner image and choose the fallback display" do
      post admin_shop_present_tickets_path(@shop), params: {
        present_ticket: {
          name: "運営者企画", capacity: 3, deadline_at: 1.day.from_now,
          banner_image: upload_png, fallback_banner: "default_banner"
        }
      }

      ticket = @shop.present_tickets.find_by(name: "運営者企画")
      assert ticket.banner_image.attached?
      assert ticket.fallback_banner_default_banner?
    end

    test "a platform admin can remove a present ticket's banner image" do
      ticket = @shop.present_tickets.create!(name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)
      ticket.banner_image.attach(**png_upload)

      patch admin_shop_present_ticket_path(@shop, ticket), params: { present_ticket: { remove_banner_image: "1" } }

      assert_not ticket.reload.banner_image.attached?
    end

    private

    def upload_png
      bytes = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")
      Rack::Test::UploadedFile.new(StringIO.new(bytes), "image/png", original_filename: "banner.png")
    end
  end
end
