# frozen_string_literal: true

require_relative "test_helper"

class StateTest < Minitest::Test
  include TrexbarSwayTestHelpers

  def test_writes_snapshot_ui_and_event_files
    with_temp_home do |home|
      config = TrexbarSway::Core::Config.normalize_config(runtime: { stateDir: File.join(home, "state") })
      snapshot = TrexbarSway::Runtime::State.build_snapshot(config, backend_payload)

      TrexbarSway::Runtime::State.write_snapshot(config, snapshot)
      TrexbarSway::Runtime::State.write_ui_state(config, open: true)

      assert_equal "healthy", TrexbarSway::Runtime::State.read_snapshot(config)[:status]
      assert_equal true, TrexbarSway::Runtime::State.read_ui_state(config)[:open]
      assert File.file?(TrexbarSway::Runtime::State.state_event_path(config))
    end
  end

  def test_stale_detection
    with_temp_home do |home|
      config = TrexbarSway::Core::Config.normalize_config(
        runtime: { stateDir: File.join(home, "state") },
        display: { staleAfterSeconds: 1 }
      )
      snapshot = { generatedAt: "2026-01-01T00:00:00Z" }

      assert TrexbarSway::Runtime::State.stale?(snapshot, config, Time.utc(2026, 1, 1, 0, 0, 3))
    end
  end
end
