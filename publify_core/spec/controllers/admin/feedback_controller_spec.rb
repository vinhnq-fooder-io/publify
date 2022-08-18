# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::FeedbackController, type: :controller do
  render_views

  let(:feedback_from_own_article) { create(:comment, article: article) }
  let(:feedback_from_not_own_article) { create(:spam_comment) }

  shared_examples_for "destroy feedback with feedback from own article" do
    it "destroys feedback" do
      id = feedback_from_own_article.id
      expect do
        delete "destroy", params: { id: id }
      end.to change(Feedback, :count)
      expect do
        Feedback.find(feedback_from_own_article.id)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "redirects to feedback from article" do
      delete "destroy", params: { id: feedback_from_own_article.id }
      expect(response).to redirect_to(controller: "admin/feedback", action: "article",
                                      id: feedback_from_own_article.article.id)
    end
  end

  describe "logged in admin user" do
    let(:admin) { create(:user, :as_admin) }
    let(:article) { create(:article, user: admin) }

    before do
      create(:blog)
      sign_in admin
    end

    describe "destroy action" do
      it_behaves_like "destroy feedback with feedback from own article"

      it "destroys feedback from article doesn't own" do
        id = feedback_from_not_own_article.id
        expect do
          delete "destroy", params: { id: id }
        end.to change(Feedback, :count)
        expect do
          Feedback.find(feedback_from_not_own_article.id)
        end.to raise_error(ActiveRecord::RecordNotFound)
        expect(response).to redirect_to(controller: "admin/feedback", action: "article",
                                        id: feedback_from_not_own_article.article.id)
      end
    end

    describe "index security" do
      it "checks domain of the only param" do
        expect { get :index, params: { only: "evil_call" } }.not_to raise_error
        expect(assigns(:only_param)).to be_nil
      end
    end

    describe "#index" do
      let!(:spam) { create(:spam_comment) }
      let!(:unapproved) { create(:unconfirmed_comment) }
      let!(:presumed_ham) { create(:presumed_ham_comment) }
      let!(:presumed_spam) { create(:presumed_spam_comment) }
      let(:params) { {} }

      before { get :index, params: params }

      it { expect(response).to be_successful }
      it { expect(response).to render_template("index") }

      context "simple" do
        it { expect(assigns(:feedback).size).to eq(4) }
      end

      context "unapproved" do
        let(:params) { { only: "unapproved" } }

        it {
          expect(assigns(:feedback)).to match_array([unapproved, presumed_ham,
                                                     presumed_spam])
        }
      end

      context "spam" do
        let(:params) { { only: "spam" } }

        it { expect(assigns(:feedback)).to eq([spam]) }
      end

      context "presumed_spam" do
        let(:params) { { only: "presumed_spam" } }

        it { expect(assigns(:feedback)).to eq([presumed_spam]) }
      end

      context "presumed_ham" do
        let(:params) { { only: "presumed_ham" } }

        it { expect(assigns(:feedback)).to match_array([unapproved, presumed_ham]) }
      end

      context "with an empty page params" do
        let(:params) { { page: "" } }

        it { expect(assigns(:feedback).size).to eq(4) }
      end
    end

    describe "#article" do
      # render_template
      let(:article) { create(:article) }
      let!(:ham) { create(:comment, article: article) }
      let!(:spam) { create(:comment, article: article, state: "spam") }

      it "sees all feedback on one article" do
        get :article, params: { id: article.id }
        aggregate_failures do
          expect(response).to be_successful
          expect(response).to render_template("article")
          expect(assigns(:article)).to eq(article)
          expect(assigns(:feedback)).to match_array [ham, spam]
        end
      end

      it "includes hidden article id field in bulkops form" do
        get :article, params: { id: article.id }
        expect(response.body).
          to have_css("form[action='/admin/feedback/bulkops'] input[name=article_id]",
                      visible: :hidden)
      end

      it "sees only spam feedback on one article" do
        get :article, params: { id: article.id, spam: "y" }
        aggregate_failures do
          expect(response).to be_successful
          expect(response).to render_template("article")
          expect(assigns(:article)).to eq(article)
          expect(assigns(:feedback)).to match_array [spam]
        end
      end

      it "sees only ham feedback on one article" do
        get :article, params: { id: article.id, ham: "y" }
        aggregate_failures do
          expect(response).to be_successful
          expect(response).to render_template("article")
          expect(assigns(:article)).to eq(article)
          expect(assigns(:feedback)).to match_array [ham]
        end
      end

      it "renders error if bad article id" do
        expect do
          get :article, params: { id: 102_302 }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe "#create" do
      def base_comment(options = {})
        { "body" => "a new comment", "author" => "Me", "url" => "https://bar.com/",
          "email" => "foo@bar.com" }.merge(options)
      end

      describe "by get access" do
        it "raises ActiveRecordNotFound if article doesn't exist" do
          expect do
            get "create", params: { article_id: 120_431, comment: base_comment }
          end.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "does not create comment" do
          article = create(:article)
          expect do
            get "create", params: { article_id: article.id, comment: base_comment }
            expect(response).to redirect_to(action: "article", id: article.id)
          end.not_to change(Comment, :count)
        end
      end

      describe "by post access" do
        it "raises ActiveRecord::RecordNotFound if article doesn't exist" do
          expect do
            post "create", params: { article_id: 123_104, comment: base_comment }
          end.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "creates comment" do
          article = create(:article)
          expect do
            post "create", params: { article_id: article.id, comment: base_comment }
            expect(response).to redirect_to(action: "article", id: article.id)
          end.to change(Comment, :count)
        end

        it "creates comment mark as ham" do
          article = create(:article)
          expect do
            post "create", params: { article_id: article.id, comment: base_comment }
            expect(response).to redirect_to(action: "article", id: article.id)
          end.to change { Comment.ham.count }
        end
      end
    end

    describe "#edit" do
      it "renders edit form" do
        article = create(:article)
        comment = create(:comment, article: article)
        get "edit", params: { id: comment.id }
        expect(assigns(:comment)).to eq(comment)
        expect(assigns(:article)).to eq(article)
        expect(response).to be_successful
        expect(response).to render_template("edit")
      end
    end

    describe "#update" do
      it "updates comment if post request" do
        article = create(:article)
        comment = create(:comment, article: article)
        post "update", params: { id: comment.id,
                                 comment: { author: "Bob Foo2",
                                            url: "http://fakeurl.com",
                                            body: "updated comment" } }
        expect(response).to redirect_to(action: "article", id: article.id)
        comment.reload
        expect(comment.body).to eq("updated comment")
      end

      it "does not update comment if get request" do
        comment = create(:comment)
        get "update", params: { id: comment.id,
                                comment: { author: "Bob Foo2",
                                           url: "http://fakeurl.com",
                                           body: "updated comment" } }
        expect(response).to redirect_to(action: "edit", id: comment.id)
        comment.reload
        expect(comment.body).not_to eq("updated comment")
      end
    end
  end

  describe "publisher access" do
    let(:publisher) { create(:user, :as_publisher) }
    let(:article) { create(:article, user: publisher) }

    before do
      create(:blog)
      sign_in publisher
    end

    describe "#destroy" do
      it_behaves_like "destroy feedback with feedback from own article"

      it "does not destroy feedback doesn't own" do
        id = feedback_from_not_own_article.id
        post "destroy", params: { id: id }
        expect(response).to redirect_to(controller: "admin/feedback", action: "index")
        expect do
          Feedback.find(id)
        end.not_to raise_error
      end
    end

    describe "#edit" do
      it "does not edit comment no own article" do
        get "edit", params: { id: feedback_from_not_own_article.id }
        expect(response).to redirect_to(action: "index")
      end

      it "edits comment if own article" do
        get "edit", params: { id: feedback_from_own_article.id }
        expect(response).to be_successful
        expect(response).to render_template("edit")
        expect(assigns(:comment)).to eq(feedback_from_own_article)
        expect(assigns(:article)).to eq(feedback_from_own_article.article)
      end
    end

    describe "#update" do
      it "updates comment if own article" do
        post "update", params: { id: feedback_from_own_article.id,
                                 comment: { author: "Bob Foo2",
                                            url: "http://fakeurl.com",
                                            body: "updated comment" } }
        expect(response).to redirect_to(action: "article",
                                        id: feedback_from_own_article.article.id)
        feedback_from_own_article.reload
        expect(feedback_from_own_article.body).to eq("updated comment")
      end

      it "does not update comment if not own article" do
        post "update", params: { id: feedback_from_not_own_article.id,
                                 comment: { author: "Bob Foo2",
                                            url: "http://fakeurl.com",
                                            body: "updated comment" } }
        expect(response).to redirect_to(action: "index")
        feedback_from_not_own_article.reload
        expect(feedback_from_not_own_article.body).not_to eq("updated comment")
      end
    end

    describe "#bulkops action" do
      it "redirects to index" do
        post :bulkops, params: { bulkop_top: "destroy all spam" }
        expect(@response).to redirect_to(action: "index")
      end

      it "redirects to article when id is given" do
        post :bulkops, params: { article_id: article.id, bulkop_top: "destroy all spam" }
        expect(@response).to redirect_to article_admin_feedback_url(article)
      end

      it "delete all spam" do
        Feedback.delete_all
        create(:comment, state: :spam)
        post :bulkops, params: { bulkop_top: "Delete all spam" }
        expect(Feedback.count).to eq(0)
      end

      it "delete all spam and only confirmed spam" do
        Feedback.delete_all
        create(:comment, state: :presumed_spam)
        create(:comment, state: :spam)
        create(:comment, state: :presumed_ham)
        create(:comment, state: :ham)
        post :bulkops, params: { bulkop_top: "Delete all spam" }
        expect(Feedback.count).to eq(3)
      end

      it "mark presumed spam comments as spam" do
        comment = create(:comment, state: :presumed_spam)
        post :bulkops, params: { bulkop_top: "Mark Checked Items as Spam",
                                 feedback_check: { comment.id.to_s => "on" } }
        expect(Feedback.find(comment.id)).to be_spam
      end

      it "mark confirmed spam comments as spam" do
        comment = create(:comment, state: :spam)
        post :bulkops, params: { bulkop_top: "Mark Checked Items as Spam",
                                 feedback_check: { comment.id.to_s => "on" } }
        expect(Feedback.find(comment.id)).to be_spam
      end

      it "mark presumed ham comments as spam" do
        comment = create(:comment, state: :presumed_ham)
        post :bulkops, params: { bulkop_top: "Mark Checked Items as Spam",
                                 feedback_check: { comment.id.to_s => "on" } }
        expect(Feedback.find(comment.id)).to be_spam
      end

      it "mark ham comments as spam" do
        comment = create(:comment, state: :ham)
        post :bulkops, params: { bulkop_top: "Mark Checked Items as Spam",
                                 feedback_check: { comment.id.to_s => "on" } }
        expect(Feedback.find(comment.id)).to be_spam
      end

      it "mark presumed spam comments as ham" do
        comment = create(:comment, state: :presumed_spam)
        post :bulkops, params: { bulkop_top: "Mark Checked Items as Ham",
                                 feedback_check: { comment.id.to_s => "on" } }
        expect(Feedback.find(comment.id)).to be_ham
      end

      it "mark confirmed spam comments as ham" do
        comment = create(:comment, state: :spam)
        post :bulkops, params: { bulkop_top: "Mark Checked Items as Ham",
                                 feedback_check: { comment.id.to_s => "on" } }
        expect(Feedback.find(comment.id)).to be_ham
      end

      it "mark presumed ham comments as ham" do
        comment = create(:comment, state: :presumed_ham)
        post :bulkops, params: { bulkop_top: "Mark Checked Items as Ham",
                                 feedback_check: { comment.id.to_s => "on" } }
        expect(Feedback.find(comment.id)).to be_ham
      end

      it "mark ham comments as ham" do
        comment = create(:comment, state: :ham)
        post :bulkops, params: { bulkop_top: "Mark Checked Items as Ham",
                                 feedback_check: { comment.id.to_s => "on" } }
        expect(Feedback.find(comment.id)).to be_ham
      end

      it "confirms presumed spam comments as spam" do
        comment = create(:comment, state: :presumed_spam)
        post :bulkops, params: { bulkop_top: "Confirm Classification of Checked Items",
                                 feedback_check: { comment.id.to_s => "on" } }
        expect(Feedback.find(comment.id)).to be_spam
      end

      it "confirms confirmed spam comments as spam" do
        comment = create(:comment, state: :spam)
        post :bulkops, params: { bulkop_top: "Confirm Classification of Checked Items",
                                 feedback_check: { comment.id.to_s => "on" } }
        expect(Feedback.find(comment.id)).to be_spam
      end

      it "confirms presumed ham comments as ham" do
        comment = create(:comment, state: :presumed_ham)
        post :bulkops, params: { bulkop_top: "Confirm Classification of Checked Items",
                                 feedback_check: { comment.id.to_s => "on" } }
        expect(Feedback.find(comment.id)).to be_ham
      end

      it "confirms ham comments as ham" do
        comment = create(:comment, state: :ham)
        post :bulkops, params: { bulkop_top: "Confirm Classification of Checked Items",
                                 feedback_check: { comment.id.to_s => "on" } }
        expect(Feedback.find(comment.id)).to be_ham
      end
    end
  end
end
