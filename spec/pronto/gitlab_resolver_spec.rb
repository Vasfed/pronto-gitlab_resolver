# frozen_string_literal: true

RSpec.describe Pronto::Formatter::GitlabMergeRequestReviewFormatter do # rubocop:disable RSpec/FilePath
  let(:repo) { Pronto::Git::Repository.new("test.git") }

  around do |spec|
    # change to repository workdir (for paths to match)
    Dir.chdir("spec/fixtures") do
      spec.run
    end
  end

  it "has a version number" do
    expect(Pronto::GitlabResolver::VERSION).not_to be nil
  end

  describe "#format" do
    subject(:perform_format) { formatter.format(messages, repo, patches) }

    let(:formatter) { described_class.new }
    let(:patches) { repo.diff("change^") }
    let(:message_level) { :info }
    let(:messages) do
      [
        Pronto::Message.new(patches.first.new_file_path, patches.first.added_lines.first, message_level, "New message")
      ] * 2
    end
    let(:existing_discussions) { [] }

    let(:glab_api_endpoint) { "https://gitlab.example.org/api/v4" }
    let(:glab_api_token) { "somet0ken" }
    let(:glab_mr_iid) { 10 }
    let(:glab_project_slug) { "somegroup/project" }
    let(:glab_api_discussions_path) do
      "#{glab_api_endpoint}/projects/#{glab_project_slug.gsub('/', '%2F')}/merge_requests/#{glab_mr_iid}/discussions"
    end
    let(:bot_uid) { 1234 }
    let!(:discussions_request) do
      stub_request(:get, glab_api_discussions_path).with(
        headers: { 'Private-Token' => glab_api_token }
      ).to_return(status: 200, body: existing_discussions.to_json)
    end
    let!(:user_request) do
      stub_request(:get, "#{glab_api_endpoint}/user").with(
        headers: { 'Private-Token' => glab_api_token }
      ).to_return(status: 200, body: { id: bot_uid }.to_json)
    end

    before do
      ENV["CI_MERGE_REQUEST_IID"] = glab_mr_iid.to_s
      ENV["PRONTO_GITLAB_API_ENDPOINT"] = glab_api_endpoint
      ENV["PRONTO_GITLAB_API_PRIVATE_TOKEN"] = glab_api_token
      # normally autodetected by pronto via git origin, but here need to set explicitly
      ENV["PRONTO_GITLAB_SLUG"] = glab_project_slug
      allow_any_instance_of(Pronto::Gitlab).to receive(:position_sha).and_return({})
    end

    it "adds comment" do
      expect_any_instance_of(Gitlab::Client).to receive(:create_merge_request_discussion).once.with(
        glab_project_slug, glab_mr_iid,
        a_hash_including(body: "New message", position: a_hash_including(new_line: 1, new_path: "somefile.txt"))
      )

      perform_format
    end

    context "when previous comments are fixed" do
      let(:messages) do
        [
          Pronto::Message.new(patches.first.new_file_path, patches.first.added_lines.first, message_level, "New message"),
          Pronto::Message.new(patches.first.new_file_path, patches.first.added_lines.first, message_level, "Non-fixed")
        ]
      end
      let(:existing_discussions) do
        [
          { id: "resolved123", notes: [
            { id: 321, type: 'DiffNote', body: "Fixed comment", position: { new_path: "somefile.txt", new_line: 1 }, author: { id: bot_uid } },
            {
              id: 3211, type: 'DiffNote', body: "changed this line...", system: true,
              position: { new_path: "somefile.txt", new_line: 1 },
              author: { id: 12345 }
            }
          ]},
          { id: "abcd12", notes: [
            { id: 321, body: "Non-fixed", position: { new_path: "somefile.txt", new_line: 1 }, author: { id: bot_uid } }
          ]},
          {
            id: "non-code321", notes: [{ id: 1234, body: "some other comment", author: { id: bot_uid } }]
          }
        ]
      end
      let!(:resolve_request) do
        stub_request(:put, "#{glab_api_discussions_path}/resolved123").with(
          body: { resolved: "true" },
          headers: { 'Private-Token' => glab_api_token }
        ).to_return(status: 200)
      end

      it "adds new and resolves old" do
        expect_any_instance_of(Gitlab::Client).to receive(:create_merge_request_discussion).once.with(
          glab_project_slug, glab_mr_iid,
          a_hash_including(body: "New message", position: a_hash_including(new_line: 1, new_path: "somefile.txt"))
        )
        perform_format
        expect(resolve_request).to have_been_requested
      end
    end

  end
end
