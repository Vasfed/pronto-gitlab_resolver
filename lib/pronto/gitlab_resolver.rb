# frozen_string_literal: true

require "pronto"
require_relative "gitlab_resolver/version"

module Pronto
  module Formatter
    module GitlabResolver
      def format(messages, repo, patches)
        @messages = messages
        @patches = patches
        super
      end

      def approve_pull_request(_comments_count, _additions_count, client)
        resolve_old_messages(client, new_comments(@messages, @patches))

        super if defined?(super)
      end

      def resolve_old_messages(pronto_client, new_comments)
        client = pronto_client.send(:client)
        slug = pronto_client.send(:slug)
        pull_id = pronto_client.send(:pull_id)
        bot_id = client.user.id

        # this is already done in #format upstream, repeated here not to monkey-patch that much
        still_actual_comments = new_comments(@messages, @patches)

        threads_to_resolve = client.merge_request_discussions(slug, pull_id).auto_paginate.select do |thread|
          note = thread.notes&.first
          next if note["resolved"] #|| !note["resolvable"]
          # NOTE: this may cause issues if bot is reused for some other linters that also add code comments
          next unless note&.author&.id == bot_id
          next unless note["position"] && note.position&.[]("new_path")
          note_position = [note.position.new_path, note.position.new_line]
          next if still_actual_comments[note_position]&.any? { |comment| comment.body == note.body }
          thread.notes.all? { |note| note["system"] || note&.author&.id == bot_id }
        end

        threads_to_resolve.each do |thread|
          if ENV['PRONTO_GITLAB_DELETE_RESOLVED']
            client.delete_merge_request_discussion_note(slug, pull_id, thread.id, thread.notes.first.id)
          else
            client.resolve_merge_request_discussion(slug, pull_id, thread.id, resolved: true)
          end
        end
      end
    end
  end
end

# if pronto did not have formatters array frozen - instead of monkeypatch we might have
# class GitlabMergeRequestResolvingReviewFormatter < GitlabMergeRequestReviewFormatter
#   prepend GitlabResolver
# end
Pronto::Formatter::GitlabMergeRequestReviewFormatter.prepend(Pronto::Formatter::GitlabResolver)
