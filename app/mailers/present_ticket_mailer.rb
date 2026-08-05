class PresentTicketMailer < ApplicationMailer
  # Sent manually by a shop admin, one batch at a time, after drawing a
  # PresentTicket lottery (see ShopAdmin::PresentTicketsController#send_result_emails)
  # — never queued automatically on draw, since the shop admin reviews the
  # winners before notifying anyone.
  def result_email(entry)
    @entry = entry
    @present_ticket = entry.present_ticket
    @member = entry.member

    subject = entry.won? ? "【当選】#{@present_ticket.name}" : "【落選】#{@present_ticket.name}"
    mail(to: @member.email, subject: subject)
  end
end
