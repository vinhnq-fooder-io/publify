# frozen_string_literal: true

require "timeout"

class Comment < Feedback
  belongs_to :user, optional: true
  content_fields :body
  validates :author, :body, presence: true

  attr_accessor :referrer, :permalink

  scope :spam, -> { where(state: "spam") }
  scope :not_spam, -> { where("state != 'spam'") }
  scope :presumed_spam, -> { where(state: "presumed_spam") }
  scope :presumed_ham, -> { where(state: "presumed_ham") }
  scope :ham, -> { where(state: "ham") }
  scope :unconfirmed, -> { where(state: %w(presumed_spam presumed_ham)) }

  scope :last_published, -> { published.limit(5).order("created_at DESC") }

  def notify_user_via_email(user)
    EmailNotify.send_comment(self, user) if user.notify_via_email?
  end

  def interested_users
    User.where(notify_on_comments: true)
  end

  def default_text_filter
    TextFilter.find_or_default(blog.comment_text_filter)
  end

  def feed_title
    "Comment on #{article.title} by #{author}"
  end

  def send_notifications
    really_send_notifications
  end

  private

  def article_allows_feedback?
    article.allow_comments?
  end

  def blog_allows_feedback?
    true
  end

  def article_closed_for_feedback?
    article.comments_closed?
  end

  def originator
    author
  end
end
