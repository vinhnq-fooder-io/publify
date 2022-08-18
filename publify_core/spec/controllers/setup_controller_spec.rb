# frozen_string_literal: true

require "rails_helper"

RSpec.describe SetupController, type: :controller do
  describe "#index" do
    describe "when no blog is configured" do
      before do
        # Set up database similar to result of seeding
        @blog = Blog.create
        get "index"
      end

      specify { expect(response).to render_template("index") }
    end

    describe "when a blog is configured and has some users" do
      before do
        create(:blog)
        get "index"
      end

      specify { expect(response).to redirect_to(controller: "articles", action: "index") }
    end
  end

  describe "#create" do
    context "when no blog is configured" do
      before do
        # Set up database similar to result of seeding
        @blog = Blog.create
      end

      context "when passing correct parameters" do
        before do
          ActionMailer::Base.deliveries.clear
          post :create, params: { setting: { blog_name: "Foo", email: "foo@bar.net",
                                             password: "foo123bar" } }
        end

        it "correctly initializes blog and users" do
          expect(Blog.first.blog_name).to eq("Foo")
          admin = User.find_by(login: "admin")
          expect(admin).not_to be_nil
          expect(admin.email).to eq("foo@bar.net")
          expect(Article.first.user).to eq(admin)
          expect(Page.first.user).to eq(admin)
        end

        it "logs in admin user" do
          expect(controller.current_user).to eq(User.find_by(login: "admin"))
        end

        it "redirects to confirm the setup" do
          expect(response).to redirect_to(controller: "accounts",
                                          action: "confirm")
        end

        it "sends a confirmation email" do
          expect(ActionMailer::Base.deliveries.size).to eq 1
        end
      end

      describe "when passing incorrect parameters" do
        it "empty blog name should raise an error" do
          post :create, params: { setting: { blog_name: "", email: "foo@bar.net",
                                             password: "foobar123" } }
          expect(response).to redirect_to(action: "index")
        end

        it "empty email should raise an error" do
          post :create, params: { setting: { blog_name: "Foo", email: "",
                                             password: "foobar123" } }
          expect(response).to redirect_to(action: "index")
        end

        it "empty password should raise an error" do
          post :create, params: { setting: { blog_name: "Foo", email: "foo@bar.net",
                                             password: "" } }
          expect(response).to redirect_to(action: "index")
        end
      end
    end

    describe "when a blog is configured and has some users" do
      before do
        create(:blog)
        post :create, params: { setting: { blog_name: "Foo", email: "foo@bar.net" } }
      end

      specify { expect(response).to redirect_to(controller: "articles", action: "index") }

      it "does not initialize blog and users" do
        expect(Blog.first.blog_name).not_to eq("Foo")
        admin = User.find_by(login: "admin")
        expect(admin).to be_nil
      end
    end
  end
end
