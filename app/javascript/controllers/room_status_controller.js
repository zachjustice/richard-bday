import { Controller } from "@hotwired/stimulus"
import { Byte, Encoder } from '@nuintun/qrcode';

export default class extends Controller {
  connect() {
    const encoder = new Encoder({
      level: 'H'
    });

    const roomCode = $('meta[name=room]').attr('code')

    const qrcode = encoder.encode(
      new Byte(`${window.location.origin}/sessions/new?code=${roomCode}`),
    );

    $('#qr-code').attr('src', qrcode.toDataURL(8, {
      margin: 0,
      background: [252, 244, 251]
    }));
  }
  disconnect() {
  }
}
