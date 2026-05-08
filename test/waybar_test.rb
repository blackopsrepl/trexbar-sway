# frozen_string_literal: true

require "stringio"
require_relative "test_helper"

class WaybarTest < Minitest::Test
  include TrexbarSwayTestHelpers

  def test_render_outputs_waybar_json_from_cache
    with_temp_home do |home|
      config_path = File.join(home, "config.json")
      config = TrexbarSway::Core::Config.normalize_config(runtime: { stateDir: File.join(home, "state") })
      TrexbarSway::Core::Config.save_config(config, config_path)
      snapshot = TrexbarSway::Runtime::State.build_snapshot(config, backend_payload)
      TrexbarSway::Runtime::State.write_snapshot(config, snapshot)

      output = StringIO.new
      TrexbarSway::Runtime::Waybar.render(config_path, out: output)
      payload = JSON.parse(output.string, symbolize_names: true)

      assert_match(/TRX 2/, payload[:text])
      assert_includes payload[:class], "trexbar"
      assert payload[:tooltip].include?("Sessions: 2")
    end
  end

  def test_render_respects_configured_max_sessions
    with_temp_home do |home|
      config_path = File.join(home, "config.json")
      config = TrexbarSway::Core::Config.normalize_config(
        runtime: { stateDir: File.join(home, "state") },
        display: { maxSessions: 1 }
      )
      TrexbarSway::Core::Config.save_config(config, config_path)
      snapshot = TrexbarSway::Runtime::State.build_snapshot(config, backend_payload)
      TrexbarSway::Runtime::State.write_snapshot(config, snapshot)

      output = StringIO.new
      TrexbarSway::Runtime::Waybar.render(config_path, out: output)
      payload = JSON.parse(output.string, symbolize_names: true)

      assert payload[:tooltip].include?("dev | healthy")
      refute payload[:tooltip].include?("build | warning")
    end
  end
end
