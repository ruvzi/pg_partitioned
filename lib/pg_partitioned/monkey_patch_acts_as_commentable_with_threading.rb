module Acts #:nodoc:
  module CommentableWithThreading #:nodoc:
    extend ActiveSupport::Concern

    module ClassMethods
      def acts_as_commentable
        has_many :comment_threads, :class_name => "Comment", as: :commentable, partition_key: :domain_id
        before_destroy { |record| record.root_comments.destroy_all }
        include Acts::CommentableWithThreading::LocalInstanceMethods
        extend Acts::CommentableWithThreading::SingletonMethods
      end
    end
  end
end