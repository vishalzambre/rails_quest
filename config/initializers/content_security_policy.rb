# Be sure to restart your server when you modify this file.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data, "https://fonts.gstatic.com"
    policy.img_src     :self, :https, :data, :blob
    policy.object_src  :none
    policy.style_src   :self, :https, :unsafe_inline, "https://fonts.googleapis.com"
    policy.media_src   :self, :data, :blob
    policy.worker_src  :self, :blob
    policy.frame_ancestors :none

    script_sources = [ :self ]
    connect_sources = [ :self ]

    if Rails.env.development?
      script_sources += [ "http://localhost:3036", "http://127.0.0.1:3036", :unsafe_eval ]
      connect_sources += [
        "http://localhost:3036",
        "ws://localhost:3036",
        "http://127.0.0.1:3036",
        "ws://127.0.0.1:3036",
        "ws://localhost:3000",
        "ws://127.0.0.1:3000"
      ]
    end

    policy.script_src(*script_sources)
    policy.connect_src(*connect_sources)
  end
end
