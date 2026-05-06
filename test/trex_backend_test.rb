# frozen_string_literal: true

require_relative "test_helper"

class TrexBackendTest < Minitest::Test
  include TrexbarSwayTestHelpers

  def test_reads_trex_snapshot_json
    Dir.mktmpdir do |dir|
      fake = write_fake_trex(dir, payload: backend_payload)
      config = TrexbarSway::Core::Config.normalize_config(runtime: { trexCommand: fake })

      snapshot = TrexbarSway::Core::TrexBackend.snapshot(config)

      assert_equal "healthy", snapshot[:status]
      assert_equal 2, snapshot.dig(:summary, :sessionCount)
    end
  end

  def test_raises_on_backend_failure
    Dir.mktmpdir do |dir|
      fake = write_fake_trex(dir, payload: {}, exit_status: 7, stderr: "broken")
      config = TrexbarSway::Core::Config.normalize_config(runtime: { trexCommand: fake })

      error = assert_raises(RuntimeError) { TrexbarSway::Core::TrexBackend.snapshot(config) }
      assert_match(/broken/, error.message)
    end
  end
end
