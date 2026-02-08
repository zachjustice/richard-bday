# Pin npm packages by running "./bin/importmap pin <package_name>"

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rails/actioncable", to: "@rails--actioncable.js" # @8.0.201
pin "jquery" # @3.7.1

pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/concerns", under: "concerns"
pin_all_from "app/javascript/channels", under: "channels"
pin "@nuintun/qrcode", to: "@nuintun--qrcode.js" # @5.0.2
pin "html2canvas", to: "https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.esm.min.js"

# Discord Activities SDK
pin "@discord/embedded-app-sdk", to: "@discord--embedded-app-sdk.js" # @1.9.0
pin_all_from "app/javascript/discord", under: "discord"
