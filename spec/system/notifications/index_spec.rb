require "rails_helper"

RSpec.describe "notifications/index", type: :system do
  let(:admin) { create(:casa_admin) }
  let(:volunteer) { build(:volunteer) }
  let(:case_contact) { create(:case_contact, creator: volunteer) }
  let(:casa_case) { case_contact.casa_case }

  before { casa_case.assigned_volunteers << volunteer }

  context "FollowupResolvedNotification" do
    let(:notification_message) { "#{volunteer.display_name} resolved a follow up. Click to see more." }
    let!(:followup) { create(:followup, creator: admin, case_contact: case_contact) }

    before do
      sign_in volunteer

      visit case_contacts_path
      click_button "Resolve"
    end

    it "lists my notifications" do
      sign_in admin
      visit notifications_path

      expect(page).to have_text(notification_message)
      expect(page).to have_text("Followup resolved")
      expect(page).not_to have_text(I18n.t(".notifications.index.no_notifications"))
    end

    context "when volunteer changes its name" do
      let(:created_by_name) { "Foo bar" }
      let(:new_notification_message) { I18n.t("notifications.followup_resolved_notification.message", created_by_name: created_by_name) }

      it "lists notifications showing it's current name" do
        visit edit_users_path
        fill_in "Display name", with: created_by_name
        click_on "Update Profile"
        expect(page).to have_content "Profile was successfully updated"

        sign_in admin
        visit notifications_path

        expect(page).to have_text(new_notification_message)
        expect(page).not_to have_text(notification_message)
        expect(page).not_to have_text(I18n.t(".notifications.index.no_notifications"))
      end
    end
  end

  context "FollowupNotification", js: true do
    let(:note) { "Lorem ipsum dolor sit amet." }

    let(:notification_message_heading) { "#{admin.display_name} has flagged a Case Contact that needs follow up." }
    let(:notification_message_more_info) { "Click to see more." }

    let(:inline_notification_message) { "#{notification_message_heading} #{notification_message_more_info}" }

    before do
      sign_in admin
      visit casa_case_path(casa_case)
    end

    context "when followup has a note" do
      before do
        click_button "Follow up"
        find(".swal2-textarea").set(note)

        click_button "Confirm"
      end

      it "lists followup notifications, showing their note" do
        # Wait until page reloads
        expect(page).to have_content "Resolve"

        sign_in volunteer
        visit notifications_path

        expect(page).to have_text(notification_message_heading)
        expect(page).to have_text(note)
        expect(page).to have_text(notification_message_more_info)
        expect(page).not_to have_text(I18n.t(".notifications.index.no_notifications"))
        expect(page).to have_text("New followup")
      end
    end

    context "when followup doesn't have a note" do
      before do
        click_button "Follow up"
        click_button "Confirm"
      end

      it "lists followup notifications, showing the information in a single line when there are no notes" do
        # Wait until page reloads
        expect(page).to have_content "Resolve"

        sign_in volunteer
        visit notifications_path

        expect(page).to have_text(inline_notification_message)
        expect(page).not_to have_text(I18n.t(".notifications.index.no_notifications"))
        expect(page).to have_text("New followup")
      end
    end

    context "when admin changes its name" do
      let(:created_by_name) { "Foo bar" }
      let(:new_notification_message) { I18n.t("notifications.followup_notification.message", created_by_name: created_by_name) }

      before do
        click_button "Follow up"
        click_button "Confirm"
      end

      it "lists followup notifications showing admin current name" do
        # Wait until page reloads
        expect(page).to have_content "Resolve"

        visit edit_users_path
        fill_in "Display name", with: created_by_name
        click_on "Update Profile"
        expect(page).to have_content "Profile was successfully updated"

        sign_in volunteer
        visit notifications_path

        expect(page).to have_text(new_notification_message)
        expect(page).not_to have_text(inline_notification_message)
        expect(page).not_to have_text(I18n.t(".notifications.index.no_notifications"))
        expect(page).to have_text("New followup")
      end
    end
  end

  context "when there are no notifications" do
    it "displays a message to the user" do
      sign_in volunteer
      visit notifications_path

      expect(page).to have_text(I18n.t(".notifications.index.no_notifications"))
    end
  end
end
