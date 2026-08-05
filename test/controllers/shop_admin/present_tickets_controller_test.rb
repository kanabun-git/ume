require "test_helper"

module ShopAdmin
  class PresentTicketsControllerTest < ActionDispatch::IntegrationTest
    test "a shop admin can create, update, and delete a present ticket" do
      shop = create_shop
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      post shop_admin_present_tickets_path, params: {
        present_ticket: { name: "テスト企画", capacity: 3, deadline_at: 1.day.from_now }
      }
      assert_redirected_to shop_admin_present_tickets_path
      ticket = shop.present_tickets.find_by(name: "テスト企画")
      assert ticket.present?

      patch shop_admin_present_ticket_path(ticket), params: { present_ticket: { name: "更新後企画" } }
      assert_equal "更新後企画", ticket.reload.name

      delete shop_admin_present_ticket_path(ticket)
      assert_not PresentTicket.exists?(ticket.id)
    end

    test "a shop admin cannot manage another shop's present ticket" do
      other_ticket = PresentTicket.create!(shop: create_shop, name: "他店企画", capacity: 1, deadline_at: 1.day.from_now)
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get shop_admin_present_ticket_path(other_ticket)

      assert_response :not_found
    end

    test "draw picks winners and moves the ticket to drawn" do
      shop = create_shop
      ticket = PresentTicket.create!(shop: shop, name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)
      3.times { ticket.present_ticket_entries.create!(member: create_member) }
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      post draw_shop_admin_present_ticket_path(ticket)

      assert_redirected_to shop_admin_present_ticket_path(ticket)
      assert_equal "drawn", ticket.reload.status
      assert_equal 1, ticket.present_ticket_entries.won.count
    end

    test "send_result_emails emails every un-notified won/lost entry and marks them notified" do
      shop = create_shop
      ticket = PresentTicket.create!(shop: shop, name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)
      3.times { ticket.present_ticket_entries.create!(member: create_member) }
      ticket.draw!
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      assert_emails 3 do
        post send_result_emails_shop_admin_present_ticket_path(ticket)
      end

      assert_redirected_to shop_admin_present_ticket_path(ticket)
      assert ticket.present_ticket_entries.all?(&:notified?)
    end

    test "send_result_emails does not re-email an already-notified entry" do
      shop = create_shop
      ticket = PresentTicket.create!(shop: shop, name: "テスト企画", capacity: 1, deadline_at: 1.day.from_now)
      ticket.present_ticket_entries.create!(member: create_member)
      ticket.draw!
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user
      post send_result_emails_shop_admin_present_ticket_path(ticket)

      assert_emails 0 do
        post send_result_emails_shop_admin_present_ticket_path(ticket)
      end
    end
  end
end
